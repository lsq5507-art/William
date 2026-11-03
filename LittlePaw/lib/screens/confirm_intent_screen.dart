import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';

/// SCR-11 lightweight confirm (M5). Default path: living feed.
class ConfirmIntentScreen extends StatefulWidget {
  final VoidCallback onContinueLiving;
  final VoidCallback onExit;
  const ConfirmIntentScreen({
    super.key,
    required this.onContinueLiving,
    required this.onExit,
  });

  @override
  State<ConfirmIntentScreen> createState() => _ConfirmIntentScreenState();
}

class _ConfirmIntentScreenState extends State<ConfirmIntentScreen> {
  int? choice;
  bool mismatch = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);

    if (mismatch) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.get('confirm.mismatch_title'),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(s.get('confirm.mismatch_body')),
                const Spacer(),
                OutlinedButton(
                  onPressed: widget.onExit,
                  child: Text(s.get('confirm.mismatch_exit')),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: widget.onContinueLiving,
                  child: Text(s.get('confirm.mismatch_continue')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.get('confirm.q'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _opt(1, s.get('confirm.a1')),
              _opt(2, s.get('confirm.a2')),
              _opt(3, s.get('confirm.a3_exclude')),
              const Spacer(),
              FilledButton(
                onPressed: choice == null
                    ? null
                    : () {
                        if (choice == 3) {
                          setState(() => mismatch = true);
                        } else {
                          widget.onContinueLiving();
                        }
                      },
                child: Text(s.get('confirm.continue')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opt(int v, String label) {
    final selected = choice == v;
    return ListTile(
      leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
          color: const Color(0xFFC45C26)),
      title: Text(label),
      selected: selected,
      onTap: () => setState(() => choice = v),
    );
  }
}
