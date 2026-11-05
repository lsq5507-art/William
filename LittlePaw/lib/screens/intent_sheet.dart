import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/intent_choice.dart';
import '../services/space_store.dart';

/// SCR-08 / SCR-09 formal interest panel (M6). Does NOT unlock membership.
Future<void> showFormalIntentSheet(BuildContext context, {String from = 'ui'}) {
  final store = context.read<SpaceStore>();
  if (!store.intentEntryEnabled) {
    final s = S(store.localeZh);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.get('intent.entry_paused_title'))),
    );
    return Future.value();
  }
  store.eventLog.paywallIntentShown(from: from);
  store.save();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _IntentSheet(),
  );
}

class _IntentSheet extends StatefulWidget {
  const _IntentSheet();

  @override
  State<_IntentSheet> createState() => _IntentSheetState();
}

class _IntentSheetState extends State<_IntentSheet> {
  IntentChoice? selected;
  bool thanks = false;
  bool submitting = false;
  final noteCtrl = TextEditingController();

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final memberBefore = store.economy.isMemberSimulated;

    if (thanks) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.get('intent.thanks.title'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(s.get('intent.thanks.body')),
            const SizedBox(height: 8),
            Text(
              store.localeZh
                  ? '会员状态未变（当前=${memberBefore ? "已开通" : "未开通"}）'
                  : 'Membership unchanged (now=${memberBefore ? "on" : "off"})',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.get('intent.thanks.close')),
            ),
          ],
        ),
      );
    }

    Widget opt(IntentChoice c, String key, {String? subtitleKey}) {
      final isSel = selected == c;
      return ListTile(
        leading: Icon(isSel ? Icons.check_circle : Icons.circle_outlined,
            color: const Color(0xFFC45C26)),
        title: Text(s.get(key)),
        subtitle: subtitleKey == null ? null : Text(s.get(subtitleKey)),
        selected: isSel,
        onTap: () => setState(() => selected = c),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.get('intent.title'),
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(store.localeZh ? '意向' : 'INTEREST',
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.get('intent.disclaimer'),
                  style: const TextStyle(fontSize: 13)),
            ),
            // D2-03 S5 trust line
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(s.get('intent.trust_local'),
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            opt(IntentChoice.monthly, 'intent.opt.monthly'),
            opt(IntentChoice.yearly, 'intent.opt.yearly',
                subtitleKey: 'intent.opt.yearly_approx'),
            opt(IntentChoice.card, 'intent.opt.card'),
            opt(IntentChoice.book, 'intent.opt.book'),
            opt(IntentChoice.none, 'intent.opt.none'),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: s.get('intent.note_optional'),
                border: const OutlineInputBorder(),
              ),
            ),
            // D2-08: network.soft_fail reserved for future share/outbound hooks.
            // Main paths stay local; do not block Feed/intent/export offline.
            const SizedBox(height: 12),
            FilledButton(
              onPressed: selected == null || submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      final before = store.economy.isMemberSimulated;
                      await store.recordIntent(
                        selected!.eventValue,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                      assert(store.economy.isMemberSimulated == before);
                      setState(() {
                        submitting = false;
                        thanks = true;
                      });
                    },
              child: Text(s.get('intent.submit')),
            ),
          ],
        ),
      ),
    );
  }
}
