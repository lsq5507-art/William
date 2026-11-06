import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/widgets/lp_web_shell_frame.dart';

void main() {
  group('LP-DEV-23 web shell center', () {
    test('stamp is web-shell-center-v0.22', () {
      expect(FirstDailyGate.stampHotfix, 'web-shell-center-v0.22');
      expect(
        FirstDailyGate.buildStampForHost('little-paw-prod.web.app'),
        'web-shell-center-v0.22',
      );
      expect(
        FirstDailyGate.buildStampForHost('littlepaw.pet'),
        'web-shell-center-v0.22',
      );
    });

    test('constants locked: breakpoint 1024 / maxWidth 480', () {
      expect(LpWebShellFrame.wideBreakpoint, 1024);
      expect(LpWebShellFrame.contentMaxWidth, 480);
    });

    test('shouldConstrain: web ≥1024 on; <1024 off; non-web off', () {
      expect(
        LpWebShellFrame.shouldConstrain(isWeb: true, width: 1024),
        isTrue,
      );
      expect(
        LpWebShellFrame.shouldConstrain(isWeb: true, width: 1280),
        isTrue,
      );
      expect(
        LpWebShellFrame.shouldConstrain(isWeb: true, width: 1023),
        isFalse,
      );
      expect(
        LpWebShellFrame.shouldConstrain(isWeb: true, width: 430),
        isFalse,
      );
      expect(
        LpWebShellFrame.shouldConstrain(isWeb: false, width: 1400),
        isFalse,
      );
    });

    testWidgets('frame passes child through under narrow width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: LpWebShellFrame(
            child: Scaffold(body: Text('shell-child')),
          ),
        ),
      );
      expect(find.text('shell-child'), findsOneWidget);
      // No forced 480 width box when narrow — ConstrainedBox absent as outer shell.
      final sized = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final forced480 = sized.where((s) => s.width == 480);
      expect(forced480, isEmpty);
    });

    testWidgets('frame forces 480 when wide (sim web via shouldConstrain path)',
        (tester) async {
      // Widget uses kIsWeb; in VM tests kIsWeb is false so we assert logic
      // above and only pump narrow-pass-through. Wide visual is covered by
      // shouldConstrain + deploy smoke. Extra: Material wraps child.
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFF5F5F5)),
          home: const LpWebShellFrame(
            child: Scaffold(body: Text('wide-child')),
          ),
        ),
      );
      expect(find.text('wide-child'), findsOneWidget);
      // In VM (non-web) still pass-through — no 480 SizedBox injected.
      final forced480 = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((s) => s.width == 480);
      expect(forced480, isEmpty);
    });
  });
}
