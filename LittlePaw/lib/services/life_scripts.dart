import '../models/story.dart';
import '../models/comment.dart';

/// Scripted first-person stories & reply templates (no real LLM).
class LifeScripts {
  static List<Story> onboardingStories(String petName, {DateTime? at}) {
    final now = at ?? DateTime.now().toUtc();
    return [
      Story(
        id: 'onb_1',
        bodyZh: '嗨，$petName 在这儿。阳光刚好，我先伸了个懒腰，决定今天从窗边开始。',
        bodyEn: 'Hi—$petName here. The sun feels right, so I stretched and started by the window.',
        createdAt: now.subtract(const Duration(minutes: 3)),
        isOnboarding: true,
        isUnread: true,
      ),
      Story(
        id: 'onb_2',
        bodyZh: '我发现一只灰尘小精灵，追着它转了两圈。没抓到，但很好玩。',
        bodyEn: 'I spotted a dust sprite and chased it twice. Missed it—still fun.',
        createdAt: now.subtract(const Duration(minutes: 2)),
        isOnboarding: true,
        isUnread: true,
      ),
      Story(
        id: 'onb_3',
        bodyZh: '如果你回我一句，我会认真听。今天的日常，从这里开始。',
        bodyEn: 'If you reply, I will listen. Today starts right here.',
        createdAt: now.subtract(const Duration(minutes: 1)),
        isOnboarding: true,
        isUnread: true,
      ),
    ];
  }

  /// Daily feed stories (script). New ones appear on revisit when quota allows.
  static List<Story> dailyStories(String petName, String utcDay, {int count = 2}) {
    final templates = <List<String>>[
      [
        '今天 $utcDay，我在毯子上打了个小盹，梦见你挠我下巴。',
        'On $utcDay I napped on the blanket and dreamed you scratched my chin.',
      ],
      [
        '我把球踢到沙发下面了。等你回来一起侦察？',
        'I kicked the ball under the sofa. Scout with me later?',
      ],
      [
        '窗外有鸟唱歌。我假装没兴趣，其实耳朵一直竖着。',
        'Birds sang outside. I pretended not to care—ears up the whole time.',
      ],
      [
        '喝了一口水，又趴回去。生活节奏刚刚好。',
        'Took a sip of water, then flopped down. Pace feels just right.',
      ],
    ];
    final out = <Story>[];
    for (var i = 0; i < count && i < templates.length; i++) {
      out.add(Story(
        id: 'day_${utcDay}_$i',
        bodyZh: templates[i][0],
        bodyEn: templates[i][1],
        createdAt: DateTime.now().toUtc().subtract(Duration(minutes: count - i)),
        isOnboarding: false,
        isUnread: true,
      ));
    }
    return out;
  }

  static const List<String> suggestionChipsZh = [
    '今天开心吗？',
    '我也想你',
    '继续说说',
  ];

  static const List<String> suggestionChipsEn = [
    'Happy today?',
    'Miss you too',
    'Tell me more',
  ];

  static CommentThread makeReply({
    required String storyId,
    required String userText,
    required String petName,
  }) {
    final id = 'c_${DateTime.now().millisecondsSinceEpoch}';
    return CommentThread(
      id: id,
      storyId: storyId,
      userText: userText,
      replyZh: '嗯嗯，$petName 听到了：「$userText」。尾巴轻轻晃了一下。',
      replyEn: 'Mm, $petName heard you: "$userText". Tail gave a little wag.',
      createdAt: DateTime.now().toUtc(),
      replyUnread: true,
    );
  }

  static const List<List<String>> followUpChoicesZh = [
    ['再晒一会儿太阳', '去找玩具'],
    ['趴着看你', '去窗边听听'],
  ];

  static const List<List<String>> followUpChoicesEn = [
    ['Sun a bit more', 'Find a toy'],
    ['Watch you quietly', 'Listen by the window'],
  ];

  /// First bounded follow-up pair (not open-ended chat).
  static List<String> followUpPair(bool zh) =>
      zh ? followUpChoicesZh.first : followUpChoicesEn.first;

  static Story followUpStory({
    required String petName,
    required String choiceLabelZh,
    required String choiceLabelEn,
    required String parentStoryId,
  }) {
    final id =
        'follow_${parentStoryId}_${DateTime.now().millisecondsSinceEpoch}';
    return Story(
      id: id,
      bodyZh: '好，$petName 选了「$choiceLabelZh」。我接着过小日子，等你再来看。',
      bodyEn:
          'Okay—$petName picked "$choiceLabelEn". Keeping the day going; come back soon.',
      createdAt: DateTime.now().toUtc(),
      isOnboarding: false,
      isUnread: true,
    );
  }
}
