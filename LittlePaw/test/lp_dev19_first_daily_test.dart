import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/screens/home_shell.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/seo_web_gate.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/services/story_impression.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/widgets/first_daily_ui.dart';
import 'package:little_paw/world/world_store.dart';

Future<SpaceStore> _primedStore({
  bool withStory = true,
  bool completed = false,
  bool coachShown = false,
}) async {
  final store = SpaceStore();
  await store.load();
  await store.createPet(Pet(
    id: 'p19',
    name: '豆豆',
    species: 'cat',
    type: PetType.real,
    createdAt: DateTime.utc(2026, 11, 4),
  ));
  await store.completeOnboarding();
  if (!withStory) {
    store.stories = [];
    await store.persist();
  }
  store.firstDailyCompleted = completed;
  store.firstDailyCoachShown = coachShown;
  store.economy.credit(Economy.coinCostChat * 5, 'checkin');
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
    child: MaterialApp(
      theme: LpTheme.light(),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
  });

  tearDown(() {
    SeoWebGate.hostnameOverride = null;
  });

  group('hostname / stamp mapping', () {
    test('web.app + localhost enable experiment; stamp hotfix', () {
      expect(FirstDailyGate.experimentEnabledForHost('little-paw-prod.web.app'), isTrue);
      expect(FirstDailyGate.experimentEnabledForHost('localhost'), isTrue);
      expect(FirstDailyGate.experimentEnabledForHost('127.0.0.1'), isTrue);
      expect(FirstDailyGate.experimentEnabledForHost(''), isTrue);
      expect(
        FirstDailyGate.buildStampForHost('little-paw-prod.web.app'),
        'ux-hotfix-web-v0.20',
      );
      expect(FirstDailyGate.buildStampForHost('localhost'), 'ux-hotfix-web-v0.20');
    });

    test('pet hosts disable experiment; stamp hotfix', () {
      expect(FirstDailyGate.experimentEnabledForHost('littlepaw.pet'), isFalse);
      expect(FirstDailyGate.experimentEnabledForHost('www.littlepaw.pet'), isFalse);
      expect(
        FirstDailyGate.buildStampForHost('littlepaw.pet'),
        'ux-hotfix-web-v0.20',
      );
      expect(
        FirstDailyGate.buildStampForHost('www.littlepaw.pet'),
        'ux-hotfix-web-v0.20',
      );
    });

    test('SeoWebGate.buildStamp follows hostname override', () {
      SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
      expect(SeoWebGate.buildStamp, 'ux-hotfix-web-v0.20');
      expect(SeoWebGate.firstDailyExperimentEnabled, isTrue);

      SeoWebGate.hostnameOverride = 'littlepaw.pet';
      expect(SeoWebGate.buildStamp, 'ux-hotfix-web-v0.20');
      expect(SeoWebGate.firstDailyExperimentEnabled, isFalse);
    });
  });

  group('Feed complete impress mapping (≥50% × ≥1s)', () {
    test('ratio 0.5 dwell 1s marks complete; leave cancels', () {
      fakeAsync((async) {
        final tracker = StoryImpressionTracker(
          immediateRatio: 1.1,
          dwellMinRatio: 0.5,
          dwell: const Duration(seconds: 1),
        );
        tracker.updateVisibility('d1', 0.5);
        expect(tracker.hasActiveDwell('d1'), isTrue);
        async.elapse(const Duration(milliseconds: 500));
        tracker.updateVisibility('d1', 0.0);
        expect(tracker.hasActiveDwell('d1'), isFalse);
        async.elapse(const Duration(seconds: 2));
        expect(tracker.impressed.contains('d1'), isFalse);

        tracker.updateVisibility('d1', 0.55);
        async.elapse(const Duration(seconds: 1));
        expect(tracker.impressed.contains('d1'), isTrue);
        tracker.dispose();
      });
    });

    test('legacy defaults unchanged: ≥80% immediate', () {
      final tracker = StoryImpressionTracker();
      tracker.updateVisibility('x', 0.85);
      expect(tracker.impressed.contains('x'), isTrue);
      tracker.dispose();
    });
  });

  group('coach copy boundaries', () {
    test('zh coach has own-day / daily; no meetup / add-friend lure', () {
      final s = S(true);
      final blob = [
        s.get('first_daily.coach.title'),
        s.get('first_daily.coach.sub'),
        s.get('first_daily.coach.cta_primary'),
        s.get('first_daily.coach.cta_secondary'),
        s.get('first_daily.coach.foot'),
        s.get('first_daily.pin.badge'),
        s.get('first_daily.empty.title'),
        s.get('first_daily.empty.sub'),
      ].join('\n');
      expect(blob.contains('自己的一天') || blob.contains('日常'), isTrue);
      expect(blob.contains('先看看它今天'), isTrue);
      expect(blob.contains('看完这条日常'), isTrue);
      expect(blob.contains('先聊聊'), isTrue);
      expect(blob.contains('不是约遛'), isTrue);
      expect(blob.contains('不加好友'), isTrue);
      expect(blob.contains('附近宠友'), isFalse);
      expect(blob.contains('开通会员'), isFalse);
    });
  });

  group('gate + persistence', () {
    test('chat blocked before complete impress when content exists', () async {
      final store = await _primedStore(withStory: true, completed: false);
      expect(store.firstDailyCompleted, isFalse);
      expect(store.hasEligibleFirstDailyContent(), isTrue);
      final r = await store.sendChatMessage('hi');
      expect(r, isNull);
      expect(
        store.eventLog.events.any((e) => e.event == 'chat_message_sent'),
        isFalse,
      );
    });

    test('先聊聊 path force impress then chat ok', () async {
      final store = await _primedStore(withStory: true, completed: false);
      await store.forceFirstDailyImpression(reason: 'chat_first');
      expect(store.firstDailyCompleted, isTrue);
      expect(
        store.eventLog.events.any((e) =>
            e.event == 'first_daily_forced_impression' ||
            e.event == 'story_impression_complete'),
        isTrue,
      );
      final r = await store.sendChatMessage('hi after');
      expect(r, isNotNull);
      expect(
        store.eventLog.events.any((e) => e.event == 'chat_message_sent'),
        isTrue,
      );
    });

    test('empty state allows chat + first_daily_skipped', () async {
      final store = await _primedStore(withStory: false, completed: false);
      final r = await store.sendChatMessage('empty chat');
      expect(r, isNotNull);
      expect(
        store.eventLog.events.any((e) => e.event == 'first_daily_skipped'),
        isTrue,
      );
      expect(store.firstDailyCompleted, isTrue);
    });

    test('returning user (completed) has no chat gate', () async {
      final store = await _primedStore(withStory: true, completed: true);
      final r = await store.sendChatMessage('back');
      expect(r, isNotNull);
    });

    test('pet host: no chat gate even if flags false', () async {
      SeoWebGate.hostnameOverride = 'littlepaw.pet';
      final store = await _primedStore(withStory: true, completed: false);
      final r = await store.sendChatMessage('pet host');
      expect(r, isNotNull);
    });

    test('story impress completes first-daily gate', () async {
      final store = await _primedStore(withStory: true, completed: false);
      final id = store.visualFeedStories().firstWhere((s) => !s.isDemoFill).id;
      await store.markStoryImpressed(id, source: 'feed');
      expect(store.firstDailyCompleted, isTrue);
    });
  });

  group('shell + widgets', () {
    testWidgets('default shell lands on Feed (index 0)', (tester) async {
      final store = await _primedStore(coachShown: true, completed: true);
      store.firstDailyPinConsumed = true; // returning-style: no pin timer
      await store.persist();
      await tester.pumpWidget(_wrap(store, const HomeShell()));
      await tester.pump(); // build
      await tester.pump(const Duration(milliseconds: 400)); // feed loading delay
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('coach sheet locked copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LpTheme.light(),
          home: Scaffold(
            body: FirstDailyCoachSheet(
              zh: true,
              onPrimary: () {},
              onSecondary: () {},
            ),
          ),
        ),
      );
      expect(find.text('先看看它今天'), findsOneWidget);
      expect(find.textContaining('自己的一天'), findsOneWidget);
      expect(find.text('看完这条日常'), findsOneWidget);
      expect(find.text('先聊聊'), findsOneWidget);
      expect(find.textContaining('不是约遛'), findsOneWidget);
    });

    testWidgets('pinned badge copy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LpTheme.light(),
          home: Scaffold(
            body: PinnedDailyCard(
              zh: true,
              caption: '晒太阳',
              petName: '豆豆',
              onOpenStory: () {},
            ),
          ),
        ),
      );
      expect(find.text('它的一条日常'), findsOneWidget);
      expect(find.text('晒太阳'), findsOneWidget);
    });
  });
}
