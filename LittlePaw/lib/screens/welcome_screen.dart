import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/space_store.dart';

/// SCR-01 Welcome + non-memorial boundary sentence (M5).
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => store.setLocaleZh(!store.localeZh),
                  child: Text(store.localeZh ? 'EN' : '中文'),
                ),
              ),
              const Spacer(),
              Text(
                s.get('welcome.title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC45C26),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                s.get('welcome.subtitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.get('welcome.boundary'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5C4033),
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              _bullet(context, s.get('welcome.v1')),
              _bullet(context, s.get('welcome.v2')),
              _bullet(context, s.get('welcome.v3')),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await store.markWelcomeSeen();
                  onStart();
                },
                child: Text(s.get('welcome.cta')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pets, size: 18, color: Color(0xFFC45C26)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
