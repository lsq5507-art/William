import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/space_store.dart';
import 'comment_guide.dart';
import 'intent_sheet.dart';

/// SCR-04 Feed revisit + SCR-07 quota bar (M2 / M4).
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  bool showQuotaBanner = false;
  String quotaType = 'stories';
  final impressedTimers = <String, Timer>{};
  final scrollController = ScrollController();
  final itemKeys = <String, GlobalKey>{};
  String? highlightId;

  @override
  void dispose() {
    for (final t in impressedTimers.values) {
      t.cancel();
    }
    scrollController.dispose();
    super.dispose();
  }

  List<Story> _feedStories(SpaceStore store) =>
      store.stories.where((s) => !s.isOnboarding).toList();

  Future<void> _impress(SpaceStore store, Story st) async {
    if (store.impressedStoryIds.contains(st.id)) return;
    if (store.economy.storiesHit && st.isUnread) {
      setState(() {
        showQuotaBanner = true;
        quotaType = 'stories';
      });
      await store.notifyQuotaHitIfNeeded('stories');
      return;
    }
    await store.markStoryImpressed(st.id, source: 'feed');
    if (store.economy.storiesHit) {
      setState(() {
        showQuotaBanner = true;
        quotaType = 'stories';
      });
    }
  }

  void _scheduleImpress(SpaceStore store, Story st) {
    impressedTimers[st.id]?.cancel();
    impressedTimers[st.id] = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _impress(store, st);
    });
    // Feed: listed cards still impress for demo (onboarding uses strict tracker).
    _impress(store, st);
  }

  void _handleFocus(SpaceStore store, List<Story> stories) {
    final id = store.focusStoryId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => highlightId = id);
      final ctx = itemKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
      store.clearFocusStory();
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted && highlightId == id) {
          setState(() => highlightId = null);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final stories = _feedStories(store);
    for (final st in stories) {
      itemKeys.putIfAbsent(st.id, () => GlobalKey());
    }
    _handleFocus(store, stories);

    final unread = store.unreadStoryCount;
    final showGuide = !store.commentGuideDone &&
        !store.commentGuideSkipped &&
        stories.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.pet?.name ?? 'Little Paw'),
        actions: [
          if (showGuide)
            TextButton(
              onPressed: () => _openCommentGuide(context, store, stories.first),
              child: Text(s.get('comment.guide.title')),
            ),
        ],
      ),
      body: Column(
        children: [
          if (unread > 0)
            Material(
              color: const Color(0xFFFFE8D6),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 10, color: Color(0xFFC45C26)),
                title: Text(
                  unread == 1
                      ? s.get('feed.header.unread')
                      : s.fmt('feed.header.unread_n', {'n': '$unread'}),
                ),
              ),
            ),
          if (showQuotaBanner) _quotaBar(context, store, s),
          Expanded(
            child: stories.isEmpty
                ? _empty(s, store)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: stories.length,
                    itemBuilder: (ctx, i) {
                      final st = stories[i];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!store.impressedStoryIds.contains(st.id)) {
                          _scheduleImpress(store, st);
                        }
                      });
                      return _FeedCard(
                        key: itemKeys[st.id],
                        story: st,
                        zh: store.localeZh,
                        newLabel: s.get('new_badge'),
                        highlighted: highlightId == st.id,
                        onReply: () => _openCommentGuide(context, store, st),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(S s, SpaceStore store) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 48, color: Color(0xFFC45C26)),
            const SizedBox(height: 12),
            Text(s.get('feed.empty.no_new'), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '${s.get('feed.empty.quota_left_hint')}: '
              'stories ${store.economy.storiesLeft}/${store.economy.storiesLimit}, '
              'replies ${store.economy.repliesLeft}/${store.economy.repliesLimit}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quotaBar(BuildContext context, SpaceStore store, S s) {
    final isStories = quotaType == 'stories';
    return Material(
      elevation: 2,
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.get(isStories ? 'quota.stories.title' : 'quota.replies.title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(s.get(isStories ? 'quota.stories.body' : 'quota.replies.body'),
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => showQuotaBanner = false),
                    child: Text(s.get('quota.cta_primary')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showFormalIntentSheet(context),
                    child: Text(s.get('quota.cta_secondary')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCommentGuide(
      BuildContext context, SpaceStore store, Story story) async {
    final hit = await showCommentGuide(context, story);
    if (!mounted) return;
    if (hit == 'replies_hit') {
      setState(() {
        showQuotaBanner = true;
        quotaType = 'replies';
      });
    }
  }
}

class _FeedCard extends StatelessWidget {
  final Story story;
  final bool zh;
  final String newLabel;
  final bool highlighted;
  final VoidCallback onReply;
  const _FeedCard({
    super.key,
    required this.story,
    required this.zh,
    required this.newLabel,
    required this.highlighted,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? const Color(0xFF1565C0)
        : (story.isUnread ? const Color(0xFFC45C26) : null);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: highlighted ? const Color(0xFFE3F2FD) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Color(0xFFC45C26), size: 18),
                const SizedBox(width: 6),
                if (story.isUnread)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC45C26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(newLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(story.body(zh)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('…'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
