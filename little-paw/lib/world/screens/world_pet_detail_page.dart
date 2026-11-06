// World Tab · pet profile · v0.5
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../services/space_store.dart';
import '../../theme/lp_theme.dart';
import '../models/world_models.dart';
import '../world_store.dart';

class WorldPetDetailPage extends StatelessWidget {
  const WorldPetDetailPage({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    final zh = context.watch<SpaceStore>().localeZh;
    final s = S(zh);
    final store = context.watch<WorldStore>();
    final pet = store.petById(petId);
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.get('world.detail.missing'))),
        body: Center(child: Text(s.get('world.detail.missing'))),
      );
    }
    final following = store.isFollowing(pet.id);
    final petPosts = store.posts.where((p) => p.petId == pet.id).toList();
    MarketAcquireStatus? marketStatus;
    for (final m in store.market) {
      if (m.petId == pet.id) {
        marketStatus = m.status;
        break;
      }
    }

    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF262626),
        elevation: 0,
        title: Text(
          pet.name(zh),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: tokens.borderHairline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.borderHairline, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(pet.avatarAsset),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name(zh),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed(zh),
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(pet.personality(zh)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: following
                        ? const Color(0xFFECEAE6)
                        : const Color(0xFF1A1A1A),
                    foregroundColor: following
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => store.toggleFollow(pet.id),
                  child: Text(
                    following
                        ? s.get('world.follow.following')
                        : s.get('world.follow.cta'),
                  ),
                ),
              ),
              if (marketStatus != null) ...[
                const SizedBox(width: 8),
                _StatusChip(status: marketStatus, zh: zh, s: s),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            s.get('world.pet.posts'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: petPosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (_, i) => Image.asset(
              petPosts[i].imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.zh, required this.s});
  final MarketAcquireStatus status;
  final bool zh;
  final S s;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      MarketAcquireStatus.locked => s.get('world.status.locked'),
      MarketAcquireStatus.trial => s.get('world.status.trial'),
      MarketAcquireStatus.owned => s.get('world.status.owned'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
