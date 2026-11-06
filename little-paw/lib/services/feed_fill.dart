import '../models/story.dart';
import 'pet_subject_media.dart';

/// Demo visual fill so Feed shows ≥6 PostCards. Does not consume economy.
class FeedFill {
  static const int minVisualCount = 6;

  static List<Story> demoPosts(String petName, {DateTime? now}) {
    final t = now ?? DateTime.now().toUtc();
    final templates = <List<String>>[
      ['窗边晒了一会儿肚皮，风刚好。', 'Sunbelly by the window—breeze just right.', 'sun'],
      ['小跑两圈，又假装很忙。', 'Trotted twice, then pretended to be busy.', 'run'],
      ['饭盆空了？我用眼神提醒你。', 'Bowl empty? Sending eye lasers.', 'bowl'],
      ['纸箱才是王座。', 'The cardboard box is the throne.', 'box'],
      ['追光斑失败，但心情不错。', 'Missed the light spot—still happy.', 'light'],
      ['打个盹，梦见你回来了。', 'Napped and dreamed you came home.', 'nap'],
      ['窗台上的鸟很吵，我假装没兴趣。', 'Noisy birds—feigning indifference.', 'bird'],
      ['新毯子味道很好闻。', 'New blanket smells amazing.', 'blanket'],
    ];
    return [
      for (var i = 0; i < templates.length; i++)
        Story(
          id: 'fill_$i',
          bodyZh: templates[i][0],
          bodyEn: templates[i][1],
          createdAt: t.subtract(Duration(hours: i + 1)),
          isOnboarding: false,
          isUnread: false,
          isDemoFill: true,
          aspect: StoryAspect.ratio43,
          locationLabel: 'Cloud Town',
          // Pet-subject local asset (no landscape fillers)
          imageUrl: PetSubjectMedia.assetForSeed('littlepaw_${templates[i][2]}_$i'),
        ),
    ];
  }

  /// Merge real feed stories with fill until [minVisualCount]. Real first.
  static List<Story> merge(List<Story> real, String petName) {
    final out = List<Story>.from(real);
    if (out.length >= minVisualCount) return out;
    final fills = demoPosts(petName);
    for (final f in fills) {
      if (out.length >= minVisualCount) break;
      if (out.any((s) => s.id == f.id)) continue;
      out.add(f);
    }
    return out;
  }
}
