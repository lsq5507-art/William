import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/life_scripts.dart';
import '../services/space_store.dart';

/// SCR-05 first-comment guide + done toast + bounded follow-up (M3).
/// Returns 'replies_hit' if quota blocked, else null/ok.
Future<String?> showCommentGuide(BuildContext context, Story story) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CommentGuideSheet(story: story),
  );
}

class _CommentGuideSheet extends StatefulWidget {
  final Story story;
  const _CommentGuideSheet({required this.story});

  @override
  State<_CommentGuideSheet> createState() => _CommentGuideSheetState();
}

class _CommentGuideSheetState extends State<_CommentGuideSheet> {
  final ctrl = TextEditingController();
  bool sending = false;
  String? replyText;
  bool showFollowUp = false;
  bool followUpChosen = false;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final chips =
        store.localeZh ? LifeScripts.suggestionChipsZh : LifeScripts.suggestionChipsEn;
    final pairLabels = LifeScripts.followUpPair(store.localeZh);
    final pairZh = LifeScripts.followUpChoicesZh.first;
    final pairEn = LifeScripts.followUpChoicesEn.first;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.get('comment.guide.title'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () async {
                  await store.skipCommentGuide();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(s.get('comment.guide.skip')),
              ),
            ],
          ),
          Text(widget.story.body(store.localeZh),
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          if (replyText == null)
            Wrap(
              spacing: 8,
              children: chips
                  .map((c) => ActionChip(
                        label: Text(c),
                        onPressed: () => setState(() => ctrl.text = c),
                      ))
                  .toList(),
            ),
          if (replyText == null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
          if (replyText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(replyText!),
            ),
            if (showFollowUp && !followUpChosen) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(s.get('comment.followup_hint'),
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              Row(
                children: [
                  for (var i = 0; i < pairLabels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await store.chooseFollowUp(
                            parentStoryId: widget.story.id,
                            choiceZh: pairZh[i],
                            choiceEn: pairEn[i],
                          );
                          setState(() => followUpChosen = true);
                        },
                        child: Text(pairLabels[i], textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (followUpChosen)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  store.localeZh ? '已记下这个小小后续' : 'Follow-up saved',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (replyText == null)
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      setState(() => sending = true);
                      final thread = await store.sendComment(
                        storyId: widget.story.id,
                        text: text,
                      );
                      if (thread == null) {
                        setState(() => sending = false);
                        if (context.mounted) {
                          Navigator.pop(context, 'replies_hit');
                        }
                        return;
                      }
                      await Future<void>.delayed(
                          const Duration(milliseconds: 400));
                      await store.markReplyShown(thread);
                      setState(() {
                        sending = false;
                        replyText = thread.reply(store.localeZh);
                        showFollowUp = true;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.get('comment.done_toast')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              child: Text(sending ? '…' : s.get('comment.guide.send')),
            ),
          if (replyText != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.get('intent.thanks.close')),
            ),
        ],
      ),
    );
  }
}
