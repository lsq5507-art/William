import 'package:flutter/material.dart';

import '../models/story.dart';
import '../theme/lp_theme.dart';
import 'post_media.dart';

/// Card-style post (LP-D-04 container; D-03 layers retained).
class PostCard extends StatefulWidget {
  final Story story;
  final String petName;
  final bool zh;
  final bool liked;
  final bool highlighted;
  final String newLabel;
  final String moreLabel;
  final String lessLabel;
  final String likeLabel;
  final String commentLabel;
  final List<String> commentPreviews;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final String? locationLabel;

  const PostCard({
    super.key,
    required this.story,
    required this.petName,
    required this.zh,
    required this.liked,
    required this.highlighted,
    required this.newLabel,
    required this.moreLabel,
    required this.lessLabel,
    required this.likeLabel,
    required this.commentLabel,
    required this.commentPreviews,
    required this.onToggleLike,
    required this.onComment,
    this.locationLabel,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool expanded = false;
  bool showHeart = false;
  late final AnimationController _heart;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    if (!widget.liked) widget.onToggleLike();
    setState(() => showHeart = true);
    _heart.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => showHeart = false);
    });
  }

  String _relativeTime(DateTime at, bool zh) {
    final diff = DateTime.now().toUtc().difference(at.toUtc());
    if (diff.inMinutes < 2) return zh ? '刚刚' : 'Just now';
    if (diff.inHours < 1) {
      return zh ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return zh ? '${diff.inHours}小时前' : '${diff.inHours}h';
    }
    if (diff.inDays == 1) return zh ? '昨天' : 'Yesterday';
    return zh ? '${diff.inDays}天前' : '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.locationLabel ??
        widget.story.locationLabel ??
        'Cloud Town';

    final tokens = context.lpTokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(
          color: widget.highlighted
              ? LpTheme.brandPrimary
              : tokens.borderHairline,
          width: widget.highlighted ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(loc),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PostMedia(
              story: widget.story,
              onDoubleTap: _doubleTapLike,
              overlay: showHeart
                  ? Center(
                      child: ScaleTransition(
                        scale: Tween(begin: 0.6, end: 1.2).animate(
                          CurvedAnimation(
                              parent: _heart, curve: Curves.easeOut),
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 72),
                      ),
                    )
                  : null,
            ),
          ),
          _actions(),
          _caption(),
          if (widget.commentPreviews.isNotEmpty) _commentPreview(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _header(String location) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2E7D4F),
              child: Icon(Icons.pets, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.petName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.story.isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC45C26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.newLabel,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B6B6B)),
                  ),
                ],
              ),
            ),
            Text(
              _relativeTime(widget.story.createdAt, widget.zh),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(Icons.more_horiz, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: widget.likeLabel,
              onPressed: widget.onToggleLike,
              icon: Icon(
                widget.liked ? Icons.favorite : Icons.favorite_border,
                color: widget.liked
                    ? const Color(0xFFD11F4F)
                    : const Color(0xFF1A1A1A),
                size: 24,
              ),
            ),
            IconButton(
              tooltip: widget.commentLabel,
              onPressed: widget.onComment,
              icon: const Icon(Icons.chat_bubble_outline,
                  size: 24, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caption() {
    final text = widget.story.body(widget.zh);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${widget.petName} ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                  ),
                ),
              ],
            ),
            maxLines: expanded ? null : 2,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (_needsExpand(text))
            GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  expanded ? widget.lessLabel : widget.moreLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _needsExpand(String text) => text.runes.length > 48;

  Widget _commentPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: InkWell(
        onTap: widget.onComment,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in widget.commentPreviews.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Multi-block skeleton matching D-04 feed (not a single spinner).
class FeedSkeletonList extends StatelessWidget {
  final String a11yLabel;
  const FeedSkeletonList({super.key, required this.a11yLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: a11yLabel,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          _SkeletonStoryCard(),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Bar(w: 64, h: 22),
                SizedBox(width: 12),
                _Bar(w: 72, h: 24),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Circle(),
                SizedBox(width: 12),
                _Circle(),
                SizedBox(width: 12),
                _Circle(),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _Bar(w: double.infinity, h: 40),
          ),
          SizedBox(height: 14),
          _SkeletonPostCard(),
          _SkeletonPostCard(),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double w;
  final double h;
  const _Bar({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w.isFinite ? w : double.infinity,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E5E0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle();
  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(radius: 28, backgroundColor: Color(0xFFE8E5E0));
  }
}

class _SkeletonStoryCard extends StatelessWidget {
  const _SkeletonStoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Bar(w: 180, h: 14),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _Bar(w: 100, h: 10),
          const SizedBox(height: 8),
          const _Bar(w: 80, h: 16),
          const SizedBox(height: 8),
          const _Bar(w: double.infinity, h: 10),
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPostCard extends StatelessWidget {
  const _SkeletonPostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  CircleAvatar(
                      radius: 16, backgroundColor: Color(0xFFE8E5E0)),
                  SizedBox(width: 10),
                  _Bar(w: 120, h: 12),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(color: Color(0xFFE8E8E8)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(w: double.infinity, h: 10),
                SizedBox(height: 8),
                _Bar(w: 180, h: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
