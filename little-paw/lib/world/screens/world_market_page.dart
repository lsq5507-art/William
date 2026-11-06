// World Tab · character market (secondary) · v0.5
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../services/space_store.dart';
import '../../theme/lp_theme.dart';
import '../models/world_models.dart';
import '../world_store.dart';
import 'world_pet_detail_page.dart';

class WorldMarketPage extends StatelessWidget {
  const WorldMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = context.watch<SpaceStore>().localeZh;
    final s = S(zh);
    final store = context.watch<WorldStore>();
    final tokens = context.lpTokens;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: store.market.length + 1,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: tokens.borderHairline),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              s.get('world.market.blurb'),
              style: TextStyle(color: tokens.textSecondary, fontSize: 13),
            ),
          );
        }
        final item = store.market[i - 1];
        return _MarketTile(item: item, zh: zh, s: s);
      },
    );
  }
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({required this.item, required this.zh, required this.s});
  final WorldMarketItem item;
  final bool zh;
  final S s;

  @override
  Widget build(BuildContext context) {
    final tokens = context.lpTokens;
    final store = context.read<WorldStore>();
    final statusLabel = switch (item.status) {
      MarketAcquireStatus.locked => s.get('world.status.locked'),
      MarketAcquireStatus.trial => s.get('world.status.trial'),
      MarketAcquireStatus.owned => s.get('world.status.owned'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item.imageAsset,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title(zh),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tagline(zh),
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(statusLabel, style: const TextStyle(fontSize: 12)),
                    ),
                    if (item.status == MarketAcquireStatus.locked) ...[
                      TextButton(
                        onPressed: () => store.startTrial(item.id),
                        child: Text(s.get('world.cta.trial')),
                      ),
                      if (item.demoPaid)
                        TextButton(
                          onPressed: () => _confirmAcquire(context, store, item, s),
                          child: Text(s.get('world.cta.demo_acquire')),
                        ),
                    ],
                    if (item.status == MarketAcquireStatus.trial && item.demoPaid)
                      TextButton(
                        onPressed: () => _confirmAcquire(context, store, item, s),
                        child: Text(s.get('world.cta.demo_acquire')),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorldPetDetailPage(petId: item.petId),
                          ),
                        );
                      },
                      child: Text(s.get('world.cta.profile')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAcquire(
    BuildContext context,
    WorldStore store,
    WorldMarketItem item,
    S s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.get('world.demo.title')),
        content: Text(s.get('world.demo.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.get('world.demo.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.get('world.demo.ok')),
          ),
        ],
      ),
    );
    if (ok == true) store.demoAcquire(item.id);
  }
}
