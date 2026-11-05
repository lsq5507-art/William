import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/pet.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import '../widgets/centered_onboarding_card.dart';

/// SCR-18-BASIC / SCR-18-TYPE — same centered card system as welcome (D-18).
class CreatePetScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const CreatePetScreen({super.key, required this.onCreated});

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  int step = 0;
  final nameCtrl = TextEditingController(text: 'Mochi');
  final speciesCtrl = TextEditingController(text: 'cat');
  PetType type = PetType.fiction;
  String? _error;

  @override
  void dispose() {
    nameCtrl.dispose();
    speciesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: CenteredOnboardingCard(
          child: step == 0 ? _step1(s) : _step2(s, store),
        ),
      ),
    );
  }

  Widget _step1(S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1/2', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.lpTokens.textSecondary,
            )),
        const SizedBox(height: 8),
        Text(
          s.get('create.step1'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: s.get('create.name'),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: speciesCtrl,
          decoration: InputDecoration(labelText: s.get('create.species')),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: lpPrimaryCtaStyle(),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                setState(() => _error = s.get('create.name_required'));
                return;
              }
              setState(() {
                _error = null;
                step = 1;
              });
            },
            child: Text(s.get('create.next')),
          ),
        ),
      ],
    );
  }

  Widget _step2(S s, SpaceStore store) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('2/2', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.lpTokens.textSecondary,
            )),
        const SizedBox(height: 8),
        Text(
          s.get('create.step2'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          s.get('create.type.hint'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.lpTokens.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        _typeTile(s, PetType.real, 'create.type.real'),
        _typeTile(s, PetType.missed, 'create.type.missed'),
        _typeTile(s, PetType.fiction, 'create.type.fiction'),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: lpPrimaryCtaStyle(),
            onPressed: () async {
              final pet = Pet(
                id: 'pet_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                species: speciesCtrl.text.trim().isEmpty
                    ? 'pet'
                    : speciesCtrl.text.trim(),
                type: type,
                createdAt: DateTime.now().toUtc(),
              );
              await store.createPet(pet);
              widget.onCreated();
            },
            child: Text(s.get('create.done')),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.get('create.footnote'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.lpTokens.textTertiary,
              ),
        ),
      ],
    );
  }

  Widget _typeTile(S s, PetType t, String key) {
    final selected = type == t;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: LpTheme.brandPrimary,
      ),
      title: Text(s.get(key)),
      selected: selected,
      onTap: () => setState(() => type = t),
    );
  }
}
