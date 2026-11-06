import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

/// Layout A · D-18 CenteredOnboardingCard — PC max ~420–480, CTA follows card.
class CenteredOnboardingCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredOnboardingCard({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.lpTokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gutter = 16.0;
        final maxW = maxWidth.clamp(320.0, 480.0);
        return ColoredBox(
          color: tokens.bgPage,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: gutter,
                vertical: constraints.maxHeight < 600 ? 16 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Material(
                  key: const Key('onboarding.centered_card'),
                  color: LpTheme.bgElevated,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                    side: BorderSide(color: tokens.borderHairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
