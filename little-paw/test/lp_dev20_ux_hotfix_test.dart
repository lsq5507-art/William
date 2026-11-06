import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/models/story.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/quota_ui.dart';
import 'package:little_paw/services/seo_web_gate.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/widgets/coin_reward_snack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F1 CoinRewardSnack', () {
    test('auto-dismiss default 2.5s and hard cap ≤3s', () {
      expect(
        CoinRewardSnack.defaultAutoDismiss,
        const Duration(milliseconds: 2500),
      );
      expect(
        CoinRewardSnack.defaultAutoDismiss <= CoinRewardSnack.maxAutoDismiss,
        isTrue,
      );
      expect(
        CoinRewardSnack.maxAutoDismiss.inMilliseconds,
        lessThanOrEqualTo(3000),
      );
      expect(CoinRewardSnack.closeHitMin, greaterThanOrEqualTo(44));
    });

    testWidgets('shows +N, wallet action, and X; dismiss removes overlay', (
      tester,
    ) async {
      var walletTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () {
                    CoinRewardSnack.show(
                      context,
                      message: '+300 金币',
                      walletLabel: '查看钱包',
                      onWallet: () => walletTaps++,
                    );
                  },
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('+300 金币'), findsOneWidget);
      expect(find.text('查看钱包'), findsOneWidget);
      expect(find.byKey(const Key('coin_reward_snack.close')), findsOneWidget);

      await tester.tap(find.byKey(const Key('coin_reward_snack.close')));
      await tester.pump();
      expect(find.text('+300 金币'), findsNothing);

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.tap(find.text('查看钱包'));
      await tester.pump();
      expect(walletTaps, 1);
      expect(find.text('+300 金币'), findsNothing);
    });

    testWidgets('auto-dismisses at default duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  CoinRewardSnack.show(
                    context,
                    message: '+100 金币',
                    walletLabel: '查看钱包',
                    onWallet: () {},
                  );
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('+100 金币'), findsOneWidget);
      await tester.pump(CoinRewardSnack.defaultAutoDismiss);
      await tester.pump();
      expect(find.text('+100 金币'), findsNothing);
    });
  });

  group('F2 quota used/limit + post-only wall', () {
    test('profile.quota_line is 已用 a/b (not remaining)', () {
      final zh = S(true).fmt('profile.quota_line', {
        'storiesUsed': '0',
        'storiesLimit': '2',
        'repliesUsed': '1',
        'repliesLimit': '10',
      });
      expect(zh.contains('已用'), isTrue);
      expect(zh.contains('动态'), isTrue);
      expect(zh.contains('0/2'), isTrue);
      expect(zh.contains('剩余'), isFalse);

      final en = S(false).fmt('profile.quota_line', {
        'storiesUsed': '0',
        'storiesLimit': '2',
        'repliesUsed': '1',
        'repliesLimit': '10',
      });
      expect(en.toLowerCase().contains('used'), isTrue);
    });

    test('wall hidden unless afterSuccessfulPost and stories exhausted', () {
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 0,
          afterSuccessfulPost: false,
        ),
        isFalse,
      );
      expect(
        QuotaUi.mayShowPostQuotaWall(storiesLeft: 1, afterSuccessfulPost: true),
        isFalse,
      );
      expect(
        QuotaUi.mayShowPostQuotaWall(storiesLeft: 0, afterSuccessfulPost: true),
        isTrue,
      );
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 0,
          afterSuccessfulPost: true,
          pickerOrConfirmInFlight: true,
        ),
        isFalse,
      );
    });

    test('quota copy keeps 现在不会扣款 + 可继续', () {
      final s = S(true);
      final blob = [
        s.get('quota.stories.title'),
        s.get('quota.stories.body'),
        s.get('quota.defer.title'),
        s.get('quota.defer.body'),
      ].join('\n');
      expect(blob.contains('现在不会扣款') || blob.contains('当前不会扣款'), isTrue);
      expect(blob.contains('仍可继续') || blob.contains('小小探险'), isTrue);
    });
  });

  group('F2 store: consume on post not impress; wall latch', () {
    late SpaceStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = SpaceStore();
      await store.load();
      await store.createPet(
        Pet(
          id: 'p1',
          name: 'Mochi',
          species: 'cat',
          type: PetType.fiction,
          createdAt: DateTime.utc(2026, 11, 5),
        ),
      );
      store.customMediaToFeedEnabled = true;
    });

    test('impress does not burn stories quota', () async {
      final story = Story(
        id: 'feed_real_1',
        bodyZh: 'hi',
        bodyEn: 'hi',
        createdAt: DateTime.utc(2026, 11, 5),
        isOnboarding: false,
        isUnread: true,
        imageUrl: 'https://example.com/a.png',
        isDemoFill: false,
      );
      store.stories = [story, ...store.stories];
      final before = store.economy.storiesUsedToday;
      await store.markStoryImpressed(story.id, source: 'feed');
      expect(store.economy.storiesUsedToday, before);
    });

    test(
      'custom media post consumes; wall only after exhaust success',
      () async {
        expect(store.pendingPostQuotaWall, isFalse);
        final s1 = await store.addCustomMediaStory(imageUrl: 'localmedia://a');
        expect(s1, isNotNull);
        expect(store.economy.storiesUsedToday, 1);
        expect(store.pendingPostQuotaWall, isFalse);

        final s2 = await store.addCustomMediaStory(imageUrl: 'localmedia://b');
        expect(s2, isNotNull);
        expect(store.economy.storiesHit, isTrue);
        expect(store.pendingPostQuotaWall, isTrue);
        expect(store.takePendingPostQuotaWall(), isTrue);
        expect(store.pendingPostQuotaWall, isFalse);
      },
    );

    test('in-flight custom media suppresses wall', () {
      store.armCustomMediaFlowInFlight();
      expect(store.customMediaFlowInFlight, isTrue);
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 0,
          afterSuccessfulPost: true,
          pickerOrConfirmInFlight: store.customMediaFlowInFlight,
        ),
        isFalse,
      );
      store.clearCustomMediaFlowInFlight();
      expect(store.customMediaFlowInFlight, isFalse);
    });
  });

  group('F3 single balance source', () {
    test('credit then surfaces share coinBalance; toast is delta-only', () {
      final e = Economy(utcDay: '2026-11-05');
      e.credit(200, 'task_custom_media');
      e.credit(100, 'task_story_impress');
      expect(e.coinBalance, 300);
      expect(CoinRewardSnack.isDeltaOnly, isTrue);
    });
  });

  group('M14 build stamp + M16 E01 gate intact', () {
    tearDown(() {
      SeoWebGate.hostnameOverride = null;
    });

    test('both hosts stamp web-shell-center-v0.22', () {
      expect(FirstDailyGate.stampHotfix, 'web-shell-center-v0.22');
      expect(
        FirstDailyGate.buildStampForHost('littlepaw.pet'),
        'web-shell-center-v0.22',
      );
      expect(
        FirstDailyGate.buildStampForHost('www.littlepaw.pet'),
        'web-shell-center-v0.22',
      );
      expect(
        FirstDailyGate.buildStampForHost('little-paw-prod.web.app'),
        'web-shell-center-v0.22',
      );
      expect(
        FirstDailyGate.buildStampForHost('localhost'),
        'web-shell-center-v0.22',
      );
    });

    test('pet keeps E01 experiment off; web.app on', () {
      expect(FirstDailyGate.experimentEnabledForHost('littlepaw.pet'), isFalse);
      expect(
        FirstDailyGate.experimentEnabledForHost('little-paw-prod.web.app'),
        isTrue,
      );
      SeoWebGate.hostnameOverride = 'littlepaw.pet';
      expect(SeoWebGate.firstDailyExperimentEnabled, isFalse);
      SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
      expect(SeoWebGate.firstDailyExperimentEnabled, isTrue);
    });
  });
}
