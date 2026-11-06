import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/models/story.dart';
import 'package:little_paw/services/feed_fill.dart';
import 'package:little_paw/l10n/strings.dart';

void main() {
  test('FeedFill merges to at least 6 visual posts without consuming real ids', () {
    final real = [
      Story(
        id: 'day_1',
        bodyZh: '真',
        bodyEn: 'real',
        createdAt: DateTime.utc(2026, 11, 3),
        isUnread: true,
      ),
    ];
    final merged = FeedFill.merge(real, 'Mochi');
    expect(merged.length, greaterThanOrEqualTo(6));
    expect(merged.first.id, 'day_1');
    expect(merged.where((s) => s.isDemoFill).length, greaterThanOrEqualTo(5));
    for (final f in merged.where((s) => s.isDemoFill)) {
      expect(f.aspect, StoryAspect.ratio43);
      expect(f.imageUrl != null && f.imageUrl!.isNotEmpty, true);
    }
  });

  test('Story json roundtrip keeps media fields with defaults for legacy', () {
    final legacy = Story.fromJson({
      'id': 'x',
      'bodyZh': '中',
      'bodyEn': 'en',
      'createdAt': '2026-11-03T00:00:00.000Z',
    });
    expect(legacy.imageUrl, isNull);
    expect(legacy.isDemoFill, false);
    expect(legacy.aspect, StoryAspect.ratio43);

    final full = Story(
      id: 'y',
      bodyZh: 'a',
      bodyEn: 'b',
      createdAt: DateTime.utc(2026, 11, 3),
      imageUrl: 'https://example.com/a.jpg',
      aspect: StoryAspect.portrait45,
      isDemoFill: true,
    );
    final back = Story.fromJson(full.toJson());
    expect(back.imageUrl, full.imageUrl);
    expect(back.isDemoFill, true);
    expect(back.aspectRatio, closeTo(0.8, 0.01));
  });

  test('D-03 caption/like keys present', () {
    expect(S(true).get('feed.caption.more'), '更多');
    expect(S(false).get('feed.like'), 'Like');
  });
}
