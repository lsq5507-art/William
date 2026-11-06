import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/quota_ui.dart';
import '../services/space_store.dart';
import '../services/story_impression.dart';
import '../services/custom_media_flow.dart';
import '../widgets/custom_media_entry_card.dart';
import '../widgets/interactive_story_card.dart';
import '../widgets/post_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/story_ring_row.dart';
import 'comment_guide.dart';
import 'intent_sheet.dart';
import '../theme/lp_theme.dart';
import 'story_player_screen.dart';
import '../services/first_daily_gate.dart';
import '../services/seo_web_gate.dart';
import '../widgets/first_daily_ui.dart';

/// SCR-04 Feed — D-04 card system (illustration + Stories + PostCards).
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  bool showQuotaStrip = false;
  bool loading = true;
  String quotaType = 'stories';
  final scrollController = ScrollController();
  final listKey = GlobalKey();
  final itemKeys = <String, GlobalKey>{};
  String? highlightId;
  late final StoryImpressionTracker tracker;
  late final StoryImpressionTracker firstDailyTracker;

  @override
  void initState() {
    super.initState();
    tracker = StoryImpressionTracker(
      onImpressed: (id) async {
        if (!mounted) return;
        final store = context.read<SpaceStore>();
        final stories = store.visualFeedStories();
        Story? st;
        for (final s in stories) {
          if (s.id == id) {
            st = s;
            break;
          }
        }
        if (st == null || st.isDemoFill) return;
        await _impress(store, st);
      },
    );
    // D-19: Feed complete ≥50% × ≥1s (maps to first_daily_forced_impression).
    firstDailyTracker = StoryImpressionTracker(
      immediateRatio: 1.1,
      dwellMinRatio: 0.5,
      dwell: const Duration(seconds: 1),
      onImpressed: (id) async {
        if (!mounted) return;
        final store = context.read<SpaceStore>();
        if (!SeoWebGate.firstDailyExperimentEnabled) return;
        if (store.dailyExposureCompleted) return;
        final stories = store.visualFeedStories();
        Story? st;
        for (final s in stories) {
          if (s.id == id) {
            st = s;
            break;
          }
        }
        if (st == null || st.isDemoFill) return;
        await store.completeFirstDailyFromFeedView(st.id);
      },
    );
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => loading = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureAndUpdate();
    });
  }

  @override
  void dispose() {
    tracker.dispose();
    firstDailyTracker.dispose();
    scrollController.dispose();
    super.dispose();
  }

  bool _effectiveShowQuotaStrip(SpaceStore store) {
    if (store.customMediaFlowInFlight) return false;
    if (store.pendingPostQuotaWall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!store.takePendingPostQuotaWall()) return;
        setState(() {
          showQuotaStrip = true;
          quotaType = 'stories';
        });
      });
    }
    return showQuotaStrip;
  }

  Future<void> _impress(SpaceStore store, Story st) async {
    if (st.isDemoFill) return;
    if (store.impressedStoryIds.contains(st.id)) return;
    await store.markStoryImpressed(st.id, source: 'feed');
    if (!mounted) return;
    // D-20 F2: story impress must not open「动态发帖」quota wall.
    setState(() {});
  }

  void _measureAndUpdate() {
    if (!mounted) return;
    final store = context.read<SpaceStore>();
    final stories = store.visualFeedStories();
    final listCtx = listKey.currentContext;
    if (listCtx == null) return;
    final listBox = listCtx.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) return;

    final origin = listBox.localToGlobal(Offset.zero);
    final listTop = origin.dy;
    final listBottom = listTop + listBox.size.height;

    for (final st in stories) {
      if (st.isDemoFill) continue;
      if (store.impressedStoryIds.contains(st.id) ||
          tracker.impressed.contains(st.id)) {
        continue;
      }
      final ctx = itemKeys[st.id]?.currentContext;
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
      final visibleH = (visibleBottom - visibleTop).clamp(0.0, box.size.height);
      final ratio = visibleH / box.size.height;
      tracker.updateVisibility(st.id, ratio);
      if (SeoWebGate.firstDailyExperimentEnabled &&
          !store.dailyExposureCompleted &&
          !firstDailyTracker.impressed.contains(st.id)) {
        firstDailyTracker.updateVisibility(st.id, ratio);
      }
    }
  }

  void _handleFocus(SpaceStore store) {
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
          alignment: 0.05,
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

  void _scrollToPosts() {
    // Rough offset past illustration + section + rings + pill.
    scrollController.animateTo(
      420,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final stories = store.visualFeedStories();
    final cardLayout = store.insFeedLayoutEnabled;
    for (final st in stories) {
      itemKeys.putIfAbsent(st.id, () => GlobalKey());
    }
    _handleFocus(store);

    final showGuide =
        !store.commentGuideDone &&
        !store.commentGuideSkipped &&
        stories.any((e) => !e.isDemoFill);
    Story? realFirst;
    for (final st in stories) {
      if (!st.isDemoFill) {
        realFirst = st;
        break;
      }
    }

    final maxW = MediaQuery.sizeOf(context).width.clamp(0, 540).toDouble();
    final petName = store.pet?.name ?? '瓜瓜';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.pets, color: Color(0xFF1A1A1A), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Little Paw',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => store.setLocaleZh(!store.localeZh),
            child: Text(
              store.localeZh ? 'English' : '简体中文',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showGuide && realFirst != null)
            TextButton(
              onPressed: () => _openCommentGuide(context, store, realFirst!),
              child: Text(s.get('comment.guide.title')),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: ColoredBox(
            color: const Color(0xFFF4F2EF),
            child: Stack(
              children: [
                if (loading)
                  FeedSkeletonList(a11yLabel: s.get('feed.skeleton.a11y'))
                else if (!cardLayout)
                  _classicList(store, s, stories)
                else
                  _cardFeed(store, s, stories, petName),
                if (_effectiveShowQuotaStrip(store) &&
                    (quotaType == 'stories'
                        ? QuotaUi.mayShowPostQuotaWall(
                            storiesLeft: store.economy.storiesLeft,
                            afterSuccessfulPost: true,
                            pickerOrConfirmInFlight:
                                store.customMediaFlowInFlight,
                          )
                        : QuotaUi.mayShowExhaustedUi(
                            storiesLeft: store.economy.storiesLeft,
                            repliesLeft: store.economy.repliesLeft,
                            kind: quotaType,
                          )))
                  Align(
                    alignment: Alignment.bottomCenter,
                    // S1-3: keep strip above Web nav tooltip / sheet overlap zone.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _quotaStrip(context, store, s),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardFeed(SpaceStore store, S s, List<Story> stories, String petName) {
    void openRing(String ringId) {
      if (!store.storiesRingPlayerEnabled) {
        // Flag off: no fake "coming soon" promise — soft no-op.
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryPlayerScreen(ringId: ringId),
        ),
      );
    }

    final rings = [
      StoryRingItemData(
        id: 'opening',
        label: s.get('feed.story.opening'),
        seen: store.seenRingIds.contains('opening'),
        onTap: () => openRing('opening'),
      ),
      StoryRingItemData(
        id: 'friend',
        label: s.get('feed.story.friend'),
        seen: store.seenRingIds.contains('friend'),
        onTap: () => openRing('friend'),
      ),
      StoryRingItemData(
        id: 'adventure',
        label: s.get('feed.story.adventure'),
        seen: store.seenRingIds.contains('adventure'),
        onTap: () => openRing('adventure'),
      ),
    ];

    final showPin = FirstDailyGate.shouldShowPin(
      experimentEnabled: SeoWebGate.firstDailyExperimentEnabled,
      hasEligibleContent: store.hasEligibleFirstDailyContent(),
      pinConsumed: store.firstDailyPinConsumed,
    );
    // LP-DEV-19c order: [PinnedDaily?] → upload → section → rings → pill → spacer → posts
    final headerCount = showPin ? 6 : 5;
    final itemCount = stories.isEmpty
        ? headerCount + 1
        : headerCount + stories.length;
    final uploadIndex = showPin ? 1 : 0;
    final sectionIndex = showPin ? 2 : 1;
    final ringsIndex = showPin ? 3 : 2;
    final pillIndex = showPin ? 4 : 3;
    final spacerIndex = showPin ? 5 : 4;

    Widget uploadOrLegacy() {
      if (store.customMediaToFeedEnabled) {
        return CustomMediaEntryCard(
          petName: petName,
          headerTitle: s.get('feed.custom.title'),
          metaLabel: s.get('feed.custom.meta'),
          lead: s.get('feed.custom.lead'),
          ctaLabel: s.get('feed.custom.cta'),
          footnote: s.get('feed.custom.footnote'),
          a11yCard: s.fmt('feed.custom.a11y.card', {'name': petName}),
          a11yCta: s.get('feed.custom.a11y.cta'),
          onAddToCircle: () => CustomMediaFlow.start(context),
        );
      }
      if (store.interactiveBoxCardLegacyEnabled) {
        return InteractiveStoryCard(
          petName: petName,
          zh: store.localeZh,
          headerTitle: s.get('feed.interactive.title'),
          metaLabel: s.get('feed.interactive.meta'),
          storyLineClosed: s.get('feed.interactive.line_closed'),
          storyLineOpen: s.get('feed.interactive.line_open'),
          ctaClosed: s.get('feed.interactive.cta_open'),
          ctaOpened: s.get('feed.interactive.cta_see_feed'),
          footnote: s.get('feed.interactive.footnote'),
          onSeeFeed: _scrollToPosts,
        );
      }
      return const SizedBox.shrink();
    }

    Widget sectionHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            Text(
              s.get('feed.section.dynamics'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEAE6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.get('feed.section.virtual_partner'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
              ),
            ),
          ],
        ),
      );
    }

    Widget? pinnedDaily() {
      final pinStory = store.firstDailyPinStory();
      if (pinStory == null) return null;
      final cap = store.localeZh ? pinStory.bodyZh : pinStory.bodyEn;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // DEF-QA19-03: note only — never auto-consume on present / timer.
        await store.noteFirstDailyPinPresented();
      });
      return PinnedDailyCard(
        zh: store.localeZh,
        caption: cap,
        petName: petName,
        imageUrl: pinStory.imageUrl,
        onOpenStory: () async {
          await store.consumeFirstDailyPin(reason: 'open_story');
          openRing('opening');
        },
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measureAndUpdate();
        });
        return false;
      },
      child: ListView.builder(
        key: listKey,
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: itemCount,
        itemBuilder: (ctx, i) {
          if (showPin && i == 0) {
            return pinnedDaily() ?? const SizedBox.shrink();
          }
          if (i == uploadIndex) {
            return uploadOrLegacy();
          }
          if (i == sectionIndex) {
            return sectionHeader();
          }
          if (i == ringsIndex) {
            return StoryRingRow(items: rings);
          }
          if (i == pillIndex) {
            return StatusPill(
              message: s.get('feed.status.pill'),
              hint: s.get('feed.status.quota_hint'),
            );
          }
          if (i == spacerIndex) {
            return const SizedBox(height: 4);
          }
          if (stories.isEmpty) {
            return _empty(s, store);
          }
          final st = stories[i - headerCount];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measureAndUpdate();
          });
          final previews = store.comments
              .where((c) => c.storyId == st.id)
              .take(2)
              .map(
                (c) => '${store.pet?.name ?? "…"}: ${c.reply(store.localeZh)}',
              )
              .toList();
          return KeyedSubtree(
            key: itemKeys[st.id],
            child: PostCard(
              story: st,
              petName: petName,
              zh: store.localeZh,
              liked: store.isLiked(st.id),
              highlighted: highlightId == st.id,
              newLabel: s.get('new_badge'),
              moreLabel: s.get('feed.caption.more'),
              lessLabel: s.get('feed.caption.less'),
              likeLabel: s.get('feed.like'),
              commentLabel: s.get('feed.comment'),
              commentPreviews: previews,
              onToggleLike: () => store.toggleLike(st.id),
              onComment: () => _openCommentGuide(context, store, st),
              locationLabel: st.locationLabel ?? 'Cloud Town',
            ),
          );
        },
      ),
    );
  }

  Widget _classicList(SpaceStore store, S s, List<Story> stories) {
    if (stories.isEmpty) return _empty(s, store);
    return ListView.builder(
      key: listKey,
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: stories.length,
      itemBuilder: (ctx, i) {
        final st = stories[i];
        return KeyedSubtree(
          key: itemKeys[st.id],
          child: _ClassicFeedCard(
            story: st,
            zh: store.localeZh,
            liked: store.isLiked(st.id),
            highlighted: highlightId == st.id,
            newLabel: s.get('new_badge'),
            likeLabel: s.get('feed.like'),
            onToggleLike: () => store.toggleLike(st.id),
            onComment: () => _openCommentGuide(context, store, st),
          ),
        );
      },
    );
  }

  Widget _empty(S s, SpaceStore store) {
    // D-10 / P-09 F1: no fake claw PostCards — single empty module or soft merge.
    if (store.feedNoFakePlaceholderPosts && store.feedNeedsPhotoEmpty) {
      if (store.customMediaToFeedEnabled) {
        // Top entry card already has near-black CTA — soft hint only.
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.get('feed.empty.photo.soft'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.lpTokens.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(s.get('feed.empty.photo.soft_cta')),
              ),
            ],
          ),
        );
      }
      final tokens = context.lpTokens;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(color: tokens.borderHairline),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: 40,
                  color: tokens.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  s.get('feed.empty.photo.title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.get('feed.empty.photo.body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.ctaInverse,
                      foregroundColor: tokens.onCtaInverse,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => CustomMediaFlow.start(context),
                    child: Text(s.get('feed.empty.photo.cta')),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.get('feed.empty.photo.hint'),
                  style: TextStyle(fontSize: 11, color: tokens.textTertiary),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            size: 40,
            color: Color(0xFFC45C26),
          ),
          const SizedBox(height: 12),
          Text(s.get('feed.empty.no_new'), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            '${s.get('feed.empty.quota_left_hint')}: '
            '${store.economy.storiesLeft}/${store.economy.storiesLimit} · '
            '${store.economy.repliesLeft}/${store.economy.repliesLimit}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
          ),
        ],
      ),
    );
  }

  Widget _quotaStrip(BuildContext context, SpaceStore store, S s) {
    final e = store.economy;
    final kind = QuotaUi.kind(
      storiesHit: e.storiesHit,
      repliesHit: e.repliesHit,
      preferred: quotaType,
    );
    final defer = store.quotaPresentation == QuotaPresentation.defer;
    final strong =
        !defer &&
        QuotaUi.showStrongSecondary(
          activeUtcDays: store.activeUtcDayCount,
          intentEntryEnabled: store.intentEntryEnabled,
        );
    final soft =
        !defer &&
        QuotaUi.showSoftSecondary(
          activeUtcDays: store.activeUtcDayCount,
          intentEntryEnabled: store.intentEntryEnabled,
        );

    return Material(
      elevation: 0,
      color: const Color(0xFFF3E0D4),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 88),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.get(
                          defer ? 'quota.defer.title' : QuotaUi.titleKey(kind),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        s.get(
                          defer ? 'quota.defer.body' : QuotaUi.bodyKey(kind),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFF1A1A1A),
                                side: const BorderSide(
                                  color: Color(0xFFE4E1DC),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: () =>
                                  setState(() => showQuotaStrip = false),
                              child: Text(
                                s.get(
                                  defer
                                      ? 'quota.defer.cta_primary'
                                      : 'quota.cta_primary',
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (defer) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () => showFormalIntentSheet(
                                  context,
                                  from: 'quota_defer',
                                ),
                                child: Text(
                                  s.get('quota.defer.link'),
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ] else if (strong || soft) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: strong
                                    ? () => showFormalIntentSheet(
                                        context,
                                        from: 'quota',
                                      )
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              s.get('quota.cta_secondary_soft'),
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  s.get(
                                    strong
                                        ? 'quota.cta_secondary'
                                        : 'quota.cta_secondary_soft',
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => showQuotaStrip = false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCommentGuide(
    BuildContext context,
    SpaceStore store,
    Story story,
  ) async {
    final hit = await showCommentGuide(context, story);
    if (!mounted) return;
    if (hit == 'replies_hit' &&
        QuotaUi.mayShowExhaustedUi(
          storiesLeft: store.economy.storiesLeft,
          repliesLeft: store.economy.repliesLeft,
          kind: 'replies',
        )) {
      setState(() {
        showQuotaStrip = true;
        final both = store.economy.storiesHit && store.economy.repliesHit;
        quotaType = both ? 'both' : 'replies';
      });
    }
  }
}

/// Pre-D-04 text Card (layout rollback when insFeedLayoutEnabled=false).
class _ClassicFeedCard extends StatelessWidget {
  final Story story;
  final bool zh;
  final bool liked;
  final bool highlighted;
  final String newLabel;
  final String likeLabel;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;

  const _ClassicFeedCard({
    required this.story,
    required this.zh,
    required this.liked,
    required this.highlighted,
    required this.newLabel,
    required this.likeLabel,
    required this.onToggleLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted
              ? const Color(0xFFC45C26)
              : (story.isUnread ? const Color(0xFFC45C26) : Colors.transparent),
          width: highlighted || story.isUnread ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Color(0xFFC45C26), size: 18),
                const SizedBox(width: 8),
                if (story.isUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC45C26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      newLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: likeLabel,
                  onPressed: onToggleLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? const Color(0xFFE31B54) : null,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(story.body(zh)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onComment,
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
