import 'dart:async';

/// Viewport impression rules for SCR-03 / M7 (O3):
/// - ratio >= 0.8 → complete immediately
/// - 0 < ratio < 0.8 → dwell >= 2s while still in viewport
/// - ratio == 0 (left viewport) → cancel unfinished dwell timer
/// Never start dwell for cards that have not been measured in-viewport.
class StoryImpressionTracker {
  StoryImpressionTracker({
    this.dwell = const Duration(seconds: 2),
    this.onImpressed,
    this.now,
  });

  final Duration dwell;
  final void Function(String id)? onImpressed;
  /// Injectable clock for tests.
  final DateTime Function()? now;

  final Set<String> impressed = {};
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> dwellStarted = {};

  bool get isComplete => impressed.length >= 3;
  int get impressedCount => impressed.length;

  /// Update visibility ratio for one story card (0.0–1.0+).
  void updateVisibility(String id, double ratio) {
    if (impressed.contains(id)) return;

    if (ratio >= 0.8) {
      _cancelTimer(id);
      _mark(id);
      return;
    }

    if (ratio > 0) {
      // Partially visible: start dwell once; keep running while still in view.
      dwellStarted.putIfAbsent(id, () => (now ?? DateTime.now)());
      _timers.putIfAbsent(id, () {
        return Timer(dwell, () {
          // Only complete if still tracked as in-viewport dwell (timer not cancelled).
          if (!impressed.contains(id)) {
            _mark(id);
          }
        });
      });
      return;
    }

    // Not in viewport — cancel unfinished dwell.
    _cancelTimer(id);
    dwellStarted.remove(id);
  }

  void _mark(String id) {
    if (impressed.contains(id)) return;
    impressed.add(id);
    _cancelTimer(id);
    dwellStarted.remove(id);
    onImpressed?.call(id);
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.cancel();
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Test helper: whether a dwell timer is active for [id].
  bool hasActiveDwell(String id) => _timers.containsKey(id);
}
