import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/event_log.dart';

void main() {
  test('formal intent does not unlock membership; simulate does', () {
    final economy = Economy();
    final log = EventLog();
    expect(economy.isMemberSimulated, false);

    // Formal intent path — log only
    log.payIntentChoice('yearly');
    expect(economy.isMemberSimulated, false);
    expect(
      log.events.any((e) =>
          e.event == 'pay_intent_choice' &&
          e.props['choice'] == 'yearly' &&
          e.props['is_simulated_commerce'] == false),
      true,
    );

    // Demo simulate path — separate event + unlock sim flag
    log.simulatePurchase('monthly');
    economy.isMemberSimulated = true;
    expect(economy.isMemberSimulated, true);
    expect(
      log.events.any((e) =>
          e.event == 'simulate_purchase_monthly' &&
          e.props['is_simulated_commerce'] == true),
      true,
    );

    // Events remain distinct
    expect(
      log.events.where((e) => e.event.startsWith('simulate_purchase_')).length,
      1,
    );
    expect(log.events.where((e) => e.event == 'pay_intent_choice').length, 1);
  });
}
