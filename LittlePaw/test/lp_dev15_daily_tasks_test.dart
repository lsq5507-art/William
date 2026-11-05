import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/models/story.dart';
import 'package:little_paw/screens/economy_pages.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M1 story impress task', () {
    test('non-demo impress credits +100 once; demo fill does not', () async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.fiction,
        createdAt: DateTime.utc(2026, 11, 4),
      ));
      store.stories = [
        Story(
          id: 'real_1',
          bodyZh: '真实故事',
          bodyEn: 'real',
          createdAt: DateTime.utc(2026, 11, 4),
          isDemoFill: false,
          isUnread: true,
        ),
        Story(
          id: 'demo_1',
          bodyZh: 'demo',
          bodyEn: 'demo',
          createdAt: DateTime.utc(2026, 11, 4),
          isDemoFill: true,
          isUnread: true,
        ),
      ];

      expect(Economy.coinTaskStoryImpress, 100);
      final before = store.economy.coinBalance;

      await store.markStoryImpressed('demo_1', source: 'feed');
      expect(store.economy.coinBalance, before);
      expect(store.economy.taskStoryImpressClaimedToday, false);
      expect(
        store.eventLog.events.any((e) => e.event == 'story_impression_complete'),
        false,
      );

      await store.markStoryImpressed('real_1', source: 'feed');
      expect(store.economy.coinBalance, before + 100);
      expect(store.economy.taskStoryImpressClaimedToday, true);
      expect(store.economy.ledger.last.reason, 'task_story_impress');
      expect(
        store.eventLog.events.any((e) => e.event == 'story_impression_complete'),
        true,
      );
      expect(
        store.eventLog.events.any((e) =>
            e.event == 'task_claim' && e.props['task_id'] == 'story_impress'),
        true,
      );
      expect(
        store.eventLog.events.any((e) =>
            e.event == 'coin_credit' &&
            e.props['reason'] == 'task_story_impress'),
        true,
      );

      final mid = store.economy.coinBalance;
      store.stories = [
        ...store.stories,
        Story(
          id: 'real_2',
          bodyZh: '另一则',
          bodyEn: 'other',
          createdAt: DateTime.utc(2026, 11, 4),
          isDemoFill: false,
          isUnread: true,
        ),
      ];
      await store.markStoryImpressed('real_2', source: 'feed');
      expect(store.economy.coinBalance, mid);
    });
  });

  group('M2 custom media task', () {
    test('post credits +300 once; second post same day no credit', () async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.fiction,
        createdAt: DateTime.utc(2026, 11, 4),
      ));
      expect(Economy.coinTaskCustomMedia, 300);
      final before = store.economy.coinBalance;

      final s1 = await store.addCustomMediaStory(
        imageUrl: 'localmedia://a',
        caption: '日常一',
      );
      expect(s1, isNotNull);
      expect(store.economy.coinBalance, before + 300);
      expect(store.economy.taskCustomMediaClaimedToday, true);
      expect(store.economy.ledger.last.reason, 'task_custom_media');
      expect(
        store.eventLog.events.any((e) => e.event == 'custom_media_posted'),
        true,
      );
      expect(
        store.eventLog.events.any((e) =>
            e.event == 'task_claim' && e.props['task_id'] == 'custom_media'),
        true,
      );

      final mid = store.economy.coinBalance;
      await store.addCustomMediaStory(
        imageUrl: 'localmedia://b',
        caption: '日常二',
      );
      expect(store.economy.coinBalance, mid);
    });
  });

  group('M5 chat coexistence + economy claim API', () {
    test('chat amount unchanged; story/custom claim once via Economy', () {
      final e = Economy(utcDay: '2026-11-04');
      expect(Economy.coinTaskChat, 200);
      e.markTaskChatProgress(day: '2026-11-04');
      expect(e.claimTaskChat(day: '2026-11-04'), 200);

      e.markTaskStoryImpressProgress(day: '2026-11-04');
      expect(e.claimTaskStoryImpress(day: '2026-11-04'), 100);
      expect(e.claimTaskStoryImpress(day: '2026-11-04'), null);

      e.markTaskCustomMediaProgress(day: '2026-11-04');
      expect(e.claimTaskCustomMedia(day: '2026-11-04'), 300);
      expect(e.claimTaskCustomMedia(day: '2026-11-04'), null);
      expect(e.coinBalance, 200 + 100 + 300);
    });
  });

  group('M3 tasks page copy/states', () {
    testWidgets('shows story + custom rows; claimed = 今日已领', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
      store.economy.markTaskStoryImpressProgress(day: store.economy.utcDay);
      store.economy.claimTaskStoryImpress(day: store.economy.utcDay);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const EconomyTasksPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('看完一则它的故事'), findsOneWidget);
      expect(find.textContaining('把一张日常放进圈子'), findsOneWidget);
      expect(find.textContaining('完成 1 次聊天发送'), findsOneWidget);
      expect(find.text('今日已领'), findsWidgets);
      expect(find.textContaining('创建自定义角色'), findsOneWidget);
      expect(find.textContaining('生成一张图'), findsOneWidget);
    });
  });

  group('S1 F8 copy', () {
    test('quota/story/replies keys avoid absolute 全部用完 / 玩不了了', () {
      final zh = S(true);
      final keys = [
        'quota.replies.title',
        'quota.both.title',
        'story.quota.title',
        'activity.chat.quota.title',
        'quota.defer.title',
        'quota.stories.title',
      ];
      for (final k in keys) {
        final t = zh.get(k);
        expect(t.contains('全部用完'), false, reason: k);
        expect(t.contains('玩不了了'), false, reason: k);
        // Absolute 「用完啦」 misleaders replaced with F8-style phrasing.
        expect(t.contains('用完啦'), false, reason: '$k still absolute 用完啦');
        expect(t.contains('都用完'), false, reason: k);
      }
      expect(
        zh.get('quota.defer.title'),
        contains('小小探险'),
      );
    });
  });

  group('ledger labels', () {
    test('reason display names match design', () {
      expect(economyReasonLabel(true, 'task_story_impress'), '今日任务·故事');
      expect(economyReasonLabel(true, 'task_custom_media'), '今日任务·放进圈子');
      expect(economyReasonLabel(true, 'task_chat'), '今日任务·聊天');
    });
  });
}
