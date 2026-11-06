import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/services/feed_fill.dart';
import 'package:little_paw/services/life_scripts.dart';
import 'package:little_paw/services/pet_subject_media.dart';
import 'package:little_paw/services/ring_story_scripts.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/l10n/strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('P-07 flags default on and persist', () async {
    final store = SpaceStore();
    await store.load();
    expect(store.storiesRingPlayerEnabled, true);
    expect(store.feedPetSubjectMediaOnly, true);
    expect(store.activityChatPrimaryEnabled, true);

    await store.setStoriesRingPlayerEnabled(false);
    await store.setFeedPetSubjectMediaOnly(false);
    await store.setActivityChatPrimaryEnabled(false);

    final store2 = SpaceStore();
    await store2.load();
    expect(store2.storiesRingPlayerEnabled, false);
    expect(store2.feedPetSubjectMediaOnly, false);
    expect(store2.activityChatPrimaryEnabled, false);
  });

  test('ring scripts: three rings have distinct content sets', () {
    final opening = RingStoryScripts.framesFor(
      ringId: RingStoryScripts.opening,
      petName: '瓜瓜',
      onboarding: LifeScripts.onboardingStories('瓜瓜'),
    );
    final friends = RingStoryScripts.friendsFrames('瓜瓜');
    final adventure = RingStoryScripts.adventureFrames('瓜瓜');
    expect(opening.length, greaterThanOrEqualTo(1));
    expect(friends.length, greaterThanOrEqualTo(1));
    expect(adventure.length, greaterThanOrEqualTo(1));
    expect(friends.first.bodyZh, isNot(adventure.first.bodyZh));
    expect(opening.first.id.startsWith('onb_'), true);
  });

  test('pet subject: picsum rejected; whitelist assets accepted', () {
    expect(
      PetSubjectMedia.isForbiddenLandscape(
          'https://picsum.photos/seed/cactus/800/600'),
      true,
    );
    expect(
      PetSubjectMedia.isPetSubject(
          'https://picsum.photos/seed/cactus/800/600'),
      false,
    );
    expect(
      PetSubjectMedia.resolveForFeed(
        'https://picsum.photos/seed/cactus/800/600',
        petOnly: true,
      ),
      isNull,
    );
    expect(
      PetSubjectMedia.resolveForFeed(
        'assets/world_feed/post_01.jpg',
        petOnly: true,
      ),
      'assets/world_feed/post_01.jpg',
    );
  });

  test('life_scripts / feed_fill have no picsum main images', () {
    final onb = LifeScripts.onboardingStories('Mochi');
    for (final s in onb) {
      expect(s.imageUrl, isNot(contains('picsum')));
      expect(PetSubjectMedia.isPetSubject(s.imageUrl), true);
    }
    final day = LifeScripts.dailyStories('Mochi', '2026-11-03');
    for (final s in day) {
      expect(s.imageUrl, isNot(contains('picsum')));
    }
    final fills = FeedFill.demoPosts('Mochi');
    for (final s in fills) {
      expect(s.imageUrl, isNot(contains('picsum')));
      expect(PetSubjectMedia.isPetSubject(s.imageUrl), true);
    }
  });

  test('guest chat: seed + send local script reply', () async {
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'cat',
      type: PetType.fiction,
      createdAt: DateTime.utc(2026, 11, 3),
    ));
    await store.ensureChatSeeded();
    expect(store.chatMessages, isNotEmpty);
    store.economy.credit(Economy.coinCostChat * 5, 'checkin');
    final before = store.chatMessages.length;
    final reply = await store.sendChatMessage('今天开心吗？');
    expect(reply, isNotNull);
    expect(store.chatMessages.length, before + 2); // user + pet
    expect(store.chatMessages.last.sender.name, 'pet');
  });

  test('chat quota hit blocks send', () async {
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'cat',
      type: PetType.fiction,
      createdAt: DateTime.utc(2026, 11, 3),
    ));
    store.economy.credit(Economy.coinCostChat * 5, 'checkin');
    store.economy.repliesUsedToday = store.economy.repliesLimit;
    final r = await store.sendChatMessage('再聊一句');
    expect(r, isNull);
    expect(store.hadQuotaHit, true);
  });

  test('activity/story copy has no fake 即将开放 on primary keys', () {
    final zh = S(true);
    expect(zh.get('activity.chat.empty_cta'), isNot(contains('即将开放')));
    expect(zh.get('activity.chat.empty_body'), contains('聊'));
    expect(zh.get('feed.story.opening_toast'), isNot(contains('即将开放')));
    expect(zh.get('feed.story.placeholder_toast'), isNot(contains('即将开放')));
    expect(zh.get('story.empty.title'), isNot(contains('即将开放')));
  });

  test('flag off: activityChatPrimaryEnabled false keeps legacy path available',
      () async {
    final store = SpaceStore();
    await store.load();
    await store.setActivityChatPrimaryEnabled(false);
    expect(store.activityChatPrimaryEnabled, false);
  });
}
