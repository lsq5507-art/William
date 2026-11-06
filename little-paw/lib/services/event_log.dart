import 'dart:convert';

import '../models/app_event.dart';

/// Kill switch for Analytics dual-write (local ledger always writes).
const bool kAnalyticsDualWriteEnabled = true;

/// Injectable Analytics dual-write target (tests use fake; prod uses Firebase).
abstract class AnalyticsSink {
  void logEvent(String name, {Map<String, Object>? parameters});
}

/// M1 local retention event ledger. Isolated from simulated commerce success.
class EventLog {
  EventLog({
    this.analyticsSink,
    this.analyticsEnabled = true,
  });

  /// When false, local ledger still writes; Analytics is skipped.
  bool analyticsEnabled;

  /// Optional dual-write sink. Failures must never break callers.
  AnalyticsSink? analyticsSink;

  final List<AppEvent> _events = [];

  List<AppEvent> get events => List.unmodifiable(_events);

  /// Business events = any logged event rows (header-only export is empty).
  bool get hasBusinessEvents => _events.isNotEmpty;
  int get businessEventCount => _events.length;

  /// Distinct UTC days that logged app_open (S1 active-day gate).
  int get activeAppOpenUtcDayCount {
    final days = <String>{};
    for (final e in _events) {
      if (e.event == 'app_open') days.add(e.utcDay);
    }
    return days.length;
  }

  String exportHeaderOnly() {
    final buf = StringBuffer();
    buf.writeln('# Little Paw trial event export');
    buf.writeln('# fields: utc_day\\tevent\\tprops\\tts');
    buf.writeln('# (no business events yet)');
    return buf.toString();
  }

  static String utcDayOf(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-'
        '${u.month.toString().padLeft(2, '0')}-'
        '${u.day.toString().padLeft(2, '0')}';
  }

  /// Convert props to Analytics-acceptable String/num/bool only.
  static Map<String, Object> analyticsParams(Map<String, dynamic>? props) {
    if (props == null || props.isEmpty) return const {};
    final out = <String, Object>{};
    props.forEach((k, v) {
      if (v == null) return;
      if (v is String || v is num || v is bool) {
        out[k] = v;
      } else {
        out[k] = v.toString();
      }
    });
    return out;
  }

  void log(String event, {Map<String, dynamic>? props, DateTime? at}) {
    final ts = at ?? DateTime.now().toUtc();
    final map = props ?? const <String, dynamic>{};
    _events.add(AppEvent(
      ts: ts,
      utcDay: utcDayOf(ts),
      event: event,
      props: map,
    ));
    _dualWrite(event, map);
  }

  void _dualWrite(String event, Map<String, dynamic> props) {
    if (!analyticsEnabled) return;
    final sink = analyticsSink;
    if (sink == null) return;
    try {
      final params = analyticsParams(props);
      sink.logEvent(
        event,
        parameters: params.isEmpty ? null : params,
      );
    } catch (_) {
      // Analytics must never block UI / local ledger.
    }
  }

  void seoLandingView() {
    log('seo_landing_view');
  }

  void seoCtaClick({String cta = 'enter_app'}) {
    log('seo_cta_click', props: {'cta': cta});
  }

  void appOpen({bool afterQuota = false}) {

    log('app_open');
    if (afterQuota) log('next_day_open_after_quota');
  }

  void storyImpressionComplete(String storyId, {String? source}) {
    log('story_impression_complete', props: {
      'storyId': storyId,
      'source': ?source,
    });
  }

  void commentSent(String storyId, {String? commentId}) {
    log('comment_sent', props: {
      'storyId': storyId,
      'commentId': ?commentId,
    });
  }

  void commentReplyShown(String storyId, {String? commentId}) {
    log('comment_reply_shown', props: {
      'storyId': storyId,
      'commentId': ?commentId,
    });
  }

  void quotaHit(String type) {
    log('quota_hit', props: {'type': type});
  }

  void paywallIntentShown({String? from}) {
    log('paywall_intent_shown', props: {
      'from': ?from,
    });
  }

  void payIntentChoice(String choice, {String? note}) {
    // Formal interest only — must NEVER unlock membership.
    log('pay_intent_choice', props: {
      'choice': choice,
      'is_simulated_commerce': false,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  void simulatePurchase(String sku) {
    // Demo path — separate field/event from pay_intent_choice.
    log('simulate_purchase_$sku', props: {
      'sku': sku,
      'is_simulated_commerce': true,
    });
  }

  String exportText() {
    final buf = StringBuffer();
    buf.writeln('# Little Paw trial event export');
    buf.writeln('# fields: utc_day\\tevent\\tprops\\tts');
    for (final e in _events) {
      buf.writeln(e.toExportLine());
    }
    return buf.toString();
  }

  List<Map<String, dynamic>> toJsonList() =>
      _events.map((e) => e.toJson()).toList();

  void loadFromJsonList(List<dynamic> list) {
    _events
      ..clear()
      ..addAll(list.map((e) => AppEvent.fromJson(Map<String, dynamic>.from(e as Map))));
  }

  String toJsonString() => jsonEncode(toJsonList());
}
