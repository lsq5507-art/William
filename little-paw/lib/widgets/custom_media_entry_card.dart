import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

/// SCR-CM-01 — Feed custom day entry (replaces open-box CTA). LP-D-08.
class CustomMediaEntryCard extends StatelessWidget {
  final String petName;
  final String headerTitle;
  final String metaLabel;
  final String lead;
  final String ctaLabel;
  final String footnote;
  final String a11yCard;
  final String a11yCta;
  final VoidCallback onAddToCircle;

  const CustomMediaEntryCard({
    super.key,
    required this.petName,
    required this.headerTitle,
    required this.metaLabel,
    required this.lead,
    required this.ctaLabel,
    required this.footnote,
    required this.a11yCard,
    required this.a11yCta,
    required this.onAddToCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: a11yCard,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.lpTokens.radiusLg),
          border: Border.all(color: context.lpTokens.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined,
                    size: 20, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const AspectRatio(
                aspectRatio: 16 / 10,
                child: CustomPaint(
                  painter: _DayTogetherPainter(),
                  child: SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              metaLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 4),
            Text(
              petName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lead,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: Semantics(
                button: true,
                label: a11yCta,
                child: FilledButton.icon(
                  style: lpPrimaryCtaStyle(radius: 12),
                  onPressed: onAddToCircle,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text(ctaLabel),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              footnote,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B6B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Living day-together sketch (owner + pet) — non-memorial, no box narrative.
class _DayTogetherPainter extends CustomPainter {
  const _DayTogetherPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF3F7F2));

    // soft sun
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.2),
      size.width * 0.05,
      Paint()..color = const Color(0xFFFFD27A),
    );

    // ground
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.78),
      Paint()
        ..color = const Color(0xFFD5E0D2)
        ..strokeWidth = 2,
    );

    // person (simple)
    final px = size.width * 0.38;
    final py = size.height * 0.52;
    canvas.drawCircle(
      Offset(px, py - 18),
      12,
      Paint()..color = const Color(0xFF5B6B7A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px, py + 18), width: 28, height: 40),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF6E8CA0),
    );

    // pet
    final dx = size.width * 0.58;
    final dy = size.height * 0.62;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(dx, dy + 6), width: 36, height: 28),
      Paint()..color = const Color(0xFFA67C52),
    );
    canvas.drawCircle(
      Offset(dx + 10, dy - 8),
      11,
      Paint()..color = const Color(0xFFB8895A),
    );
    canvas.drawCircle(
      Offset(dx + 14, dy - 10),
      2.2,
      Paint()..color = const Color(0xFF1A1A1A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
