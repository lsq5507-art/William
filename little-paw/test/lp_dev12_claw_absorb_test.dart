import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/screens/home_shell.dart';
import 'package:little_paw/screens/profile_tab.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/pet_subject_media.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/world/world_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<(SpaceStore, S)> pumpProfile(WidgetTester tester) async {
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
    return (store, S(store.localeZh));
  }

  Future<void> scrollTap(WidgetTester tester, Finder f) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(f, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('S0 copy', () {
    test('C1 about body has companion middle + anti social meetup', () {
      final zh = S(true);
      final en = S(false);
      final zhBody = zh.get('profile.about_body');
      final enBody = en.get('profile.about_body');
      expect(zhBody, contains('数字日常'));
      expect(zhBody, contains('陪伴向'));
      expect(zhBody, contains('中间表达'));
      expect(zhBody, contains('约遛'));
      expect(zhBody, contains('加好友'));
      expect(zhBody, isNot(contains('演示')));
      expect(zhBody, isNot(contains('Demo')));
      expect(zhBody, isNot(contains('调试')));
      expect(enBody.toLowerCase(), contains('digital'));
      expect(enBody.toLowerCase(), contains('companion'));
      expect(enBody.toLowerCase(), contains('dog-walking'));
      expect(enBody.toLowerCase(), isNot(contains('demo')));
    });

    test('C2 invite copy has no real-social meetup words', () {
      final zh = S(true);
      final en = S(false);
      for (final key in [
        'profile.invite_copy_text',
        'profile.invite_coming_body',
        'profile.invite_sub',
      ]) {
        final z = zh.get(key);
        final e = en.get(key);
        expect(z, isNot(contains('约遛')));
        expect(z, isNot(contains('加好友')));
        expect(z, isNot(contains('同城')));
        expect(z, isNot(contains('附近主人')));
        expect(e.toLowerCase(), isNot(contains('meetup')));
        expect(e.toLowerCase(), isNot(contains('nearby owner')));
        expect(e.toLowerCase(), isNot(contains('dog-walking')));
      }
      expect(zh.get('profile.invite_copy_text'), contains('宠物朋友圈'));
      expect(en.get('profile.invite_copy_text').toLowerCase(), contains('pet'));
    });

    test('C4/C5 empty hints stay companion; no plaza match', () {
      final zh = S(true);
      final en = S(false);
      expect(zh.get('feed.empty.photo.body'), contains('日常'));
      expect(zh.get('custom.empty.feed_hint'), contains('数字日常'));
      expect(zh.get('feed.empty.photo.hint'), isNot(contains('广场')));
      expect(zh.get('feed.empty.photo.hint'), isNot(contains('匹配')));
      expect(zh.get('activity.chat.empty_body'), isNot(contains('加宠友')));
      expect(zh.get('story.empty.body'), isNot(contains('加宠友')));
      expect(en.get('feed.empty.photo.body').toLowerCase(),
          isNot(contains('match friends')));
      expect(en.get('custom.empty.feed_hint').toLowerCase(),
          contains('digital'));
    });
  });

  group('S1 my posts', () {
    test('flag defaults true and persists off', () async {
      final store = SpaceStore();
      await store.load();
      expect(store.profileMyPostsReadonlyEnabled, isTrue);
      await store.setProfileMyPostsReadonlyEnabled(false);
      final store2 = SpaceStore();
      await store2.load();
      expect(store2.profileMyPostsReadonlyEnabled, isFalse);
    });

    testWidgets('entry visible after identity; no fake follow/like copy',
        (tester) async {
      final (_, s) = await pumpProfile(tester);
      expect(find.text(s.get('profile.section_daily')), findsOneWidget);
      expect(find.byKey(const Key('profile.my_posts')), findsOneWidget);
      expect(find.text(s.get('profile.my_posts')), findsOneWidget);
      expect(find.text(s.get('profile.my_posts_sub')), findsOneWidget);
      expect(find.textContaining('关注'), findsNothing);
      expect(find.textContaining('粉丝'), findsNothing);
      expect(find.textContaining('获赞'), findsNothing);
      expect(find.textContaining('followers'), findsNothing);
      expect(find.textContaining('likes'), findsNothing);
    });

    testWidgets('flag off hides entry; no fake follow wall', (tester) async {
      final (store, s) = await pumpProfile(tester);
      await store.setProfileMyPostsReadonlyEnabled(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile.my_posts')), findsNothing);
      expect(find.text(s.get('profile.my_posts')), findsNothing);
      expect(find.textContaining('关注'), findsNothing);
      expect(find.textContaining('获赞'), findsNothing);
    });

    testWidgets('empty state CTA and honest copy', (tester) async {
      final (_, s) = await pumpProfile(tester);
      await scrollTap(tester, find.byKey(const Key('profile.my_posts')));
      expect(find.byKey(const Key('profile.my_posts.page')), findsOneWidget);
      expect(find.text(s.get('profile.my_posts_empty_title')), findsOneWidget);
      expect(find.text(s.get('profile.my_posts_empty_body')), findsOneWidget);
      expect(find.byKey(const Key('profile.my_posts.empty_cta')), findsOneWidget);
      expect(find.text(s.get('profile.my_posts_empty_cta')), findsOneWidget);
      expect(find.textContaining('即将开放'), findsNothing);
      expect(find.textContaining('coming soon'), findsNothing);
    });

    testWidgets('list shows local post after publish', (tester) async {
      final (store, s) = await pumpProfile(tester);
      await store.addCustomMediaStory(
        imageUrl: PetSubjectMedia.whitelistAssets.first,
        caption: '晒晒瓜瓜午睡',
      );
      await tester.pumpAndSettle();
      await scrollTap(tester, find.byKey(const Key('profile.my_posts')));
      expect(find.text('晒晒瓜瓜午睡'), findsOneWidget);
      expect(find.text(s.get('profile.my_posts_empty_title')), findsNothing);
      expect(find.textContaining('关注'), findsNothing);
      expect(find.textContaining('获赞'), findsNothing);
    });

    testWidgets('about page shows positive and negative examples',
        (tester) async {
      final (_, s) = await pumpProfile(tester);
      await scrollTap(tester, find.byKey(const Key('profile.about')));
      expect(find.text(s.get('profile.about')), findsWidgets);
      expect(find.textContaining('数字日常'), findsOneWidget);
      expect(find.textContaining('陪伴向'), findsOneWidget);
      expect(find.textContaining('约遛'), findsOneWidget);
      expect(find.textContaining('加好友'), findsOneWidget);
    });

    testWidgets('empty CTA switches toward Feed path', (tester) async {
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
      final world = WorldStore();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            ChangeNotifierProvider<AuthService>.value(value: auth),
            Provider<CloudSyncService>.value(value: sync),
            ChangeNotifierProvider.value(value: world),
          ],
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const HomeShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Profile tab.
      await tester.tap(find.text(S(true).get('profile.tab')));
      await tester.pumpAndSettle();
      await scrollTap(tester, find.byKey(const Key('profile.my_posts')));
      await tester.tap(find.byKey(const Key('profile.my_posts.empty_cta')));
      await tester.pump(); // switch tab
      await tester.pump(const Duration(milliseconds: 50));
      // Feed focus highlight schedules a 2s timer — drain it.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should leave SCR-12 and land on Feed (tab label / empty photo CTA).
      expect(find.byKey(const Key('profile.my_posts.page')), findsNothing);
      expect(
        find.text(S(true).get('feed.tab')).hitTestable(),
        findsWidgets,
      );
    });
  });

  test('no fake social metrics keys on my-posts surface', () {
    final zh = S(true);
    expect(zh.get('profile.my_posts_sub'), isNot(contains('关注')));
    expect(zh.get('profile.my_posts_sub'), isNot(contains('获赞')));
    expect(zh.get('profile.my_posts_sub'), contains('本机'));
  });
}
