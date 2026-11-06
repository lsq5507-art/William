import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

class StoryRingItemData {
  final String id;
  final String label;
  final bool seen;
  final VoidCallback? onTap;

  const StoryRingItemData({
    required this.id,
    required this.label,
    this.seen = false,
    this.onTap,
  });
}

/// Horizontal story rings (LP-DS01 §7.3 / LP-D-09).
class StoryRingRow extends StatelessWidget {
  final List<StoryRingItemData> items;

  const StoryRingRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 76,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GradientRing(seen: item.seen),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LpTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientRing extends StatelessWidget {
  final bool seen;
  const _GradientRing({required this.seen});

  @override
  Widget build(BuildContext context) {
    final t = context.lpTokens;
    const outer = 64.0;
    const stroke = 2.0;
    return Container(
      width: outer,
      height: outer,
      padding: const EdgeInsets.all(stroke),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: seen
            ? null
            : SweepGradient(
                colors: [
                  t.ringUnreadStart,
                  t.ringUnreadEnd,
                  t.ringUnreadStart,
                ],
              ),
        color: seen ? t.ringRead : null,
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(
          backgroundColor: t.brandSoft,
          child: Icon(Icons.pets, color: LpTheme.brandPrimary, size: 28),
        ),
      ),
    );
  }
}
