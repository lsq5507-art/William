import '../models/story.dart';
import 'pet_subject_media.dart';

/// Frame model for SCR-ST story player (local seed; no LLM).
class RingStoryFrame {
  final String id;
  final String bodyZh;
  final String bodyEn;
  final String? imageUrl;
  final ColorHint colorHint;

  const RingStoryFrame({
    required this.id,
    required this.bodyZh,
    required this.bodyEn,
    this.imageUrl,
    this.colorHint = ColorHint.warm,
  });

  String body(bool zh) => zh ? bodyZh : bodyEn;
}

enum ColorHint { warm, soft, sky, mint }

/// Independent content sets for story rings (LP-D-07 §2.1).
class RingStoryScripts {
  static const opening = 'opening';
  static const friends = 'friend';
  static const adventure = 'adventure';

  /// Opening: map onboarding [Story] list → frames (SCR-03 revisit).
  static List<RingStoryFrame> fromOnboardingStories(List<Story> stories) {
    return [
      for (final s in stories)
        RingStoryFrame(
          id: s.id,
          bodyZh: s.bodyZh,
          bodyEn: s.bodyEn,
          imageUrl: PetSubjectMedia.resolveForFeed(
            s.imageUrl,
            petOnly: true,
          ),
          colorHint: ColorHint.warm,
        ),
    ];
  }

  static List<RingStoryFrame> friendsFrames(String petName) => [
        RingStoryFrame(
          id: 'ring_friend_1',
          bodyZh: '$petName 在院子里碰到了一只毛茸茸的新朋友，两只鼻子轻轻碰了碰。',
          bodyEn: '$petName met a fluffy new friend in the yard—noses bumped softly.',
          imageUrl: PetSubjectMedia.assetForSeed('friend_1'),
          colorHint: ColorHint.soft,
        ),
        RingStoryFrame(
          id: 'ring_friend_2',
          bodyZh: '它们轮流追一片落叶，笑得尾巴都停不下来。',
          bodyEn: 'They took turns chasing a leaf until their tails would not stop.',
          imageUrl: PetSubjectMedia.assetForSeed('friend_2'),
          colorHint: ColorHint.mint,
        ),
        RingStoryFrame(
          id: 'ring_friend_3',
          bodyZh: '分别前，$petName 回头看了你一眼：明天还要约吗？',
          bodyEn: 'Before parting, $petName glanced back at you: same time tomorrow?',
          imageUrl: PetSubjectMedia.assetForSeed('friend_3'),
          colorHint: ColorHint.warm,
        ),
      ];

  static List<RingStoryFrame> adventureFrames(String petName) => [
        RingStoryFrame(
          id: 'ring_adv_1',
          bodyZh: '$petName 踮脚探进沙发底下的「洞穴」，发现了一枚失踪的小球。',
          bodyEn: '$petName peeked into the sofa cave and found a missing ball.',
          imageUrl: PetSubjectMedia.assetForSeed('adv_1'),
          colorHint: ColorHint.sky,
        ),
        RingStoryFrame(
          id: 'ring_adv_2',
          bodyZh: '小球滚过地毯，像一颗小行星。探险日记写上：今日收获满满。',
          bodyEn: 'The ball rolled across the rug like a tiny planet. Log: good haul today.',
          imageUrl: PetSubjectMedia.assetForSeed('adv_2'),
          colorHint: ColorHint.mint,
        ),
        RingStoryFrame(
          id: 'ring_adv_3',
          bodyZh: '探险结束，$petName 趴在你脚边喘气——小小世界，刚刚好。',
          bodyEn: 'Adventure done. $petName flopped by your feet—small world, just right.',
          imageUrl: PetSubjectMedia.assetForSeed('adv_3'),
          colorHint: ColorHint.warm,
        ),
      ];

  static List<RingStoryFrame> framesFor({
    required String ringId,
    required String petName,
    List<Story> onboarding = const [],
  }) {
    switch (ringId) {
      case opening:
        return fromOnboardingStories(onboarding);
      case friends:
        return friendsFrames(petName);
      case adventure:
        return adventureFrames(petName);
      default:
        return const [];
    }
  }
}
