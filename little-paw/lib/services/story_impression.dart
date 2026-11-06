import 'dart:async';

/// Viewport impression rules for SCR-03 / M7 (O3) — defaults:
/// - ratio >= [immediateRatio] (0.8) → complete immediately
/// - ratio >= [dwellMinRatio] (legacy: any >0) → dwell >= [dwell] while in viewport
/// - below band / left viewport → cancel unfinished dwell timer
///
/// LP-DEV-19 D-19 feed complete: immediateRatio=1.1, dwellMinRatio=0.5, dwell=1s.
class StoryImpressionTracker {
  StoryImpressionTracker({
    this.dwell = const Duration(seconds: 2),
    this.immediateRatio = 0.8,
    this.dwellMinRatio = 0.0,
    this.onImpressed,
    this.now,
  });

  final Duration dwell;
  final double immediateRatio;
  /// 0 → any partial ratio > 0 starts dwell (legacy). Else require ratio >= this.
  final double dwellMinRatio;
  final void Function(String id)? onImpressed;
  /// Injectable clock for tests.
  final DateTime Function()? now;

  final Set<String> impressed = {};
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> dwellStarted = {};

  bool get isComplete => impressed.length >= 3;
  int get impressedCount => impressed.length;

  bool _inDwellBand(double ratio) {
    if (dwellMinRatio <= 0) return ratio > 0;
    return ratio >= dwellMinRatio;
  }

  /// Update visibility ratio for one story card (0.0–1.0+).
  void updateVisibility(String id, double ratio) {
    if (impressed.contains(id)) return;

    if (ratio >= immediateRatio) {
      _cancelTimer(id);
      _mark(id);
      return;
    }

    if (_inDwellBand(ratio)) {
      dwellStarted.putIfAbsent(id, () => (now ?? DateTime.now)());
      _timers.putIfAbsent(id, () {
        return Timer(dwell, () {
          if (!impressed.contains(id)) {
            _mark(id);
          }
        });
      });
      return;
    }

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
