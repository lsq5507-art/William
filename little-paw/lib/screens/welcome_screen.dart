import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import '../widgets/centered_onboarding_card.dart';

/// SCR-18-WELCOME — Layout A centered card + R-03 value copy (D-18).
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: Stack(
          children: [
            CenteredOnboardingCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.get('welcome.title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LpTheme.brandPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.get('welcome.subtitle'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  _bullet(context, s.get('welcome.v1')),
                  _bullet(context, s.get('welcome.v2')),
                  _bullet(context, s.get('welcome.v3')),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: lpPrimaryCtaStyle(),
                      onPressed: () async {
                        await store.markWelcomeSeen();
                        onStart();
                      },
                      child: Text(s.get('welcome.cta')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.get('welcome.trust'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 8,
              child: TextButton(
                onPressed: () => store.setLocaleZh(!store.localeZh),
                child: Text(store.localeZh ? 'EN' : '中文'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final tokens = context.lpTokens;
    final parts = text.split(' — ');
    final title = parts.first;
    final sub = parts.length > 1 ? parts.sublist(1).join(' — ') : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pets, size: 18, color: LpTheme.brandPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (sub != null && sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(color: tokens.textSecondary, height: 1.35),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
