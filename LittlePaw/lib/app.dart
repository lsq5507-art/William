import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/confirm_intent_screen.dart';
import 'screens/create_pet_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_stories.dart';
import 'screens/welcome_screen.dart';
import 'services/space_store.dart';

class LittlePawApp extends StatelessWidget {
  const LittlePawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpaceStore>(
      builder: (context, store, _) {
        return MaterialApp(
          title: 'Little Paw',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC45C26),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: _RootRouter(store: store),
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
