import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/screens/home_shell.dart';
import 'package:little_paw/screens/profile_tab.dart';
import 'package:little_paw/screens/welcome_screen.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/quota_ui.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/world/world_store.dart';
import 'package:little_paw/widgets/centered_onboarding_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M4/M5 quota exhausted-only gate', () {
    test('remaining > 0 must not show exhausted UI (stories)', () {
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 2, repliesLeft: 10, kind: 'stories'),
        isFalse,
      );
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 1, repliesLeft: 0, kind: 'stories'),
        isFalse,
      );
    });

    test('remaining > 0 must not show exhausted UI (replies)', () {
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 0, repliesLeft: 3, kind: 'replies'),
        isFalse,
      );
    });

    test('remaining == 0 may show exhausted UI', () {
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 0, repliesLeft: 10, kind: 'stories'),
        isTrue,
      );
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 2, repliesLeft: 0, kind: 'replies'),
        isTrue,
      );
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 0, repliesLeft: 0, kind: 'both'),
        isTrue,
      );
      expect(
        QuotaUi.mayShowExhaustedUi(storiesLeft: 0, repliesLeft: 5, kind: 'both'),
        isFalse,
      );
    });
  });

  group('M3 welcome value copy', () {
    test('zh covers 我↔它 / own day / not meetup', () {
      final s = S(true);
      final blob = [
        s.get('welcome.subtitle'),
        s.get('welcome.v1'),
        s.get('welcome.v2'),
        s.get('welcome.v3'),
        s.get('welcome.cta'),
      ].join('\n');
      expect(blob.contains('自己的一天') || blob.contains('自己生活'), isTrue);
      expect(blob.contains('我') && blob.contains('它'), isTrue);
      expect(
        blob.contains('约遛') || blob.contains('加好友') || blob.contains('LBS'),
        isTrue,
      );
      expect(blob.contains('附近宠友'), isFalse);
      expect(s.get('welcome.cta'), '认识它');
    });

    test('en semantic alignment', () {
      final s = S(false);
      final blob = [
        s.get('welcome.subtitle'),
        s.get('welcome.v1'),
        s.get('welcome.v2'),
        s.get('welcome.v3'),
      ].join('\n').toLowerCase();
      expect(blob.contains('own') || blob.contains('day'), isTrue);
      expect(blob.contains('you') || blob.contains('pet'), isTrue);
      expect(
        blob.contains('meetup') ||
            blob.contains('add-friends') ||
            blob.contains('lbs'),
        isTrue,
      );
    });
  });

  group('build stamp', () {
    test('hostname maps pet=v0.18 web.app=v0.19', () {
      expect(FirstDailyGate.buildStampForHost('littlepaw.pet'), 'web-shell-center-v0.22');
      expect(FirstDailyGate.buildStampForHost('little-paw-prod.web.app'), 'web-shell-center-v0.22');
    });
  });

  group('CenteredOnboardingCard layout', () {
    testWidgets('PC wide: card max width <= 480, CTA not viewport-wide',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: LpTheme.light(),
          home: Scaffold(
            body: CenteredOnboardingCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('title'),
                  FilledButton(
                    key: const Key('ob.cta'),
                    onPressed: () {},
                    child: const Text('认识它'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.getSize(find.byKey(const Key('onboarding.centered_card')));
      expect(card.width, lessThanOrEqualTo(480));
      expect(card.width, greaterThan(300));

      final cta = tester.getSize(find.byKey(const Key('ob.cta')));
      expect(cta.width, lessThan(1280 * 0.7));
      expect(cta.width, lessThanOrEqualTo(card.width + 1));
    });

    testWidgets('phone: card not a hairline strip; has padding gutters',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: LpTheme.light(),
          home: Scaffold(
            body: CenteredOnboardingCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('title'),
                  FilledButton(onPressed: () {}, child: const Text('下一步')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.getSize(find.byKey(const Key('onboarding.centered_card')));
      expect(card.width, lessThanOrEqualTo(390 - 24));
      expect(card.height, greaterThan(80));
    });
  });

  group('M7 feedback entry migration', () {
    Future<SpaceStore> pumpShell(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.real,
        createdAt: DateTime.utc(2026, 1, 1),
      ));
      final auth = FakeAuthService();
      final sync = CloudSyncService(backend: MemoryCloudBackend());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            ChangeNotifierProvider<AuthService>.value(value: auth),
            Provider<CloudSyncService>.value(value: sync),
            ChangeNotifierProvider(create: (_) => WorldStore()),
          ],
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const HomeShell(),
          ),
        ),
      );
      await tester.pump(); // FeedTab has timers; avoid pumpAndSettle hang
      await tester.pump(const Duration(milliseconds: 300));
      return store;
    }

    testWidgets('HomeShell has no feedback FAB', (tester) async {
      await pumpShell(tester);
      expect(find.byKey(const Key('lp_feedback_fab')), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Profile has feedback row opening sheet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.real,
        createdAt: DateTime.utc(2026, 1, 1),
      ));
      final auth = FakeAuthService();
      final sync = CloudSyncService(backend: MemoryCloudBackend());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            ChangeNotifierProvider<AuthService>.value(value: auth),
            Provider<CloudSyncService>.value(value: sync),
          ],
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const ProfileTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ListView lazily builds; drag to force build of lower sections.
      final list = find.byType(ListView);
      expect(list, findsWidgets);
      await tester.drag(list.first, const Offset(0, -4000));
      await tester.pumpAndSettle();

      final row = find.byKey(const Key('profile.feedback'));
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('提交'), findsOneWidget);
    });
  });

  group('welcome uses centered card', () {
    testWidgets('WelcomeScreen hosts CenteredOnboardingCard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: LpTheme.light(),
            home: WelcomeScreen(onStart: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding.centered_card')), findsOneWidget);
      expect(find.textContaining('认识它'), findsOneWidget);
    });
  });
}
