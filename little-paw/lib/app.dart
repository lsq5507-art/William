import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ops/ops_gate.dart';
import 'ops/ops_path.dart';
import 'screens/confirm_intent_screen.dart';
import 'screens/create_pet_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_stories.dart';
import 'screens/welcome_screen.dart';
import 'services/space_store.dart';
import 'theme/lp_theme.dart';
import 'widgets/lp_web_shell_frame.dart';

class LittlePawApp extends StatelessWidget {
  const LittlePawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpaceStore>(
      builder: (context, store, _) {
        final ops = OpsPath.isOpsPath();
        return MaterialApp(
          title: ops ? 'Little Paw Ops' : 'Little Paw',
          debugShowCheckedModeBanner: false,
          theme: LpTheme.light(),
          // LP-DEV-23: root shell so HomeShell + pushed secondary routes share
          // the same web≥1024 / maxWidth=480 frame. Skip /ops.
          builder: ops
              ? null
              : (context, child) => LpWebShellFrame(
                    child: child ?? const SizedBox.shrink(),
                  ),
          home: ops ? const OpsGate() : _RootRouter(store: store),
        );
      },
    );
  }
}

enum _Phase { welcome, create, confirm, onboarding, home }

class _RootRouter extends StatefulWidget {
  final SpaceStore store;
  const _RootRouter({required this.store});

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  _Phase? overridePhase;

  _Phase get phase {
    if (overridePhase != null) return overridePhase!;
    final st = widget.store;
    if (!st.welcomeSeen && !st.hasPet) return _Phase.welcome;
    if (!st.hasPet) return _Phase.create;
    if (!st.onboardingComplete) return _Phase.onboarding;
    return _Phase.home;
  }

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case _Phase.welcome:
        return WelcomeScreen(
          onStart: () => setState(() => overridePhase = _Phase.create),
        );
      case _Phase.create:
        return CreatePetScreen(
          onCreated: () => setState(() => overridePhase = _Phase.confirm),
        );
      case _Phase.confirm:
        return ConfirmIntentScreen(
          onContinueLiving: () =>
              setState(() => overridePhase = _Phase.onboarding),
          onExit: () async {
            await widget.store.resetSpace();
            setState(() => overridePhase = _Phase.welcome);
          },
        );
      case _Phase.onboarding:
        return OnboardingStoriesScreen(
          onDone: () => setState(() => overridePhase = null),
        );
      case _Phase.home:
        return const HomeShell();
    }
  }
}
