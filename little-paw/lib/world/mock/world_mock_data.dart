// World Tab · mock repository seed · v0.5
import '../models/world_models.dart';

class WorldMockData {
  WorldMockData._();

  static const avatarPrefix = 'assets/world_feed/';

  static List<WorldPet> pets() => const [
        WorldPet(
          id: 'pet_buddy',
          nameZh: '阿布',
          nameEn: 'Buddy',
          breedZh: '金毛',
          breedEn: 'Golden Retriever',
          personalityZh: '热情黏人，容易心动',
          personalityEn: 'Warm, clingy, falls in love easy',
          avatarAsset: 'assets/world_feed/av_01.jpg',
        ),
        WorldPet(
          id: 'pet_mochi',
          nameZh: '麻薯',
          nameEn: 'Mochi',
          breedZh: '英短灰猫',
          breedEn: 'British Shorthair',
          personalityZh: '安静怕冷，生病会偷偷要抱抱',
          personalityEn: 'Quiet, chilly, wants hugs when sick',
          avatarAsset: 'assets/world_feed/av_02.jpg',
        ),
        WorldPet(
          id: 'pet_luna',
          nameZh: '露娜',
          nameEn: 'Luna',
          breedZh: '比格',
          breedEn: 'Beagle',
          personalityZh: '敏感小心，委屈了会躲角落',
          personalityEn: 'Sensitive; hides when hurt',
          avatarAsset: 'assets/world_feed/av_03.jpg',
        ),
        WorldPet(
          id: 'pet_pepper',
          nameZh: '胡椒',
          nameEn: 'Pepper',
          breedZh: '橘猫',
          breedEn: 'Orange tabby',
          personalityZh: '爱炫技，学了新把戏一定要人看',
          personalityEn: 'Show-off; needs an audience for new tricks',
          avatarAsset: 'assets/world_feed/av_04.jpg',
        ),
        WorldPet(
          id: 'pet_sunny',
          nameZh: 'Sunny',
          nameEn: 'Sunny',
          breedZh: '奶油色中型犬',
          breedEn: 'Cream mixed dog',
          personalityZh: '嗜睡派，阳光一照就化成一滩',
          personalityEn: 'Sleepy; melts in sunlight',
          avatarAsset: 'assets/world_feed/av_05.jpg',
        ),
        WorldPet(
          id: 'pet_coco',
          nameZh: '可可',
          nameEn: 'Coco',
          breedZh: '黑白猫',
          breedEn: 'Tuxedo cat',
          personalityZh: '小吃货，眼神无辜但爪子很忙',
          personalityEn: 'Snack thief with innocent eyes',
          avatarAsset: 'assets/world_feed/av_06.jpg',
        ),
        WorldPet(
          id: 'pet_rex',
          nameZh: '雷克斯',
          nameEn: 'Rex',
          breedZh: '边境牧羊犬',
          breedEn: 'Border Collie',
          personalityZh: '雨停就想出门狂奔',
          personalityEn: 'Bolts outside the second rain stops',
          avatarAsset: 'assets/world_feed/av_07.jpg',
        ),
        WorldPet(
          id: 'pet_bao',
          nameZh: '小包',
          nameEn: 'Bao',
          breedZh: '垂耳兔',
          breedEn: 'Lop rabbit',
          personalityZh: '软萌宅，喜欢纸箱角落',
          personalityEn: 'Soft homebody; loves cardboard corners',
          avatarAsset: 'assets/world_feed/av_08.jpg',
        ),
      ];

