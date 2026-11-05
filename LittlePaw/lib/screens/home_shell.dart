import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/space_store.dart';
import 'activity_tab.dart';
import 'feed_tab.dart';
import 'profile_tab.dart';
import '../theme/lp_theme.dart';
import 'economy_pages.dart';
import '../services/first_daily_gate.dart';
import '../services/seo_web_gate.dart';
import '../widgets/first_daily_ui.dart';
import 'story_player_screen.dart';
import 'world_tab.dart';

/// Four-tab shell: 动态 / 互动 / 世界 / 我的 + demoted FAB (LP-D-09).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  bool _corruptPromptShown = false;
  bool _firstDailyCoachQueued = false;

  bool _authGuestLogged = false;

  static const _tabKeys = ['feed', 'activity', 'world', 'profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowCorrupt();
      _logInitialTabViews();
      _maybeLogAuthGuest();
      _maybeShowFirstDailyCoach();
    });
  }

  void _logInitialTabViews() {
    if (!mounted) return;
    final store = context.read<SpaceStore>();
    // Initial visible tab is feed (index 0).
    store.eventLog.log('tab_view', props: {'tab': 'feed'});
    store.eventLog.log('feed_view', props: {'source': 'home_shell'});
  }

  void _maybeLogAuthGuest() {
    if (!mounted || _authGuestLogged) return;
    AuthService? auth;
    try {
      auth = context.read<AuthService>();
    } catch (_) {
      return;
    }
    if (auth.currentUser != null) return;
    _authGuestLogged = true;
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    context.read<SpaceStore>().eventLog.log('auth_guest', props: {
      'platform': platform,
    });
  }

  void _onTabSelected(int i) {
    setState(() => index = i);
    final store = context.read<SpaceStore>();
    final tab = _tabKeys[i];
    store.eventLog.log('tab_view', props: {'tab': tab});
    if (tab == 'feed') {
      store.eventLog.log('feed_view', props: {'source': 'tab'});
    } else if (tab == 'profile') {
      store.eventLog.log('profile_view');
    }
  }


  void _maybeShowFirstDailyCoach() {
    if (!mounted || _firstDailyCoachQueued) return;
    final store = context.read<SpaceStore>();
    // G2: do NOT early-return on dailyExposureCompleted — 3/3 must not swallow coach.
    if (!FirstDailyGate.shouldShowCoach(
      experimentEnabled: SeoWebGate.firstDailyExperimentEnabled,
      onboardingComplete: store.onboardingComplete,
      coachShown: store.firstDailyCoachShown,
    )) {
      return;
    }
    _firstDailyCoachQueued = true;
    Future<void>.delayed(const Duration(milliseconds: 420), () async {
      if (!mounted) return;
      final st = context.read<SpaceStore>();
      if (!FirstDailyGate.shouldShowCoach(
        experimentEnabled: SeoWebGate.firstDailyExperimentEnabled,
        onboardingComplete: st.onboardingComplete,
        coachShown: st.firstDailyCoachShown,
      )) {
        return;
      }
      final empty = !st.hasEligibleFirstDailyContent();
      var acted = false;
      var sheetPresented = false;
      if (!mounted) return;
      try {
        await showFirstDailyCoachSheet(
          context,
          zh: st.localeZh,
          emptyMode: empty,
          onPrimary: () async {
            acted = true;
            if (empty) {
              await st.forceFirstDailyImpression(reason: 'empty_primary');
              if (!mounted) return;
              setState(() => index = 1);
              return;
            }
            final stories = st.visualFeedStories().where((s) => !s.isDemoFill);
            if (stories.isNotEmpty) {
              st.focusStoryId = stories.first.id;
            }
            if (st.storiesRingPlayerEnabled && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StoryPlayerScreen(ringId: 'opening'),
                ),
              );
            }
          },
          onSecondary: () async {
            acted = true;
            await st.forceFirstDailyImpression(reason: 'chat_first');
            if (!mounted) return;
            setState(() => index = 1);
          },
        );
        sheetPresented = true;
      } catch (_) {
        sheetPresented = false;
      }
      // G3: mark shown only after Sheet actually presented (await returned).
      if (sheetPresented && mounted) {
        await context.read<SpaceStore>().markFirstDailyCoachShown();
      }
      // Barrier / back: same as「先聊聊」(exposure only; coach already marked if shown).
      if (!acted && mounted) {
        await context.read<SpaceStore>().forceFirstDailyImpression(reason: 'barrier');
        if (mounted) setState(() => index = 1);
      }
    });
  }

  void _maybeShowCorrupt() {
    if (!mounted || _corruptPromptShown) return;
    final store = context.read<SpaceStore>();
    if (!store.loadCorrupt || store.loadCorruptAcknowledged) return;
    _corruptPromptShown = true;
    final s = S(store.localeZh);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.get('space.load_corrupt_title')),
        content: Text(s.get('space.load_corrupt_body')),
        actions: [
          FilledButton(
            onPressed: () {
              store.acknowledgeLoadCorrupt();
              Navigator.pop(ctx);
            },
            child: Text(s.get('space.load_corrupt_ok')),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final unreadFeed = store.unreadStoryCount;
    final unreadAct = store.unreadReplyCount;

    // DEF-03: Activity → Feed when focusStoryId requested.
    if (store.focusStoryId != null && index != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (index != 0) setState(() => index = 0);
      });
    }

    // LP-DEV-15: deep-link tab from tasks center.
    final pendingTab = store.pendingShellTab;
    if (pendingTab != null && pendingTab != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        store.pendingShellTab = null;
        if (pendingTab >= 0 && pendingTab < _tabKeys.length) {
          _onTabSelected(pendingTab);
        }
      });
    } else if (pendingTab != null && pendingTab == index) {
      store.pendingShellTab = null;
    }

    // LP-DEV-15: auto task credit toast.
    if (store.pendingCoinToastAmount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final n = store.takePendingCoinToast();
        if (n == null) return;
        showEconomyCoinToast(context, store: store, amount: n);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          FeedTab(),
          ActivityTab(),
          WorldTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: context.lpTokens.brandSoft,
        selectedIndex: index,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadFeed > 0,
              label: Text('$unreadFeed'),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: const Icon(Icons.home),
            label: s.get('feed.tab'),
            tooltip: '',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadAct > 0,
              label: Text('$unreadAct'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: s.get('activity.tab'),
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: s.get('world.tab'),
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: s.get('profile.tab'),
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
