import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';

/// World tab — minimal placeholder (no Must this round).
class WorldTab extends StatelessWidget {
  const WorldTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    return Scaffold(
      appBar: AppBar(title: Text(s.get('world.tab'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.get('world.placeholder'), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
