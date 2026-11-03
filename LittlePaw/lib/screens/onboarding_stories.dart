import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/space_store.dart';
import '../services/story_impression.dart';

/// SCR-03 Onboarding 3 stories gate (M7).
/// Impression: >=80% visible in list viewport OR dwell >=2s while in viewport.
class OnboardingStoriesScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingStoriesScreen({super.key, required this.onDone});

  @override
  State<OnboardingStoriesScreen> createState() =>
      _OnboardingStoriesScreenState();
}

class _OnboardingStoriesScreenState extends State<OnboardingStoriesScreen> {
  final listKey = GlobalKey();
  final cardKeys = <String, GlobalKey>{};
  late final StoryImpressionTracker tracker;

  @override
  void initState() {
    super.initState();
    tracker = StoryImpressionTracker(
      onImpressed: (id) async {
        if (!mounted) return;
        setState(() {});
        final store = context.read<SpaceStore>();
        await store.markStoryImpressed(id, source: 'onboarding');
      },
    );
    // Only measure real viewport after first layout — never blind-start dwell.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndUpdate();
    });
  }

  @override
  void dispose() {
    tracker.dispose();
    super.dispose();
  }

  List<Story> _stories(SpaceStore store) =>
      store.stories.where((s) => s.isOnboarding).toList();

  bool get allDone => tracker.impressedCount >= 3;

  void _measureAndUpdate() {
    final store = context.read<SpaceStore>();
    final stories = _stories(store);
    final listCtx = listKey.currentContext;
    if (listCtx == null) return;
    final listBox = listCtx.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) return;

    final listOrigin = listBox.localToGlobal(Offset.zero);
    final listTop = listOrigin.dy;
    final listBottom = listTop + listBox.size.height;

    for (final st in stories) {
      final ctx = cardKeys[st.id]?.currentContext;
      if (ctx == null) {
        tracker.updateVisibility(st.id, 0);
        continue;
      }
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || box.size.height <= 0) {
        tracker.updateVisibility(st.id, 0);
        continue;
      }
      final pos = box.localToGlobal(Offset.zero);
      final top = pos.dy;
      final bottom = top + box.size.height;
      final visibleTop = top < listTop ? listTop : top;
      final visibleBottom = bottom > listBottom ? listBottom : bottom;
      final visibleH =
          (visibleBottom - visibleTop).clamp(0.0, box.size.height);
      final ratio = visibleH / box.size.height;
      tracker.updateVisibility(st.id, ratio);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final stories = _stories(store);
    for (final st in stories) {
      cardKeys.putIfAbsent(st.id, () => GlobalKey());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.get('onboarding.stories.title'),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(s.get('onboarding.stories.sub')),
                  const SizedBox(height: 8),
                  Text('${tracker.impressedCount} / 3'),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _measureAndUpdate();
                  });
                  return false;
                },
                child: ListView.builder(
                  key: listKey,
                  padding: const EdgeInsets.all(16),
                  itemCount: stories.length,
                  itemBuilder: (ctx, i) {
                    final st = stories[i];
                    return _StoryCard(
                      key: cardKeys[st.id],
                      story: st,
                      zh: store.localeZh,
                      impressed: tracker.impressed.contains(st.id),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: allDone
                    ? () async {
                        await store.completeOnboarding();
                        widget.onDone();
                      }
                    : null,
                child: Text(allDone
                    ? s.get('onboarding.stories.cta_done')
                    : s.get('onboarding.stories.cta_wait')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;
  final bool zh;
  final bool impressed;
  const _StoryCard({
    super.key,
    required this.story,
    required this.zh,
    required this.impressed,
  });

  @override
  Widget build(BuildContext context) {
    // Tall cards so typical viewports cannot show all 3 at ≥80% without scroll.
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 220),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pets, color: Color(0xFFC45C26)),
                  const Spacer(),
                  if (impressed)
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(story.body(zh), style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Text(
                zh ? '继续往下滑，看完三条日常' : 'Keep scrolling to finish all three',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
