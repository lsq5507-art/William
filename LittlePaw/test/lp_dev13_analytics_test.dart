import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/event_log.dart';

class _FakeSink implements AnalyticsSink {
  final List<(String, Map<String, Object>?)> calls = [];
  bool throwOnLog = false;

  @override
  void logEvent(String name, {Map<String, Object>? parameters}) {
    if (throwOnLog) throw StateError('analytics down');
    calls.add((name, parameters));
  }
}

void main() {
  test('EventLog still writes local ledger when dual-writing', () {
    final sink = _FakeSink();
    final log = EventLog(analyticsSink: sink);
    log.log('app_open');
    expect(log.events.map((e) => e.event), contains('app_open'));
    expect(sink.calls.any((c) => c.$1 == 'app_open'), true);
  });

  test('Analytics sink is invoked with sanitized props', () {
    final sink = _FakeSink();
    final log = EventLog(analyticsSink: sink);
    log.log('tab_view', props: {'tab': 'feed', 'n': 1, 'ok': true, 'skip': null});
    expect(sink.calls.length, 1);
    expect(sink.calls.first.$1, 'tab_view');
    final p = sink.calls.first.$2!;
    expect(p['tab'], 'feed');
    expect(p['n'], 1);
    expect(p['ok'], true);
    expect(p.containsKey('skip'), false);
  });

  test('Analytics throw does not block local log', () {
    final sink = _FakeSink()..throwOnLog = true;
    final log = EventLog(analyticsSink: sink);
    expect(() => log.log('chat_open'), returnsNormally);
    expect(log.events.single.event, 'chat_open');
  });

  test('analyticsEnabled=false skips sink but keeps local', () {
    final sink = _FakeSink();
    final log = EventLog(analyticsSink: sink, analyticsEnabled: false);
    log.log('feed_view');
    expect(log.events.single.event, 'feed_view');
    expect(sink.calls, isEmpty);
  });

  test('pay_intent vs simulate stay on separate rails for sink', () {
    final sink = _FakeSink();
    final log = EventLog(analyticsSink: sink);
    log.payIntentChoice('yearly');
    log.simulatePurchase('monthly');
    final intent = sink.calls.firstWhere((c) => c.$1 == 'pay_intent_choice');
    final sim = sink.calls.firstWhere((c) => c.$1 == 'simulate_purchase_monthly');
    expect(intent.$2!['is_simulated_commerce'], false);
    expect(sim.$2!['is_simulated_commerce'], true);
    expect(sim.$2!['sku'], 'monthly');
  });

  test('new event names can be logged via helpers/log', () {
    final sink = _FakeSink();
    final log = EventLog(analyticsSink: sink);
    log.log('tab_view', props: {'tab': 'world'});
    log.log('story_open', props: {'ringId': 'opening'});
    log.log('story_dismiss', props: {'ringId': 'opening'});
    log.log('feed_view');
    log.log('chat_open');
    log.log('profile_view');
    log.log('my_moments_open', props: {'entry': 'profile'});
    log.log('auth_guest', props: {'platform': 'web'});
    log.log('auth_sign_in_result', props: {'success': true});
    final names = log.events.map((e) => e.event).toSet();
    for (final n in [
      'tab_view',
      'story_open',
      'story_dismiss',
      'feed_view',
      'chat_open',
      'profile_view',
      'my_moments_open',
      'auth_guest',
      'auth_sign_in_result',
    ]) {
      expect(names, contains(n));
      expect(sink.calls.any((c) => c.$1 == n), true);
    }
  });
}
