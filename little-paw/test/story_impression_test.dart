import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/story_impression.dart';

void main() {
  test('DEF-01: off-screen cards do not impress after 2s without visibility', () {
    fakeAsync((async) {
      final tracker = StoryImpressionTracker();
      // Only first card mostly visible; others never measured in viewport.
      tracker.updateVisibility('onb_1', 0.9);
      tracker.updateVisibility('onb_2', 0.0);
      tracker.updateVisibility('onb_3', 0.0);

      expect(tracker.impressed.contains('onb_1'), true);
      expect(tracker.impressedCount, 1);
      expect(tracker.hasActiveDwell('onb_2'), false);
      expect(tracker.hasActiveDwell('onb_3'), false);

      async.elapse(const Duration(seconds: 3));

      // Still only 1/3 — cannot enter Feed.
      expect(tracker.impressedCount, 1);
      expect(tracker.isComplete, false);

      tracker.dispose();
    });
  });

  test('DEF-01: partial visible starts dwell; leaving cancels timer', () {
    fakeAsync((async) {
      final tracker = StoryImpressionTracker();

      tracker.updateVisibility('onb_2', 0.4); // in view, <80%
      expect(tracker.hasActiveDwell('onb_2'), true);
      expect(tracker.impressed.contains('onb_2'), false);

      // Scroll away before 2s.
      async.elapse(const Duration(milliseconds: 500));
      tracker.updateVisibility('onb_2', 0.0);
      expect(tracker.hasActiveDwell('onb_2'), false);

      async.elapse(const Duration(seconds: 3));
      expect(tracker.impressed.contains('onb_2'), false);

      // Come back and dwell fully.
      tracker.updateVisibility('onb_2', 0.5);
      async.elapse(const Duration(seconds: 2));
      expect(tracker.impressed.contains('onb_2'), true);

      tracker.dispose();
    });
  });

  test('DEF-01: all three need real visibility before complete', () {
    fakeAsync((async) {
      final tracker = StoryImpressionTracker();

      tracker.updateVisibility('a', 0.85);
      tracker.updateVisibility('b', 0.3);
      tracker.updateVisibility('c', 0.0);
      async.elapse(const Duration(seconds: 2));
      expect(tracker.impressedCount, 2); // a immediate, b dwell
      expect(tracker.isComplete, false);

      tracker.updateVisibility('c', 0.81);
      expect(tracker.isComplete, true);

      tracker.dispose();
    });
  });
}
