import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:little_paw/ops/ops_allowlist.dart';
import 'package:little_paw/ops/ops_constants.dart';
import 'package:little_paw/ops/ops_funnel_defs.dart';
import 'package:little_paw/ops/ops_gate.dart';
import 'package:little_paw/ops/ops_path.dart';
import 'package:little_paw/ops/ops_repository.dart';
import 'package:little_paw/ops/pages/ops_deny_page.dart';
import 'package:little_paw/ops/pages/ops_funnel_page.dart';
import 'package:little_paw/ops/pages/ops_shell.dart';
import 'package:little_paw/ops/pages/ops_users_page.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/first_daily_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpsAllowlist', () {
    test('default includes lsq5507@gmail.com (case-insensitive)', () {
      expect(OpsAllowlist.isAllowlisted('lsq5507@gmail.com'), isTrue);
      expect(OpsAllowlist.isAllowlisted('LSQ5507@Gmail.com'), isTrue);
    });

    test('rejects null / empty / non-members', () {
      expect(OpsAllowlist.isAllowlisted(null), isFalse);
      expect(OpsAllowlist.isAllowlisted(''), isFalse);
      expect(OpsAllowlist.isAllowlisted('stranger@example.com'), isFalse);
    });

    test('merges compile-time with optional Firestore extras', () {
      expect(
        OpsAllowlist.isAllowlisted(
          'extra@example.com',
          firestoreEmails: const ['extra@example.com'],
        ),
        isTrue,
      );
      expect(
        OpsAllowlist.isAllowlisted(
          'extra@example.com',
          firestoreEmails: const [],
        ),
        isFalse,
      );
    });
  });

  group('OpsPath', () {
    test('detects /ops and /ops/* only', () {
      expect(OpsPath.isOpsPath('/ops'), isTrue);
      expect(OpsPath.isOpsPath('/ops/'), isTrue);
      expect(OpsPath.isOpsPath('/ops/users'), isTrue);
      expect(OpsPath.isOpsPath('/ops/funnel'), isTrue);
      expect(OpsPath.isOpsPath('/'), isFalse);
      expect(OpsPath.isOpsPath('/home'), isFalse);
      expect(OpsPath.isOpsPath('/opportunity'), isFalse);
    });
  });

  group('Ops funnel defs', () {
    test('locks F0–F7b including formal/sim split', () {
      final ids = OpsFunnelDefs.steps.map((s) => s.id).toList();
      expect(ids, containsAll(['F0', 'F1', 'F2a', 'F2b', 'F3', 'F4', 'F5', 'F6', 'F7a', 'F7b']));
      final f7a = OpsFunnelDefs.steps.firstWhere((s) => s.id == 'F7a');
      final f7b = OpsFunnelDefs.steps.firstWhere((s) => s.id == 'F7b');
      expect(f7a.rail, OpsFunnelRail.formal);
      expect(f7b.rail, OpsFunnelRail.simulated);
      expect(f7a.eventName, contains('pay_intent_choice'));
      expect(f7b.eventName, contains('simulate_purchase'));
    });

    test('BQ export flag is blocked while Billing=No / unlinked', () {
      expect(OpsConstants.bqExportEnabled, isFalse);
    });
  });

  group('Build chip + user-side stamp isolation', () {
    test('ops chip is ops-admin-funnel-web-v0.21', () {
      expect(OpsConstants.buildChip, 'ops-admin-funnel-web-v0.21');
    });

    test('user-side FirstDailyGate stamp stays web-shell-center-v0.22', () {
      expect(FirstDailyGate.stampHotfix, 'web-shell-center-v0.22');
      expect(
        FirstDailyGate.buildStampForHost('little-paw-prod.web.app'),
        'web-shell-center-v0.22',
      );
    });
  });

  group('OpsDenyPage zero leak', () {
    testWidgets('shows deny copy only — no table/card/skeleton columns', (
      tester,
    ) async {
      final auth = FakeAuthService(
        initial: const AuthUserInfo(
          uid: 'x',
          email: 'stranger@example.com',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: auth,
          child: const MaterialApp(home: OpsDenyPage()),
        ),
      );
      expect(find.textContaining('无权访问'), findsOneWidget);
      expect(find.textContaining('白名单'), findsWidgets);
      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(DataTableTheme), findsNothing);
      expect(find.byKey(const Key('ops.overview.cards')), findsNothing);
      expect(find.byKey(const Key('ops.users.table')), findsNothing);
      expect(find.byKey(const Key('ops.funnel.table')), findsNothing);
      expect(find.byKey(const Key('ops.skeleton.table')), findsNothing);
      // No numeric summary peek / nav data surfaces
      expect(find.textContaining('Auth 用户'), findsNothing);
      expect(find.text('概览'), findsNothing);
      expect(find.byKey(const Key('ops.funnel.table')), findsNothing);
    });
  });

  group('OpsFunnelPage Blocked', () {
    testWidgets('BQ-off shows amber Blocked and em-dash n, no fake %', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OpsFunnelPage()),
        ),
      );
      expect(find.textContaining('Blocked'), findsWidgets);
      expect(find.textContaining('待开通'), findsWidgets);
      expect(find.textContaining('BigQuery'), findsWidgets);
      expect(find.text('%'), findsNothing);
      expect(find.textContaining('转化率'), findsNothing);
      // Step defs visible with —
      expect(find.text('F0'), findsWidgets);
      expect(find.text('F7a'), findsWidgets);
      expect(find.text('F7b'), findsWidgets);
      expect(find.byKey(const Key('ops.funnel.table')), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });
  });

  group('OpsUsersPage footnote', () {
    testWidgets('shows Auth ≠ Guest footnote', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OpsUsersPage(rows: [], loading: false),
          ),
        ),
      );
      expect(
        find.textContaining('Auth 用户 ≠ 全部'),
        findsWidgets,
      );
    });
  });

  group('OpsShell build chip', () {
    testWidgets('chip text fixed', (tester) async {
      final auth = FakeAuthService(
        initial: const AuthUserInfo(
          uid: 'w',
          email: 'lsq5507@gmail.com',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: auth,
          child: const MaterialApp(
            home: OpsShell(initialTab: OpsTab.overview, overview: SizedBox()),
          ),
        ),
      );
      expect(find.text('ops-admin-funnel-web-v0.21'), findsOneWidget);
    });
  });

  group('OpsGate routing', () {
    testWidgets('signed-out → login (no Guest CTA)', (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: auth,
          child: const MaterialApp(
            home: OpsGate(skipRemoteAllowlist: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('使用 Google 登录'), findsOneWidget);
      expect(find.textContaining('Guest'), findsWidgets); // "Guest 不可进入"
      expect(find.text('以访客继续'), findsNothing);
      expect(find.byKey(const Key('ops.guest.cta')), findsNothing);
    });

    testWidgets('non-allowlisted → deny page', (tester) async {
      final auth = FakeAuthService(
        initial: const AuthUserInfo(
          uid: 'n',
          email: 'nope@example.com',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: auth,
          child: const MaterialApp(home: OpsGate(skipRemoteAllowlist: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('无权访问'), findsOneWidget);
      expect(find.byKey(const Key('ops.overview.cards')), findsNothing);
    });

    testWidgets('allowlisted → shell with overview cards', (tester) async {
      final auth = FakeAuthService(
        initial: const AuthUserInfo(
          uid: 'w',
          email: 'lsq5507@gmail.com',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: auth,
          child: const MaterialApp(
            home: OpsGate(
              skipRemoteAllowlist: true,
              repository: OpsRepositoryStub.empty(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('概览'), findsWidgets);
      expect(find.byKey(const Key('ops.overview.cards')), findsOneWidget);
      // Footnote may mention 已收款 as forbidden metric; no success/revenue card.
      expect(find.text('正式付费成功'), findsNothing);
      expect(find.textContaining('营收'), findsNothing);
    });
  });
}
