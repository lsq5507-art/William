import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/quota_ui.dart';
import 'package:little_paw/services/seo_web_gate.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/widgets/coin_reward_snack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L22 tokens / stamp', () {
    test('ringUnreadEnd is brandPrimary same-hue orange', () {
      final t = LpTokens.light;
      expect(t.ringUnreadStart, const Color(0xFFE07A3A));
      expect(t.ringUnreadEnd, const Color(0xFFC45C26));
      expect(t.ringUnreadEnd, LpTheme.brandPrimary);
    });

    test('display/headline theme weight ≤ w600', () {
      final tt = LpTheme.lightTextTheme;
      expect(
        tt.displaySmall!.fontWeight!.value,
        lessThanOrEqualTo(FontWeight.w600.value),
      );
      expect(
        tt.headlineMedium!.fontWeight!.value,
        lessThanOrEqualTo(FontWeight.w600.value),
      );
      expect(
        tt.headlineSmall!.fontWeight!.value,
        lessThanOrEqualTo(FontWeight.w600.value),
      );
    });

    test('build stamp is web-shell-center-v0.22', () {
      expect(FirstDailyGate.stampHotfix, 'web-shell-center-v0.22');
      expect(
        FirstDailyGate.buildStampForHost('little-paw-prod.web.app'),
        'web-shell-center-v0.22',
      );
      SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
      expect(SeoWebGate.buildStamp, 'web-shell-center-v0.22');
      SeoWebGate.hostnameOverride = null;
    });
  });

  group('L22 copy constraints', () {
    test('interactive line_open has no exclamation', () {
      expect(const S(false).get('feed.interactive.line_open').contains('!'),
          isFalse);
      expect(const S(true).get('feed.interactive.line_open').contains('!'),
          isFalse);
    });
  });

  group('L22-F1–F3 regression', () {
    test('F1 snack duration ≤3s and dismissible hit ≥44', () {
      expect(
        CoinRewardSnack.defaultAutoDismiss <= CoinRewardSnack.maxAutoDismiss,
        isTrue,
      );
      expect(
        CoinRewardSnack.maxAutoDismiss.inMilliseconds,
        lessThanOrEqualTo(3000),
      );
      expect(CoinRewardSnack.closeHitMin, greaterThanOrEqualTo(44));
    });

    test('F2 mayShowPostQuotaWall only when exhausted after post', () {
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 0,
          afterSuccessfulPost: true,
          pickerOrConfirmInFlight: false,
        ),
        isTrue,
      );
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 1,
          afterSuccessfulPost: true,
          pickerOrConfirmInFlight: false,
        ),
        isFalse,
      );
      expect(
        QuotaUi.mayShowPostQuotaWall(
          storiesLeft: 0,
          afterSuccessfulPost: false,
          pickerOrConfirmInFlight: true,
        ),
        isFalse,
      );
    });

    test('F3 single ledger coinBalance source', () {
      final e = Economy(utcDay: '2026-11-05');
      e.credit(100, 'test');
      expect(e.coinBalance, 100);
    });
  });
}
