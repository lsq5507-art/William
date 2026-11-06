import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// LP-DEV-23: Web wide-viewport centered phone shell (maxWidth 480).
///
/// Only [kIsWeb] and logical width ≥ [wideBreakpoint]. Narrow / non-web:
/// child unchanged (no fake phone gutters).
class LpWebShellFrame extends StatelessWidget {
  const LpWebShellFrame({super.key, required this.child});

  final Widget child;

  /// Wide-viewport gate (logical px). Written hard per LP-P-23.
  static const double wideBreakpoint = 1024;

  /// Content + bottom nav max width (logical px). Written hard per LP-P-23.
  static const double contentMaxWidth = 480;

  /// Pure logic for tests / callers: enable centered shell?
  static bool shouldConstrain({
    required bool isWeb,
    required double width,
  }) =>
      isWeb && width >= wideBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!shouldConstrain(isWeb: kIsWeb, width: width)) {
      return child;
    }
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: SizedBox(
            width: contentMaxWidth,
            child: child,
          ),
        ),
      ),
    );
  }
}
