import 'package:flutter/material.dart';

import '../theme/lp_theme.dart';

/// Interactive illustration story card (LP-D-04 §3.1).
/// Locally orchestrated frames — never claims cloud AI.
class InteractiveStoryCard extends StatefulWidget {
  final String petName;
  final bool zh;
  final String headerTitle;
  final String metaLabel;
  final String storyLineClosed;
  final String storyLineOpen;
  final String ctaClosed;
  final String ctaOpened;
  final String footnote;
  final VoidCallback? onSeeFeed;

  const InteractiveStoryCard({
    super.key,
    required this.petName,
    required this.zh,
    required this.headerTitle,
    required this.metaLabel,
    required this.storyLineClosed,
    required this.storyLineOpen,
    required this.ctaClosed,
    required this.ctaOpened,
    required this.footnote,
    this.onSeeFeed,
  });

  @override
  State<InteractiveStoryCard> createState() => _InteractiveStoryCardState();
}

class _InteractiveStoryCardState extends State<InteractiveStoryCard> {
  int page = 0; // 0 = closed box, 1 = opened
  static const int pageCount = 2;

  void _onCta() {
    if (page == 0) {
      setState(() => page = 1);
    } else {
      widget.onSeeFeed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = page == 1;
    final tokens = context.lpTokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 20, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.headerTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                '${page + 1} / $pageCount',
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: CustomPaint(
                  key: ValueKey(page),
                  painter: _BoxFriendPainter(opened: open),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.metaLabel,
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.petName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            open ? widget.storyLineOpen : widget.storyLineClosed,
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
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onCta,
              icon: Icon(open ? Icons.pets : Icons.inventory_2_outlined,
                  size: 20),
              label: Text(open ? widget.ctaOpened : widget.ctaClosed),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.footnote,
            style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Living-scene painter: dog + cardboard box (non-memorial).
class _BoxFriendPainter extends CustomPainter {
  final bool opened;
  const _BoxFriendPainter({required this.opened});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF7F0E8);
    canvas.drawRect(Offset.zero & size, bg);

    // window
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.12, size.width * 0.28,
          size.height * 0.38),
      const Radius.circular(8),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFFB8D4E8));
    canvas.drawRRect(
      window,
      Paint()
        ..color = LpTokens.light.textSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // sun
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.04,
      Paint()..color = const Color(0xFFFFC857),
    );

    // floor line
    canvas.drawLine(
      Offset(0, size.height * 0.78),
      Offset(size.width, size.height * 0.78),
      Paint()
        ..color = const Color(0xFFE0D4C8)
        ..strokeWidth = 2,
    );

    // box
    final boxLeft = size.width * 0.42;
    final boxTop = size.height * (opened ? 0.42 : 0.48);
    final boxW = size.width * 0.28;
    final boxH = size.height * 0.28;
    final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxW, boxH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFD4A574),
    );
    canvas.drawLine(
      Offset(boxLeft + boxW / 2, boxTop),
      Offset(boxLeft + boxW / 2, boxTop + boxH),
      Paint()
        ..color = const Color(0xFFB8895A)
        ..strokeWidth = 1.5,
    );
    if (opened) {
      // open flap
      final path = Path()
        ..moveTo(boxLeft, boxTop)
        ..lineTo(boxLeft - boxW * 0.15, boxTop - boxH * 0.35)
        ..lineTo(boxLeft + boxW * 0.55, boxTop - boxH * 0.25)
        ..lineTo(boxLeft + boxW / 2, boxTop)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8C49A));
      // peek friend (ball)
      canvas.drawCircle(
        Offset(boxLeft + boxW * 0.5, boxTop + boxH * 0.25),
        boxW * 0.18,
        Paint()..color = const Color(0xFFE85D4C),
      );
    }

    // dog body (sitting left)
    final dogX = size.width * 0.22;
    final dogY = size.height * 0.55;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(dogX, dogY + 18),
          width: size.width * 0.18,
          height: size.height * 0.22),
      Paint()..color = const Color(0xFFA67C52),
    );
    canvas.drawCircle(
      Offset(dogX, dogY - 8),
      size.width * 0.07,
      Paint()..color = const Color(0xFFB8895A),
    );
    // ear
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(dogX - size.width * 0.05, dogY - 14),
          width: size.width * 0.04,
          height: size.height * 0.08),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    // eye
    canvas.drawCircle(
      Offset(dogX + 6, dogY - 10),
      2.5,
      Paint()..color = const Color(0xFF1A1A1A),
    );
    // tail
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(dogX - size.width * 0.1, dogY + 10),
          width: size.width * 0.1,
          height: size.height * 0.12),
      -0.4,
      1.8,
      false,
      Paint()
        ..color = const Color(0xFFA67C52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BoxFriendPainter oldDelegate) =>
      oldDelegate.opened != opened;
}
