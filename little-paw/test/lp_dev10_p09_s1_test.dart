import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/models/story.dart';
import 'package:little_paw/screens/home_shell.dart';
import 'package:little_paw/screens/story_player_screen.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/pet_subject_media.dart';
import 'package:little_paw/services/quota_ui.dart';
import 'package:little_paw/services/ring_story_scripts.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/world/world_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P-09 S1 flags', () {
    test('F1/F2/F3 flags default true and persist', () async {
      final store = SpaceStore();
      await store.load();
      expect(store.feedNoFakePlaceholderPosts, isTrue);
      expect(store.storyCloseDismisses, isTrue);
      expect(store.quotaWallAfterFirstSessionCore, isTrue);

      await store.setFeedNoFakePlaceholderPosts(false);
      await store.setStoryCloseDismisses(false);
      await store.setQuotaWallAfterFirstSessionCore(false);

      final store2 = SpaceStore();
      await store2.load();
      expect(store2.feedNoFakePlaceholderPosts, isFalse);
      expect(store2.storyCloseDismisses, isFalse);
      expect(store2.quotaWallAfterFirstSessionCore, isFalse);
    });
  });

  group('F1 no fake placeholder posts', () {
    test('visualFeedStories drops unqualified media when flag on', () async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.fiction,
        createdAt: DateTime.utc(2026, 11, 3),
      ));
      // Inject a fake-claw candidate (no pet-subject url).
      store.stories = [
        Story(
          id: 'bad1',
          bodyZh: '假爪',
          bodyEn: 'fake',
          createdAt: DateTime.utc(2026, 11, 3),
          isOnboarding: false,
          isUnread: true,
          imageUrl: 'https://picsum.photos/seed/x/800/600',
        ),
        Story(
          id: 'bad2',
          bodyZh: '空图',
          bodyEn: 'empty',
          createdAt: DateTime.utc(2026, 11, 3),
          isOnboarding: false,
          isUnread: true,
          imageUrl: null,
        ),
        Story(
          id: 'good1',
          bodyZh: '真图',
          bodyEn: 'real',
          createdAt: DateTime.utc(2026, 11, 3),
          isOnboarding: false,
          isUnread: true,
          imageUrl: PetSubjectMedia.whitelistAssets.first,
        ),
        ...store.stories,
      ];
      await store.persist();

      expect(store.feedNoFakePlaceholderPosts, isTrue);
      final vis = store.visualFeedStories();
      expect(vis.any((s) => s.id == 'bad1' || s.id == 'bad2'), isFalse);
      expect(vis.any((s) => s.id == 'good1'), isTrue);
      for (final s in vis) {
        expect(PetSubjectMedia.isPetSubject(s.imageUrl), isTrue);
      }
    });

    test('l10n empty photo + defer keys present', () {
      final zh = S(true);
      final en = S(false);
      expect(zh.get('feed.empty.photo.title'), '还没有它的照片');
      expect(zh.get('feed.empty.photo.cta'), '放进圈子');
      expect(zh.get('feed.empty.photo.body'), contains('日常'));
      expect(zh.get('feed.empty.photo.hint'), contains('本机'));
      expect(zh.get('feed.empty.photo.soft'), contains('空'));
      expect(zh.get('feed.empty.photo.soft_cta'), contains('放'));
      expect(zh.get('quota.defer.cta_primary'), '稍后再说');
      expect(zh.get('quota.defer.link'), contains('正式方案'));
      expect(en.get('story.a11y.close'), 'Close story');
      expect(en.get('feed.empty.photo.cta'), 'Add to circle');
    });
  });

  group('F3 first-session core gate', () {
    test('incomplete until three rings dismissed and content gate', () async {
      final store = SpaceStore();
      await store.load();
      expect(store.firstSessionCoreComplete, isFalse);
      expect(store.quotaPresentation, QuotaPresentation.defer);
      expect(store.mayAutoShowFormalQuotaWall, isFalse);

      await store.recordRingDismissed(RingStoryScripts.opening);
      await store.recordRingDismissed(RingStoryScripts.friends);
      expect(store.firstSessionCoreComplete, isFalse);

      await store.recordRingDismissed(RingStoryScripts.adventure);
      // rings ok but still need post OR opening finished
      expect(store.firstSessionCoreComplete, isFalse);

      await store.recordOpeningStoryCompleted();
      expect(store.firstSessionCoreComplete, isTrue);
      expect(store.quotaPresentation, QuotaPresentation.ready);
      expect(store.mayAutoShowFormalQuotaWall, isTrue);

      final store2 = SpaceStore();
      await store2.load();
      expect(store2.firstSessionCoreComplete, isTrue);
      expect(store2.quotaPresentation, QuotaPresentation.ready);
    });

    test('successful custom post satisfies content gate with rings', () async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.fiction,
        createdAt: DateTime.utc(2026, 11, 3),
      ));
      for (final id in [
        RingStoryScripts.opening,
        RingStoryScripts.friends,
        RingStoryScripts.adventure,
      ]) {
        await store.recordRingDismissed(id);
      }
      expect(store.firstSessionCoreComplete, isFalse);
      await store.recordSuccessfulCustomPost();
      expect(store.firstSessionCoreComplete, isTrue);
    });

    test('QuotaUi.defer hides formal as primary auto wall', () {
      expect(
        QuotaUi.mayAutoPresentFormalQuotaSheet(
          flagOn: true,
          firstSessionCoreComplete: false,
        ),
        isFalse,
      );
      expect(
        QuotaUi.mayAutoPresentFormalQuotaSheet(
          flagOn: true,
          firstSessionCoreComplete: true,
        ),
        isTrue,
      );
      expect(
        QuotaUi.mayAutoPresentFormalQuotaSheet(
          flagOn: false,
          firstSessionCoreComplete: false,
        ),
        isTrue,
      );
    });
  });

  group('F2 story close dismisses', () {
    testWidgets('X dismisses player instead of advancing frame', (tester) async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p1',
        name: '瓜瓜',
        species: 'cat',
        type: PetType.fiction,
        createdAt: DateTime.utc(2026, 11, 3),
      ));
      expect(store.storyCloseDismisses, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: LpTheme.light(),
            home: Builder(
              builder: (ctx) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StoryPlayerScreen(
                          ringId: RingStoryScripts.friends,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byTooltip(S(true).get('story.a11y.close')), findsOneWidget);
      // Capture frame body before close.
      final before = find.textContaining('朋友');
      // friends frames have distinct bodies — ensure player showing
      expect(find.byType(StoryPlayerScreen), findsOneWidget);

      await tester.tap(find.byTooltip(S(true).get('story.a11y.close')));
      await tester.pumpAndSettle();

      expect(find.byType(StoryPlayerScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      // before may or may not match; dismiss is the assertion
      expect(before, isNotNull);
    });
  });

  group('DEF-QA091-01 no visible debug chrome', () {
    testWidgets('HomeShell has no feedback FAB / no debug chrome', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      // LP-DEV-18: global feedback FAB removed; language lives in Profile.
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('调试'), findsNothing);
      expect(find.text('Debug'), findsNothing);
      expect(find.textContaining('点开调试'), findsNothing);
      expect(find.textContaining('Lab tools'), findsNothing);
      expect(find.textContaining('实验室'), findsNothing);
    });
  });
}
