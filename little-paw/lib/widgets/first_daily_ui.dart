import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// SCR-19-COACH soft coach sheet.
class FirstDailyCoachSheet extends StatelessWidget {
  const FirstDailyCoachSheet({
    super.key,
    required this.zh,
    required this.onPrimary,
    required this.onSecondary,
    this.emptyMode = false,
  });

  final bool zh;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool emptyMode;

  @override
  Widget build(BuildContext context) {
    final s = S(zh);
    final title = emptyMode
        ? s.get('first_daily.coach.empty_title')
        : s.get('first_daily.coach.title');
    final sub = emptyMode
        ? s.get('first_daily.coach.empty_sub')
        : s.get('first_daily.coach.sub');
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const Key('first_daily.coach.primary'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onPrimary,
                      child: Text(
                        emptyMode
                            ? s.get('first_daily.empty.cta_chat')
                            : s.get('first_daily.coach.cta_primary'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('first_daily.coach.secondary'),
                    onPressed: onSecondary,
                    child: Text(
                      s.get('first_daily.coach.cta_secondary'),
                      style: const TextStyle(color: Color(0xFF6B6B6B)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.get('first_daily.coach.foot'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SCR-19-DAILY-CARD pinned「它的一条日常」.
class PinnedDailyCard extends StatelessWidget {
  const PinnedDailyCard({
    super.key,
    required this.zh,
    required this.caption,
    required this.petName,
    required this.onOpenStory,
    this.imageUrl,
  });

  final bool zh;
  final String caption;
  final String petName;
  final String? imageUrl;
  final VoidCallback onOpenStory;

  @override
  Widget build(BuildContext context) {
    final s = S(zh);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const Key('first_daily.pinned'),
          borderRadius: BorderRadius.circular(20),
          onTap: onOpenStory,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E1DC)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E0D4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.get('first_daily.pin.badge'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC45C26),
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Text(
                    petName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenStory,
                    child: Text(s.get('first_daily.pin.story_link')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFECEAE6),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, size: 48, color: Color(0xFFC45C26)),
      );
}

Future<void> showFirstDailyCoachSheet(
  BuildContext context, {
  required bool zh,
  required bool emptyMode,
  required Future<void> Function() onPrimary,
  required Future<void> Function() onSecondary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FirstDailyCoachSheet(
          zh: zh,
          emptyMode: emptyMode,
          onPrimary: () async {
            Navigator.of(ctx).pop();
            await onPrimary();
          },
          onSecondary: () async {
            Navigator.of(ctx).pop();
            await onSecondary();
          },
        ),
      );
    },
  ).whenComplete(() {});
}
