import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';

/// SCR-06 Activity reply discoverability (M3) + jump to Feed story (DEF-03).
class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final items = store.comments;

    return Scaffold(
      appBar: AppBar(title: Text(s.get('activity.tab'))),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.get('activity.empty'), textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final c = items[i];
                return ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 10,
                    color: c.replyUnread
                        ? const Color(0xFFC45C26)
                        : Colors.transparent,
                  ),
                  title: Text(s.get('activity.reply_arrived')),
                  subtitle: Text(c.reply(store.localeZh)),
                  onTap: () async {
                    await store.markReplyShown(c);
                    store.requestFocusStory(c.storyId);
                  },
                );
              },
            ),
    );
  }
}