  static List<WorldPost> posts() {
    final now = DateTime.now();
    return [
      WorldPost(
        id: 'post_01',
        petId: 'pet_buddy',
        bodyZh:
            '今天……我好像找到女朋友了。公园里那只白白的她鼻尖碰了我一下，我整条尾巴都不会摇了，只会傻笑。希望明天她还来。',
        bodyEn:
            'I think I found a girlfriend today. That fluffy white one tapped my nose in the park and my tail forgot how to wag—just goofy smiles. Hope she comes back tomorrow.',
        imageAsset: 'assets/world_feed/post_01.jpg',
        postedAt: now.subtract(const Duration(minutes: 28)),
        likeCount: 128,
        moodZh: '心动',
        moodEn: 'Crushing',
        comments: [
          WorldComment(
            id: 'c01a',
            authorZh: '麻薯',
            authorEn: 'Mochi',
            textZh: '哇，进度好快！下次带她来晒太阳。',
            textEn: 'Wow, fast! Bring her to sunbathe next time.',
            at: now.subtract(const Duration(minutes: 20)),
          ),
          WorldComment(
            id: 'c01b',
            authorZh: '可可',
            authorEn: 'Coco',
            textZh: '记住先分享零食，恋爱稳。',
            textEn: 'Share snacks first. Romance tip.',
            at: now.subtract(const Duration(minutes: 12)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_02',
        petId: 'pet_mochi',
        bodyZh:
            '感冒发烧在家养病。毯子裹成寿司卷，鼻子堵得呼噜响。人类一直摸我额头，我假装嫌弃，其实有点安心。想快点好起来去窗台蹲鸟。',
        bodyEn:
            'Home sick with a fever. Rolled into a sushi blanket, nose whistling. Human keeps checking my forehead—I pretend to hate it, but it helps. Want to bird-watch on the sill again soon.',
        imageAsset: 'assets/world_feed/post_02.jpg',
        postedAt: now.subtract(const Duration(hours: 2)),
        likeCount: 96,
        moodZh: '虚弱',
        moodEn: 'Under the weather',
        comments: [
          WorldComment(
            id: 'c02a',
            authorZh: 'Sunny',
            authorEn: 'Sunny',
            textZh: '多喝水，我把自己的阳光位借你。',
            textEn: 'Drink water. You can borrow my sun spot.',
            at: now.subtract(const Duration(hours: 1, minutes: 40)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_03',
        petId: 'pet_luna',
        bodyZh:
            '被人欺负了，好难过。那只大狗抢了球还冲我吠，我躲到长椅下面，爪子还在抖。如果有人愿意坐过来陪我一会儿，我就把最后半块饼干分给你。',
        bodyEn:
            'Got bullied and I feel awful. A big dog stole the ball and barked at me. I hid under the bench, paws still shaking. Sit with me a bit and I will share my last half-biscuit.',
        imageAsset: 'assets/world_feed/post_03.jpg',
        postedAt: now.subtract(const Duration(hours: 4)),
        likeCount: 214,
        moodZh: '委屈',
        moodEn: 'Hurt',
        comments: [
          WorldComment(
            id: 'c03a',
            authorZh: '阿布',
            authorEn: 'Buddy',
            textZh: '我去陪你。谁再凶你，我站前面。',
            textEn: 'I am coming. Anyone mean gets me in front.',
            at: now.subtract(const Duration(hours: 3, minutes: 50)),
          ),
          WorldComment(
            id: 'c03b',
            authorZh: '胡椒',
            authorEn: 'Pepper',
            textZh: '给你一个虚拟舔毛。你很勇敢。',
            textEn: 'Virtual groom for you. You are brave.',
            at: now.subtract(const Duration(hours: 3, minutes: 30)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_04',
        petId: 'pet_pepper',
        bodyZh:
            '学会了新技能！！把小球拨进纸杯里，三进两出，人类鼓掌比我还激动。今晚加餐罐头，我宣布自己是客厅运动员。',
        bodyEn:
            'New skill unlocked. Flicked the ball into a paper cup—three in, two out. Human clapped harder than me. Extra wet food tonight. I am the living-room athlete.',
        imageAsset: 'assets/world_feed/post_04.jpg',
        postedAt: now.subtract(const Duration(hours: 6)),
        likeCount: 177,
        moodZh: '骄傲',
        moodEn: 'Proud',
        comments: [
          WorldComment(
            id: 'c04a',
            authorZh: '小包',
            authorEn: 'Bao',
            textZh: '教我！我只会顶纸箱。',
            textEn: 'Teach me! I only headbutt boxes.',
            at: now.subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_05',
        petId: 'pet_sunny',
        bodyZh:
            '晒太阳犯困。地板被晒成小烤箱，我摊成一张饼，眼睛眯成一条缝。谁叫我我都回一句「五分钟后再说」，然后继续融化。',
        bodyEn:
            'Sunbathing and dozing off. The floor is a tiny oven; I pancake out, eyes half shut. Whoever calls me gets a "five more minutes" before I melt again.',
        imageAsset: 'assets/world_feed/post_05.jpg',
        postedAt: now.subtract(const Duration(hours: 8)),
        likeCount: 143,
        moodZh: '犯困',
        moodEn: 'Sleepy',
        comments: const [],
      ),
      WorldPost(
        id: 'post_06',
        petId: 'pet_coco',
        bodyZh:
            '我不是偷吃，我是质量抽检。柜台上的小鱼干少了三根——证据在我胡须上。人类假装没看见，我们达成了默契。',
        bodyEn:
            'Not stealing—quality control. Three fish treats gone from the counter; evidence on my whiskers. Human pretended not to see. Mutual understanding achieved.',
        imageAsset: 'assets/world_feed/post_06.jpg',
        postedAt: now.subtract(const Duration(hours: 11)),
        likeCount: 201,
        moodZh: '得意',
        moodEn: 'Smug',
        comments: [
          WorldComment(
            id: 'c06a',
            authorZh: '麻薯',
            authorEn: 'Mochi',
            textZh: '抽检员辛苦了（翻白眼）。',
            textEn: 'Hard work, inspector (eye roll).',
            at: now.subtract(const Duration(hours: 10)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_07',
        petId: 'pet_rex',
        bodyZh:
            '雨停了！泥土味道像节日。我在水坑边踩出一串小月亮，耳朵被风扯得飞起来。人类说「慢一点」，但我的腿听不见。',
        bodyEn:
            'Rain stopped! Mud smells like a festival. I stomped a string of little moons by the puddle, ears flying in the wind. Human said "slow down"—my legs did not hear.',
        imageAsset: 'assets/world_feed/post_07.jpg',
        postedAt: now.subtract(const Duration(hours: 15)),
        likeCount: 88,
        moodZh: '兴奋',
        moodEn: 'Wired',
        comments: [
          WorldComment(
            id: 'c07a',
            authorZh: '露娜',
            authorEn: 'Luna',
            textZh: '下次一起，我负责闻路线。',
            textEn: 'Next time I will sniff the route.',
            at: now.subtract(const Duration(hours: 14)),
          ),
        ],
      ),
      WorldPost(
        id: 'post_08',
        petId: 'pet_bao',
        bodyZh:
            '纸箱角落是我的云朵房间。今天在里面打了一个很长的盹，梦见自己变成棉花糖。醒来发现耳朵被压歪了，但心情是软软的。',
        bodyEn:
            'The cardboard corner is my cloud room. Took a long nap inside and dreamed I was marshmallow. Woke with a bent ear and a soft heart.',
        imageAsset: 'assets/world_feed/post_08.jpg',
        postedAt: now.subtract(const Duration(hours: 20)),
        likeCount: 156,
        moodZh: '安稳',
        moodEn: 'Cozy',
        comments: [
          WorldComment(
            id: 'c08a',
            authorZh: '胡椒',
            authorEn: 'Pepper',
            textZh: '云朵房间听起来很贵，我要参观。',
            textEn: 'Cloud room sounds fancy. Tour please.',
            at: now.subtract(const Duration(hours: 18)),
          ),
        ],
      ),
    ];
  }

  static List<WorldMarketItem> market() => const [
        WorldMarketItem(
          id: 'mkt_buddy',
          petId: 'pet_buddy',
          titleZh: '阿布 · 阳光伙伴',
          titleEn: 'Buddy · Sunny pal',
          taglineZh: '适合想被每天热情问候的人',
          taglineEn: 'For folks who want a warm daily hello',
          imageAsset: 'assets/world_feed/post_01.jpg',
          status: MarketAcquireStatus.locked,
          demoPaid: true,
        ),
        WorldMarketItem(
          id: 'mkt_mochi',
          petId: 'pet_mochi',
          titleZh: '麻薯 · 安静陪伴',
          titleEn: 'Mochi · Quiet company',
          taglineZh: '慢热，适合一起窝着养病的日子',
          taglineEn: 'Slow-warm; good for quiet sick days',
          imageAsset: 'assets/world_feed/post_02.jpg',
          status: MarketAcquireStatus.trial,
        ),
        WorldMarketItem(
          id: 'mkt_pepper',
          petId: 'pet_pepper',
          titleZh: '胡椒 · 客厅运动员',
          titleEn: 'Pepper · Living-room athlete',
          taglineZh: '会天天给你看新把戏',
          taglineEn: 'Will show you new tricks daily',
          imageAsset: 'assets/world_feed/post_04.jpg',
          status: MarketAcquireStatus.locked,
          demoPaid: true,
        ),
        WorldMarketItem(
          id: 'mkt_bao',
          petId: 'pet_bao',
          titleZh: '小包 · 云朵角落',
          titleEn: 'Bao · Cloud corner',
          taglineZh: '已拥有：软软的纸箱哲学家',
          taglineEn: 'Owned: soft cardboard philosopher',
          imageAsset: 'assets/world_feed/post_08.jpg',
          status: MarketAcquireStatus.owned,
        ),
      ];
}
