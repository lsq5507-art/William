// World Tab · IG-style post card · v0.5
import 'package:flutter/material.dart';

import '../models/world_models.dart';
import '../../theme/lp_theme.dart';

class WorldIgPostCard extends StatelessWidget {
  const WorldIgPostCard({
    super.key,
    required this.post,
    required this.pet,
    required this.zh,
    required this.timeLabel,
    required this.onLike,
    required this.onOpenComments,
    required this.onOpenPet,
    required this.onOpenDetail,
  });

  final WorldPost post;
  final WorldPet pet;
  final bool zh;
  final String timeLabel;
  final VoidCallback onLike;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenPet;
  final VoidCallback onOpenDetail;

  static const _text = Color(0xFF262626);
  static const _like = Color(0xFFED4956);

  @override
  Widget build(BuildContext context) {
    final tokens = context.lpTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onOpenPet,
                child: _GradientAvatar(asset: pet.avatarAsset, size: 36),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onOpenPet,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name(zh),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _text,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.more_horiz, color: _text),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onOpenDetail,
          onDoubleTap: onLike,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              post.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF0F0F0),
                alignment: Alignment.center,
                child: Icon(Icons.pets, size: 48, color: tokens.textSecondary),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  post.liked ? Icons.favorite : Icons.favorite_border,
                  color: post.liked ? _like : _text,
                ),
              ),
              IconButton(
                onPressed: onOpenComments,
                icon: const Icon(Icons.chat_bubble_outline, color: _text),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send_outlined, color: _text),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.mood(zh),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: Text(
            zh ? '${post.likeCount} 次赞' : '${post.likeCount} likes',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _text,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: _text, height: 1.35),
              children: [
                TextSpan(
                  text: '${pet.name(zh)} ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: post.body(zh)),
              ],
            ),
          ),
        ),
        if (post.comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: GestureDetector(
              onTap: onOpenComments,
              child: Text(
                zh
                    ? '查看全部 ${post.comments.length} 条评论'
                    : 'View all ${post.comments.length} comments',
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
            ),
          )
        else
          const SizedBox(height: 8),
        Divider(height: 1, thickness: 0.5, color: tokens.borderHairline),
      ],
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.asset, required this.size});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
        ),
      ),
      child: CircleAvatar(
        backgroundImage: AssetImage(asset),
        backgroundColor: Colors.white,
      ),
    );
  }
}
