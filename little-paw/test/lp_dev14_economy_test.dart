import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/event_log.dart';

void main() {
  group('M9 params readable', () {
    test('§6.4 defaults exposed as constants', () {
      expect(Economy.coinsPerCny, 10000);
      expect(Economy.priceSubMonthlyCny, 6.0);
      expect(Economy.priceSubYearlyCny, 48.0);
      expect(Economy.coinCheckinDaily, 500);
      expect(Economy.coinCheckinStreak7, 2000);
      expect(Economy.coinTaskChat, 200);
      expect(Economy.coinInviteInviter, 2000);
      expect(Economy.coinInviteInvitee, 1000);
      expect(Economy.coinFeedbackAdopted, 1000);
      expect(Economy.coinCostChat, 20);
      expect(Economy.coinCostCustomCharacter, 5000);
      expect(Economy.coinCostImageGen, 2000);
      expect(Economy.coinSubGrantMonthly, 30000);
      expect(Economy.coinMemberDailyGrant, greaterThan(0));
    });
  });

  group('M1 wallet credit/debit + persist', () {
    test('credit and debit update balance and ledger', () {
      final e = Economy(utcDay: '2026-11-04');
      expect(e.coinBalance, 0);
      e.credit(500, 'checkin');
      expect(e.coinBalance, 500);
      expect(e.ledger.length, 1);
      expect(e.ledger.first.type, 'credit');
      expect(e.ledger.first.reason, 'checkin');
      expect(e.debit(20, 'chat'), true);
      expect(e.coinBalance, 480);
      expect(e.ledger.last.type, 'debit');
      expect(e.ledger.last.reason, 'chat');
      expect(e.debit(9999, 'chat'), false);
      expect(e.coinBalance, 480);
    });

    test('toJson/fromJson keeps wallet', () {
      final e = Economy(utcDay: '2026-11-04');
      e.credit(1000, 'sub_grant');
      e.debit(20, 'chat');
      final copy = Economy.fromJson(e.toJson());
      expect(copy.coinBalance, 980);
      expect(copy.ledger.length, 2);
      expect(copy.ledger.first.reason, 'sub_grant');
    });
  });

  group('M3 chat coin gate', () {
    test('insufficient blocks; enough debits', () {
      final e = Economy(utcDay: '2026-11-04');
      expect(e.canAffordChat, false);
      expect(e.tryDebitChat(), false);
      e.credit(20, 'checkin');
      expect(e.canAffordChat, true);
      expect(e.tryDebitChat(), true);
      expect(e.coinBalance, 0);
      expect(e.ledger.last.reason, 'chat');
    });

    test('story consume does not debit coins', () {
      final e = Economy(utcDay: '2026-11-04');
      e.credit(100, 'checkin');
      expect(e.consumeStory(), true);
      expect(e.coinBalance, 100);
    });
  });

  group('M4 checkin', () {
    test('same UTC day no double claim; streak7 bonus; break resets', () {
      final e = Economy(utcDay: '2026-11-01');
      expect(e.claimCheckin(day: '2026-11-01'), 500);
      expect(e.claimCheckin(day: '2026-11-01'), null);
      expect(e.checkinStreak, 1);

      expect(e.claimCheckin(day: '2026-11-02'), 500);
      expect(e.checkinStreak, 2);
      expect(e.claimCheckin(day: '2026-11-03'), 500);
      expect(e.claimCheckin(day: '2026-11-04'), 500);
      expect(e.claimCheckin(day: '2026-11-05'), 500);
      expect(e.claimCheckin(day: '2026-11-06'), 500);
      expect(e.claimCheckin(day: '2026-11-07'), 2000);
      expect(e.checkinStreak, 7);

      // break
      expect(e.claimCheckin(day: '2026-11-09'), 500);
      expect(e.checkinStreak, 1);
    });
  });

  group('M5 task chat claim', () {
    test('claim once after chat progress same day', () {
      final e = Economy(utcDay: '2026-11-04');
      expect(e.claimTaskChat(day: '2026-11-04'), null);
      e.markTaskChatProgress(day: '2026-11-04');
      expect(e.claimTaskChat(day: '2026-11-04'), 200);
      expect(e.claimTaskChat(day: '2026-11-04'), null);
      expect(e.coinBalance, 200);
    });
  });

  group('M6 invite simulate', () {
    test('inviter/invitee grant once per device roles', () {
      final e = Economy(utcDay: '2026-11-04');
      final code = e.ensureInviteCode();
      expect(code.isNotEmpty, true);
      expect(e.redeemInviteAsInviter(), 2000);
      expect(e.redeemInviteAsInviter(), null);
      expect(e.redeemInviteAsInvitee(code), null); // own code blocked
      expect(e.redeemInviteAsInvitee('FRIEND01'), 1000);
      expect(e.redeemInviteAsInvitee('FRIEND02'), null);
      expect(e.coinBalance, 3000);
    });
  });

  group('M7 feedback adopt idempotent', () {
    test('adopt credits once', () {
      final e = Economy(utcDay: '2026-11-04');
      final id = e.submitFeedback(type: 'suggestion', body: '希望更好的签到');
      expect(id, isNotEmpty);
      expect(e.adoptFeedback(id), 1000);
      expect(e.adoptFeedback(id), null);
      expect(e.coinBalance, 1000);
    });
  });

  group('M2/M8 simulate vs pay_intent', () {
    test('simulate unlocks; pay_intent does not; skus distinct', () {
      final economy = Economy();
      final log = EventLog();
      log.payIntentChoice('yearly');
      expect(economy.isMemberSimulated, false);
      expect(
        log.events.any((e) =>
            e.event == 'pay_intent_choice' &&
            e.props['is_simulated_commerce'] == false),
        true,
      );

      log.simulatePurchase('sub_monthly');
      economy.applySimulatedSub('sub_monthly');
      expect(economy.isMemberSimulated, true);
      expect(
        log.events.any((e) =>
            e.event == 'simulate_purchase_sub_monthly' &&
            e.props['is_simulated_commerce'] == true),
        true,
      );
      expect(log.events.where((e) => e.event == 'pay_intent_choice').length, 1);
    });
  });

  group('member daily grant + raised quota', () {
    test('member gets daily grant once and higher story/reply caps', () {
      final e = Economy(isMemberSimulated: true, utcDay: '2026-11-04');
      expect(e.storiesLimit, greaterThan(Economy.freeStoriesPerUtcDay));
      expect(e.repliesLimit, greaterThan(Economy.freeRepliesPerUtcDay));
      final g = e.ensureMemberDailyGrant(day: '2026-11-04');
      expect(g, Economy.coinMemberDailyGrant);
      expect(e.ensureMemberDailyGrant(day: '2026-11-04'), null);
    });
  });
}
