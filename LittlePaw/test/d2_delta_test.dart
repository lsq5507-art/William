import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/services/demo_unlock_gate.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/services/event_log.dart';
import 'package:little_paw/services/quota_ui.dart';

void main() {
  group('D2-01 dual quota copy', () {
    test('both hits use quota.both keys', () {
      expect(
        QuotaUi.kind(storiesHit: true, repliesHit: true),
        'both',
      );
      expect(QuotaUi.titleKey('both'), 'quota.both.title');
      expect(QuotaUi.bodyKey('both'), 'quota.both.body');
      final zh = S(true);
      expect(zh.get('quota.both.title').contains('动态'), true);
      expect(zh.get('quota.both.title').contains('回复'), true);
    });

    test('single hit stays stories or replies', () {
      expect(QuotaUi.kind(storiesHit: true, repliesHit: false), 'stories');
      expect(QuotaUi.kind(storiesHit: false, repliesHit: true), 'replies');
    });
  });

  group('D2-02 / S1 gating', () {
    test('strong secondary only at >=3 active days and entry enabled', () {
      expect(
        QuotaUi.showStrongSecondary(activeUtcDays: 2, intentEntryEnabled: true),
        false,
      );
      expect(
        QuotaUi.showStrongSecondary(activeUtcDays: 3, intentEntryEnabled: true),
        true,
      );
      expect(
        QuotaUi.showStrongSecondary(activeUtcDays: 5, intentEntryEnabled: false),
        false,
      );
      expect(
        QuotaUi.showSoftSecondary(activeUtcDays: 1, intentEntryEnabled: true),
        true,
      );
      expect(
        QuotaUi.showSoftSecondary(activeUtcDays: 1, intentEntryEnabled: false),
        false,
      );
    });

    test('activeAppOpenUtcDayCount counts distinct days', () {
      final clean = EventLog();
      clean.log('app_open', at: DateTime.utc(2026, 11, 1));
      clean.log('app_open', at: DateTime.utc(2026, 11, 1, 18));
      clean.log('app_open', at: DateTime.utc(2026, 11, 2));
      clean.log('comment_sent', at: DateTime.utc(2026, 11, 4));
      expect(clean.activeAppOpenUtcDayCount, 2);
    });
  });

  group('D2-05 empty export', () {
    test('empty log is not business events; header-only available', () {
      final log = EventLog();
      expect(log.hasBusinessEvents, false);
      expect(log.businessEventCount, 0);
      final header = log.exportHeaderOnly();
      expect(header.contains('no business events'), true);
      log.log('app_open', at: DateTime.utc(2026, 11, 3));
      expect(log.hasBusinessEvents, true);
      expect(log.exportText().contains('app_open'), true);
    });
  });

  group('D2-10 intentEntryEnabled', () {
    test('strings for paused entry exist', () {
      final zh = S(true);
      final en = S(false);
      expect(zh.get('intent.entry_paused_title').isNotEmpty, true);
      expect(en.get('intent.entry_paused_body').toLowerCase().contains('paused') ||
          en.get('intent.entry_paused_title').toLowerCase().contains('paused'), true);
    });
  });

  group('D2-04 / D2-11 unlock confirm copy (product tone)', () {
    test('confirm and unlock toast keys present without demo labels', () {
      final zh = S(true);
      final en = S(false);
      expect(zh.get('demo.confirm.title').contains('演示'), false);
      expect(zh.get('demo.unlock_toast').contains('演示'), false);
      expect(zh.get('demo.confirm.ok').isNotEmpty, true);
      expect(en.get('demo.confirm.title').toLowerCase().contains('demo'), false);
      expect(en.get('demo.unlock_toast').toLowerCase().contains('demo'), false);
    });
  });

  group('D2-03 S5 trust', () {
    test('trust keys present', () {
      expect(S(true).get('intent.trust_local').contains('本机'), true);
      expect(S(false).get('profile.export_trust').toLowerCase().contains('local'), true);
    });
  });

  group('D2-07 load corrupt flag', () {
    testWidgets('SpaceStore.load sets loadCorrupt on bad JSON', (tester) async {
      SharedPreferences.setMockInitialValues({
        'little_paw_space_v1': '{not-valid-json',
      });
      final store = SpaceStore();
      await store.load();
      expect(store.loadCorrupt, true);
      expect(store.hasPet, false);
      store.acknowledgeLoadCorrupt();
      expect(store.loadCorruptAcknowledged, true);
    });
  });

  group('D2-04 demo unlock requires confirmation gate', () {
    test('helper refuses unlock when not confirmed', () async {
      var called = false;
      await DemoUnlockGate.run(
        confirmed: false,
        unlock: () async {
          called = true;
        },
      );
      expect(called, false);
      await DemoUnlockGate.run(
        confirmed: true,
        unlock: () async {
          called = true;
        },
      );
      expect(called, true);
    });
  });
}
