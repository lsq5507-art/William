import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/event_log.dart';

void main() {
  test('logs required retention events with fields', () {
    final log = EventLog();
    log.appOpen();
    log.storyImpressionComplete('s1', source: 'onboarding');
    log.commentSent('s1', commentId: 'c1');
    log.commentReplyShown('s1', commentId: 'c1');
    log.quotaHit('stories');
    log.appOpen(afterQuota: true);
    log.paywallIntentShown(from: 'profile');
    log.payIntentChoice('yearly');
    log.simulatePurchase('monthly');

    final names = log.events.map((e) => e.event).toList();
    expect(names, contains('app_open'));
    expect(names, contains('story_impression_complete'));
    expect(names, contains('comment_sent'));
    expect(names, contains('comment_reply_shown'));
    expect(names, contains('quota_hit'));
    expect(names, contains('next_day_open_after_quota'));
    expect(names, contains('paywall_intent_shown'));
    expect(names, contains('pay_intent_choice'));
    expect(names, contains('simulate_purchase_monthly'));

    for (final e in log.events) {
      expect(e.utcDay.isNotEmpty, true);
      expect(e.ts.isUtc, true);
      expect(e.event.isNotEmpty, true);
    }

    final export = log.exportText();
    expect(export.contains('pay_intent_choice'), true);
    expect(export.contains('simulate_purchase_monthly'), true);
  });
}
