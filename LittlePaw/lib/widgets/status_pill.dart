import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

/// Soft status capsule + quota hint (LP-D-04 §3.3).
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
