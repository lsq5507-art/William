import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/models/pet.dart';
import 'package:little_paw/models/story.dart';
import 'package:little_paw/screens/feed_tab.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/pet_subject_media.dart';
import 'package:little_paw/services/seo_web_gate.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/world/world_store.dart';

Future<SpaceStore> _primed({bool exposureDone = false}) async {
  final store = SpaceStore();
  await store.load();
  await store.createPet(Pet(
    id: 'p19c',
    name: '豆豆',
    species: 'cat',
    type: PetType.real,
    createdAt: DateTime.utc(2026, 11, 4),
  ));
  await store.completeOnboarding();
  store.economy.credit(Economy.coinCostChat * 5, 'checkin');
  store.dailyExposureCompleted = exposureDone;
  store.firstDailyCoachShown = true; // avoid coach sheet in widget tests
  await store.persist();
  return store;
}

Widget _wrap(SpaceStore store, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SpaceStore>.value(value: store),
      ChangeNotifierProvider<WorldStore>(create: (_) => WorldStore()),
      ChangeNotifierProvider<AuthService>.value(value: FakeAuthService()),
      Provider<CloudSyncService>.value(
        value: CloudSyncService(backend: MemoryCloudBackend()),
      ),
    ],
    child: MaterialApp(theme: LpTheme.light(), home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
  });

  tearDown(() => SeoWebGate.hostnameOverride = null);

  group('pin race / consume timing', () {
    test('exposure done + !pinConsumed → shouldShowPin true', () {
      expect(
        FirstDailyGate.shouldShowPin(
          experimentEnabled: true,
          hasEligibleContent: true,
          pinConsumed: false,
        ),
        isTrue,
      );
    });

    test('noteFirstDailyPinPresented does NOT consume immediately', () async {
      final store = await _primed(exposureDone: true);
      expect(store.firstDailyPinConsumed, isFalse);
      await store.noteFirstDailyPinPresented();
      expect(store.firstDailyPinPresented, isTrue);
      expect(store.firstDailyPinConsumed, isFalse);
    });

    test('3/3 exposure + presented does NOT auto-consume (DEF-QA19-03)', () async {
      final store = await _primed(exposureDone: true);
      await store.noteFirstDailyPinPresented();
      expect(store.firstDailyPinPresented, isTrue);
      expect(store.firstDailyPinConsumed, isFalse);
      // No default timer path — pin stays until explicit interaction.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(store.firstDailyPinConsumed, isFalse);
    });

    test('exposure newly completed after pin presented does NOT auto-consume', () async {
      final store = await _primed(exposureDone: false);
      await store.noteFirstDailyPinPresented();
      expect(store.firstDailyPinConsumed, isFalse);
      final id = store.stories.firstWhere((s) => !s.isDemoFill).id;
      final vis = store.visualFeedStories();
      final impressId = vis.isNotEmpty ? vis.first.id : id;
      await store.markStoryImpressed(impressId, source: 'after_pin');
      expect(store.dailyExposureCompleted, isTrue);
      expect(store.firstDailyPinConsumed, isFalse);
    });

    test('user tap consume works without dwell', () async {
      final store = await _primed(exposureDone: true);
      await store.noteFirstDailyPinPresented();
      await store.consumeFirstDailyPin(reason: 'user_tap');
      expect(store.firstDailyPinConsumed, isTrue);
    });
  });

  group('eligibility onboarding fallback', () {
    test('onboarding pet stories can source pin when feed empty', () async {
      final store = await _primed();
      store.stories = [
        Story(
          id: 'onb_1',
          bodyZh: '开场',
          bodyEn: 'open',
          createdAt: DateTime.utc(2026, 11, 4),
          isOnboarding: true,
          imageUrl: PetSubjectMedia.whitelistAssets.first,
        ),
      ];
      await store.persist();
      expect(store.hasEligibleFirstDailyContent(), isTrue);
      expect(store.firstDailyPinStory(), isNotNull);
      expect(store.firstDailyPinStory()!.isOnboarding, isTrue);
    });
  });

  group('widget mount order', () {
    testWidgets('pin above upload card with badge', (tester) async {
      final store = await _primed(exposureDone: true);
      expect(store.hasEligibleFirstDailyContent(), isTrue);
      expect(store.firstDailyPinConsumed, isFalse);

      await tester.pumpWidget(_wrap(store, const Scaffold(body: FeedTab())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // loading delay
      await tester.pump(); // post-frame notePresented

      expect(find.byKey(const Key('first_daily.pinned')), findsOneWidget);
      expect(find.text('它的一条日常'), findsOneWidget);

      final pinY = tester.getTopLeft(find.byKey(const Key('first_daily.pinned'))).dy;
      // Upload card may be below; if custom media enabled, find its CTA text
      final upload = find.textContaining('放进圈子');
      if (upload.evaluate().isNotEmpty) {
        final uploadY = tester.getTopLeft(upload.first).dy;
        expect(pinY, lessThan(uploadY));
      }

      // Still not consumed — stable until user interaction (DEF-QA19-03).
      expect(store.firstDailyPinConsumed, isFalse);
      expect(store.firstDailyPinPresented, isTrue);
      await tester.pump(const Duration(milliseconds: 2600));
      expect(store.firstDailyPinConsumed, isFalse);
      expect(find.byKey(const Key('first_daily.pinned')), findsOneWidget);
      expect(find.text('它的一条日常'), findsOneWidget);
      store.cancelFirstDailyPinSoftDismiss();
    });
  });
}
