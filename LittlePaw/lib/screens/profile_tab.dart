import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/economy.dart';
import '../services/space_store.dart';
import 'intent_sheet.dart';

/// SCR-10 Profile: demo store badge, export, formal intent entry (M1/M6).
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final e = store.economy;

    return Scaffold(
      appBar: AppBar(title: Text(s.get('profile.tab'))),
      body: ListView(
        children: [
          ListTile(
            title: Text(store.pet?.name ?? '—'),
            subtitle: Text(
              store.localeZh
                  ? '额度 动态 ${e.storiesLeft}/${e.storiesLimit} · 回复 ${e.repliesLeft}/${e.repliesLimit}'
                  : 'Quota stories ${e.storiesLeft}/${e.storiesLimit} · replies ${e.repliesLeft}/${e.repliesLimit}',
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(s.get('profile.lang')),
            trailing: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(s.get('profile.lang_zh'))),
                ButtonSegment(value: false, label: Text(s.get('profile.lang_en'))),
              ],
              selected: {store.localeZh},
              onSelectionChanged: (v) => store.setLocaleZh(v.first),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.get('profile.section_research'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(s.get('profile.intent_entry')),
            onTap: () => showFormalIntentSheet(context, from: 'profile'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(s.get('profile.export_trial')),
            onTap: () async {
              final text = store.eventLog.exportText();
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.get('profile.export_copied'))),
                );
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(s.get('profile.export_trial')),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(child: SelectableText(text)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.get('intent.thanks.close')),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(s.get('profile.section_demo'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                _demoBadge(s.get('profile.demo_badge')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Row(
              children: [
                Text(s.get('profile.demo_store')),
                const SizedBox(width: 8),
                _demoBadge(s.get('profile.demo_badge')),
              ],
            ),
            subtitle: Text(
              e.isMemberSimulated
                  ? s.get('profile.member_sim')
                  : s.get('profile.member_off'),
            ),
            onTap: () => _openDemoStore(context, store, s),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(s.get('profile.reset')),
            onTap: () async {
              await store.resetSpace();
              if (context.mounted) {
                // Router in app.dart listens to store and returns to welcome.
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Prices (hypotheses): '
              'M ${Economy.priceMonthly} / Y ${Economy.priceYearly} / '
              'Card ${Economy.priceCard} / Book ${Economy.priceBook}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE082),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      );

  Future<void> _openDemoStore(
      BuildContext context, SpaceStore store, S s) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Row(
                children: [
                  Text(s.get('profile.demo_store')),
                  const SizedBox(width: 8),
                  _demoBadge(s.get('profile.demo_badge')),
                ],
              ),
              subtitle: Text(s.get('profile.section_demo')),
            ),
            ListTile(
              title: Text(s.get('profile.demo_unlock')),
              onTap: () async {
                await store.simulatePurchase('monthly');
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        store.localeZh
                            ? '演示：已模拟开通（不计付费验证）'
                            : 'Demo: simulated unlock (not payment validation)',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
