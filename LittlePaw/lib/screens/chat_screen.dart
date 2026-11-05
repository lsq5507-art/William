import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/quota_ui.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import 'economy_pages.dart';
import 'intent_sheet.dart';

/// SCR-06-CHAT conversation (local script replies).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;
  bool showQuota = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = context.read<SpaceStore>();
      store.eventLog.log('chat_open', props: {'from': 'activity'});
      await store.ensureChatSeeded();
      _jumpBottom();
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _jumpBottom() {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    if (sending) return;
    final text = ctrl.text;
    if (text.trim().isEmpty) return;
    final store = context.read<SpaceStore>();
    store.economy.ensureUtcDay();
    store.economy.ensureMemberDailyGrant();
    if (!store.economy.canAffordChat) {
      await showCoinInsufficientSheet(context);
      return;
    }
    if (store.economy.repliesHit) {
      setState(() => showQuota = true);
      await store.notifyQuotaHitIfNeeded('replies');
      return;
    }
    setState(() => sending = true);
    final draft = text;
    final result = await store.sendChatMessage(draft);
    if (!mounted) return;
    if (result == null && store.lastChatBlockedByCoins) {
      setState(() => sending = false);
      await showCoinInsufficientSheet(context);
      return;
    }
    if (result == null && store.economy.repliesHit) {
      setState(() {
        sending = false;
        showQuota = true;
      });
      return;
    }
    ctrl.clear();
    setState(() => sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
  }

  Future<void> _retry(ChatMessage m) async {
    setState(() => sending = true);
    await context.read<SpaceStore>().retryChatMessage(m.id);
    if (!mounted) return;
    setState(() => sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpBottom());
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final name = store.pet?.name ?? 'Little Paw';
    final msgs = store.chatMessages;
    final auth = context.watch<AuthService>();
    final guest = auth.currentUser == null;

    return Scaffold(
      backgroundColor: context.lpTokens.bgPage,
      appBar: AppBar(
        title: Text(name),
      ),
      body: Column(
        children: [
          if (guest)
            Material(
              color: context.lpTokens.brandSoft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.get('activity.guest_hint'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A6A4A)),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: msgs.length,
              itemBuilder: (ctx, i) => _bubble(s, store.localeZh, msgs[i]),
            ),
          ),
          if (showQuota || store.economy.repliesHit)
            _quotaBanner(store, s)
          else
            _composer(s),
        ],
      ),
    );
  }

  Widget _bubble(S s, bool zh, ChatMessage m) {
    final mine = m.sender == ChatSender.user;
    final sys = m.sender == ChatSender.system;
    if (sys) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            m.text(zh),
            style: TextStyle(fontSize: 12, color: context.lpTokens.textSecondary),
          ),
        ),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine
                    ? context.lpTokens.chatBubbleMe
                    : context.lpTokens.chatBubbleThem,
                borderRadius: BorderRadius.circular(context.lpTokens.radiusMd),
              ),
              child: Text(
                m.text(zh),
                style: TextStyle(
                  color: mine ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
            if (m.failed)
              TextButton(
                onPressed: sending ? null : () => _retry(m),
                child: Text(
                  s.get('activity.chat.send_failed'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFC45C26)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quotaBanner(SpaceStore store, S s) {
    final defer = store.quotaPresentation == QuotaPresentation.defer;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.get(defer ? 'quota.defer.title' : 'activity.chat.quota.title'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                s.get(defer ? 'quota.defer.body' : 'activity.chat.quota.body'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: lpSecondaryCtaStyle(),
                onPressed: () => setState(() => showQuota = false),
                child: Text(s.get(defer
                    ? 'quota.defer.cta_primary'
                    : 'activity.chat.quota.cta_primary')),
              ),
              TextButton(
                style: lpSecondaryCtaStyle(outlined: false),
                onPressed: () => showFormalIntentSheet(
                  context,
                  from: defer ? 'chat_quota_defer' : 'chat_quota',
                ),
                child: Text(s.get(defer
                    ? 'quota.defer.link'
                    : 'activity.chat.quota.cta_secondary')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(S s) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: s.get('activity.chat.input_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              width: 44,
              child: Material(
                color: context.lpTokens.ctaInverse,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: sending ? null : _send,
                  color: context.lpTokens.onCtaInverse,
                  style: IconButton.styleFrom(
                    backgroundColor: context.lpTokens.ctaInverse,
                    foregroundColor: context.lpTokens.onCtaInverse,
                    disabledBackgroundColor: const Color(0xFFBBBBBB),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  tooltip: s.get('activity.chat.send'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
