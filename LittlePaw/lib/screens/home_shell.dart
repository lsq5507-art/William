import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';
import 'activity_tab.dart';
import 'feed_tab.dart';
import 'profile_tab.dart';
import 'world_tab.dart';

/// Four-tab shell: Feed / Activity / World / Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

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
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadFeed > 0,
              label: Text('$unreadFeed'),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: const Icon(Icons.home),
            label: s.get('feed.tab'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadAct > 0,
              label: Text('$unreadAct'),
              child: const Icon(Icons.favorite_outline),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: s.get('activity.tab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_outlined),
            selectedIcon: const Icon(Icons.public),
            label: s.get('world.tab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: s.get('profile.tab'),
          ),
        ],
      ),
    );
  }
}
