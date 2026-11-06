import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

/// Soft status capsule + quota hint (LP-D-04 §3.3 / LP-D-22 token align).
class StatusPill extends StatelessWidget {
  final String message;
  final String? hint;

  const StatusPill({
    super.key,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.lpTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: tokens.textSecondary,
              ),
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
