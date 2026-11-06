// World Tab · pet social feed + character market · v0.5
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/custom_media_flow.dart';
import '../services/space_store.dart';
import '../world/screens/world_market_page.dart';
import '../world/screens/world_pet_detail_page.dart';
import '../world/screens/world_post_detail_page.dart';
import '../world/widgets/world_ig_post_card.dart';
import '../theme/lp_theme.dart';
import '../world/world_store.dart';

class WorldTab extends StatefulWidget {
  const WorldTab({super.key});

  @override
  State<WorldTab> createState() => _WorldTabState();
}

class _WorldTabState extends State<WorldTab>
    with AutomaticKeepAliveClientMixin {
  int _segment = 0; // 0 feed, 1 market

  @override
  bool get wantKeepAlive => true;

  String _relTime(DateTime at, bool zh) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 60) {
      return zh ? '${d.inMinutes} 分钟前' : '${d.inMinutes}m';
    }
    if (d.inHours < 24) {
      return zh ? '${d.inHours} 小时前' : '${d.inHours}h';
    }
    return zh ? '${d.inDays} 天前' : '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final zh = context.watch<SpaceStore>().localeZh;
    final s = S(zh);
    final world = context.watch<WorldStore>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          s.get('world.tab'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Color(0xFF262626),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: s.get('world.publish.a11y'),
            onPressed: () {
              final store = context.read<SpaceStore>();
              if (store.customMediaToFeedEnabled) {
                CustomMediaFlow.start(context);
                return;
              }
              // Flag off: honest divert — never "coming soon" fake promise.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.get('world.publish.divert_body'))),
              );
            },
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFF262626)),
          ),
          IconButton(
            tooltip: s.get('world.top.messages'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.get('world.top.messages_toast'))),
              );
            },
            icon: const Icon(Icons.near_me_outlined, color: Color(0xFF262626)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _SegChip(
                      label: s.get('world.seg.feed'),
                      selected: _segment == 0,
                      onTap: () => setState(() => _segment = 0),
                    ),
                    const SizedBox(width: 8),
                    _SegChip(
                      label: s.get('world.seg.market'),
                      selected: _segment == 1,
                      onTap: () => setState(() => _segment = 1),
                    ),
                  ],
                ),
              ),
              Divider(height: 0.5, thickness: 0.5, color: context.lpTokens.borderHairline),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _segment,
        children: [
          ListView.builder(
            itemCount: world.posts.length,
            itemBuilder: (context, i) {
              final post = world.posts[i];
              final pet = world.petById(post.petId);
              if (pet == null) return const SizedBox.shrink();
              return WorldIgPostCard(
                post: post,
                pet: pet,
                zh: zh,
                timeLabel: _relTime(post.postedAt, zh),
                onLike: () => world.toggleLike(post.id),
                onOpenComments: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorldPostDetailPage(postId: post.id),
                    ),
                  );
                },
                onOpenPet: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorldPetDetailPage(petId: pet.id),
                    ),
                  );
                },
                onOpenDetail: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorldPostDetailPage(postId: post.id),
                    ),
                  );
                },
              );
            },
          ),
          const WorldMarketPage(),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF262626) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF262626),
          ),
        ),
      ),
    );
  }
}
