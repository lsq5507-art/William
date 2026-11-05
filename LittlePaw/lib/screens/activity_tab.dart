import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import 'chat_screen.dart';
import 'role_gen_pages.dart';

/// SCR-06 Activity — chat primary path (LP-P-07 / LP-D-07); replies as light section.
class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);

    if (!store.activityChatPrimaryEnabled) {
      return _legacyReplies(context, store, s);
    }
    return _chatPrimary(context, store, s);
  }

  Widget _chatPrimary(BuildContext context, SpaceStore store, S s) {
    final auth = context.watch<AuthService>();
    final name = store.pet?.name ?? 'Little Paw';
    final hasPet = store.hasPet;
    final preview = store.chatPreview(store.localeZh);
    final replies = store.comments;

    return Scaffold(
      backgroundColor: context.lpTokens.bgPage,
      appBar: AppBar(title: Text(s.get('activity.tab'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (auth.currentUser == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                s.get('activity.guest_hint'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A6A4A)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              s.get('activity.chat.list_title'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          if (!hasPet)
            _chatEmpty(context, store, s, canStart: false)
          else if (store.chatMessages.isEmpty)
            _chatEmpty(context, store, s, canStart: true)
          else
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE8D6),
                child: Icon(Icons.pets, color: Color(0xFFC45C26)),
              ),
              title: Text(name),
              subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: store.chatMessages.any((m) =>
                      m.sender.name == 'pet' &&
                      store.chatMessages.last.id == m.id)
                  ? null
                  : null,
              onTap: () => _openChat(context, store),
            ),
          ListTile(
            key: const Key('activity.role_pick'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.switch_account_outlined),
            title: Text(store.localeZh ? '选伴' : 'Pick companion'),
            subtitle: Text(
              store.localeZh ? '本机自定义角色' : 'On-device custom characters',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RolePickPage()),
              );
            },
          ),
          if (replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                s.get('activity.light_section'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            for (final c in replies.take(8))
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.circle,
                  size: 8,
                  color: c.replyUnread
                      ? const Color(0xFFC45C26)
                      : const Color(0xFFDDDDDD),
                ),
                title: Text(
                  s.get('activity.reply_arrived'),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
                ),
                subtitle: Text(
                  c.reply(store.localeZh),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  s.get('activity.reply_go_feed'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC45C26)),
                ),
                onTap: () async {
                  await store.markReplyShown(c);
                  store.requestFocusStory(c.storyId);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _chatEmpty(
    BuildContext context,
    SpaceStore store,
    S s, {
    required bool canStart,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Text(
            s.get('activity.chat.empty_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            s.get('activity.chat.empty_body'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          if (canStart)
            FilledButton(
              onPressed: () => _openChat(context, store),
              child: Text(s.get('activity.chat.empty_cta')),
            ),
          TextButton(
            onPressed: () {
              // Switch to Feed tab via HomeShell index is owned by parent;
              // focus a noop / user taps bottom nav. Soft path: snackbar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.get('activity.chat.empty_secondary'))),
              );
            },
            child: Text(s.get('activity.chat.empty_secondary')),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, SpaceStore store) async {
    await store.ensureChatSeeded();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
    );
  }

  Widget _legacyReplies(BuildContext context, SpaceStore store, S s) {
    final items = store.comments;
    return Scaffold(
      backgroundColor: context.lpTokens.bgPage,
      appBar: AppBar(title: Text(s.get('activity.tab'))),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.get('activity.chat.empty_body'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
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
