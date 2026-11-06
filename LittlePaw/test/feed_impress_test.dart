import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/feed_fill.dart';
import 'package:little_paw/services/story_impression.dart';
import 'package:little_paw/models/story.dart';

void main() {
  group('DEF-QA04-01 Feed impress rules', () {
    test('off-screen (ratio 0) does not impress after 2s', () {
      fakeAsync((async) {
        final tracker = StoryImpressionTracker();
        tracker.updateVisibility('day_1', 0.0);
        expect(tracker.hasActiveDwell('day_1'), false);
        async.elapse(const Duration(seconds: 3));
        expect(tracker.impressed.contains('day_1'), false);
        tracker.dispose();
      });
    });

    test('partial visible dwell 2s impresses; leave cancels', () {
      fakeAsync((async) {
        final tracker = StoryImpressionTracker();
        tracker.updateVisibility('day_1', 0.4);
        expect(tracker.hasActiveDwell('day_1'), true);
        async.elapse(const Duration(milliseconds: 500));
        tracker.updateVisibility('day_1', 0.0);
        expect(tracker.hasActiveDwell('day_1'), false);
        async.elapse(const Duration(seconds: 3));
        expect(tracker.impressed.contains('day_1'), false);

        tracker.updateVisibility('day_1', 0.5);
        async.elapse(const Duration(seconds: 2));
        expect(tracker.impressed.contains('day_1'), true);
        tracker.dispose();
      });
    });

    test('>=80% visible impresses immediately without waiting 2s', () {
      fakeAsync((async) {
        final tracker = StoryImpressionTracker();
        tracker.updateVisibility('day_2', 0.85);
        expect(tracker.impressed.contains('day_2'), true);
        expect(tracker.hasActiveDwell('day_2'), false);
        tracker.dispose();
      });
    });

    test('demo fill ids are not required for tracker; fill flagged separately', () {
      final fills = FeedFill.demoPosts('Mochi');
      expect(fills.every((s) => s.isDemoFill), true);
      // Tracker may track any id; FeedTab skips calling update for isDemoFill.
      final tracker = StoryImpressionTracker();
      tracker.updateVisibility(fills.first.id, 0.9);
      expect(tracker.impressed.contains(fills.first.id), true);
      tracker.dispose();
    });
  });

  group('DEF-QA04-02 layout vs fill independence', () {
    test('merge only used when layout+fill conceptually on (pure helper)', () {
      final real = [
        Story(
          id: 'r1',
          bodyZh: '真',
          bodyEn: 'r',
          createdAt: DateTime.utc(2026, 11, 3),
        ),
      ];
      final merged = FeedFill.merge(real, 'Mochi');
      expect(merged.length, greaterThanOrEqualTo(6));
      // Classic path would return `real` only (tested via store flag semantics).
      expect(real.length, 1);
    });
  });
}
