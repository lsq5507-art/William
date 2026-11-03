import 'dart:convert';

import '../models/app_event.dart';

/// M1 local retention event ledger. Isolated from simulated commerce success.
class EventLog {
  final List<AppEvent> _events = [];

  List<AppEvent> get events => List.unmodifiable(_events);

  static String utcDayOf(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-'
        '${u.month.toString().padLeft(2, '0')}-'
        '${u.day.toString().padLeft(2, '0')}';
  }

  void log(String event, {Map<String, dynamic>? props, DateTime? at}) {
    final ts = at ?? DateTime.now().toUtc();
    _events.add(AppEvent(
      ts: ts,
      utcDay: utcDayOf(ts),
      event: event,
      props: props ?? const {},
    ));
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
