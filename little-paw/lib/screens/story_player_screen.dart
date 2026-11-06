import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/pet_subject_media.dart';
import '../services/quota_ui.dart';
import '../services/ring_story_scripts.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import 'intent_sheet.dart';

/// SCR-ST-01 full-screen story ring player (LP-D-07 / LP-D-10).
class StoryPlayerScreen extends StatefulWidget {
  final String ringId;
  const StoryPlayerScreen({super.key, required this.ringId});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  int index = 0;
  bool endHintShown = false;
  bool showQuota = false;
  Timer? autoTimer;

  static const _chromeH = 56.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SpaceStore>().eventLog.log(
        'story_open',
        props: {'ringId': widget.ringId},
      );
    });
  }

  @override
  void dispose() {
    autoTimer?.cancel();
    super.dispose();
  }

  List<RingStoryFrame> _frames(SpaceStore store) {
    final onb = store.stories.where((s) => s.isOnboarding).toList();
    return RingStoryScripts.framesFor(
      ringId: widget.ringId,
      petName: store.pet?.name ?? 'Little Paw',
      onboarding: onb,
    );
  }

  String _ringLabel(S s) {
    switch (widget.ringId) {
      case RingStoryScripts.opening:
        return s.get('feed.story.opening');
      case RingStoryScripts.friends:
        return s.get('feed.story.friend');
      case RingStoryScripts.adventure:
        return s.get('feed.story.adventure');
      default:
        return widget.ringId;
    }
  }

  Color _bg(ColorHint hint) {
    switch (hint) {
      case ColorHint.soft:
        return const Color(0xFFFFE8F0);
      case ColorHint.sky:
        return const Color(0xFFE3F2FD);
      case ColorHint.mint:
        return const Color(0xFFE8F5E9);
      case ColorHint.warm:
        return const Color(0xFFFFF3E8);
    }
  }

  Future<void> _close(SpaceStore store, {bool finished = false}) async {
    autoTimer?.cancel();
    store.eventLog.log(
      'story_dismiss',
      props: {
        'ringId': widget.ringId,
        'reason': finished ? 'finished' : 'dismiss',
      },
    );
    if (finished) {
      await store.markRingSeen(widget.ringId);
    }
    // P-09 F3: any normal dismiss counts toward ring enter+exit gate.
    await store.recordRingDismissed(widget.ringId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _maybeCompleteOpening(
    SpaceStore store,
    List<RingStoryFrame> frames,
  ) async {
    if (widget.ringId != RingStoryScripts.opening) return;
    if (frames.length >= 3 && index >= frames.length - 1) {
      await store.recordOpeningStoryCompleted();
    }
  }

  void _next(SpaceStore store, List<RingStoryFrame> frames) {
    if (frames.isEmpty) return;
    if (index >= frames.length - 1) {
      unawaited(_maybeCompleteOpening(store, frames));
      if (!endHintShown) {
        setState(() => endHintShown = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S(store.localeZh).get('story.player.end_hint')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    // D-20 F2: stories counter = free「动态发帖」only — do not lock 小小探险/朋友 rings.

    setState(() {
      index += 1;
      endHintShown = false;
    });
    unawaited(_maybeCompleteOpening(store, frames));
  }

  void _prev(List<RingStoryFrame> frames) {
    if (index <= 0) return;
    setState(() {
      index -= 1;
      endHintShown = false;
      showQuota = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final frames = _frames(store);
    final petName = store.pet?.name ?? 'Little Paw';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: frames.isEmpty
            ? _empty(store, s)
            : showQuota
            ? (store.quotaPresentation == QuotaPresentation.defer
                  ? _quotaDefer(store, s)
                  : _quota(store, s))
            : _player(store, s, frames, petName),
      ),
    );
  }

  Widget _closeButton(SpaceStore store, S s, {bool finished = false}) {
    final hit = context.lpTokens.hitMin;
    return Semantics(
      button: true,
      label: s.get('story.a11y.close'),
      child: IconButton(
        tooltip: s.get('story.a11y.close'),
        constraints: BoxConstraints(minWidth: hit, minHeight: hit),
        padding: EdgeInsets.zero,
        onPressed: () => _close(store, finished: finished),
        icon: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }

  Widget _empty(SpaceStore store, S s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.topRight, child: _closeButton(store, s)),
          const Spacer(),
          Text(
            s.get('story.empty.title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.get('story.empty.body'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _close(store),
            child: Text(s.get('story.empty.cta')),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Q-DEFER light layer (D-10 §4.2): primary = 稍后再说; formal = text link.
  Widget _quotaDefer(SpaceStore store, S s) {
    final tokens = context.lpTokens;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.topRight, child: _closeButton(store, s)),
          const Spacer(),
          Material(
            color: tokens.brandSoft,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.get('quota.defer.title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.get('quota.defer.body'),
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: BorderSide(color: tokens.borderHairline),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => _close(store),
                    child: Text(s.get('quota.defer.cta_primary')),
                  ),
                  TextButton(
                    onPressed: () async {
                      await showFormalIntentSheet(
                        context,
                        from: 'story_quota_defer',
                      );
                    },
                    child: Text(s.get('quota.defer.link')),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _quota(SpaceStore store, S s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.topRight, child: _closeButton(store, s)),
          const Spacer(),
          Text(
            s.get('story.quota.title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.get('story.quota.body'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
          ),
          const SizedBox(height: 24),
          // G-01: 「稍后再说」= weak Secondary, not unlock filled primary.
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0x66FFFFFF)),
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => _close(store),
            child: Text(s.get('story.quota.cta_primary')),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () async {
              await showFormalIntentSheet(context, from: 'story_quota');
            },
            child: Text(s.get('story.quota.cta_secondary')),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _player(
    SpaceStore store,
    S s,
    List<RingStoryFrame> frames,
    String petName,
  ) {
    final frame = frames[index];
    final media = PetSubjectMedia.resolveForFeed(frame.imageUrl, petOnly: true);
    final finished = index >= frames.length - 1;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: _bg(frame.colorHint),
          child: media != null && PetSubjectMedia.isAssetPath(media)
              ? Image.asset(media, fit: BoxFit.cover)
              : Center(
                  child: Icon(
                    Icons.pets,
                    size: 96,
                    color: Colors.brown.withValues(alpha: 0.35),
                  ),
                ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0x00000000), Color(0x99000000)],
              stops: [0, 0.35, 1],
            ),
          ),
        ),
        // Tap zones BELOW chrome so X is never eaten (D-10 / P-09 F2).
        Positioned(
          top: _chromeH,
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _prev(frames),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _next(store, frames),
                ),
              ),
            ],
          ),
        ),
        // Progress + close on top (safe area chrome).
        Positioned(
          top: 8,
          left: 12,
          right: 4,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: s.fmt('story.a11y.progress', {
                    'current': '${index + 1}',
                    'total': '${frames.length}',
                  }),
                  child: Row(
                    children: [
                      for (var i = 0; i < frames.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: i < index ? 1 : (i == index ? 0.55 : 0),
                              minHeight: 3,
                              backgroundColor: const Color(0x55FFFFFF),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _closeButton(store, s, finished: finished),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$petName · ${_ringLabel(s)}',
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  frame.body(store.localeZh),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
