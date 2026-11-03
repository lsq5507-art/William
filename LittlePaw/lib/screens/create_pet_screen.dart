import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/pet.dart';
import '../services/space_store.dart';

/// SCR-02 two-step create (M5 / M7 prelude).
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
    return Scaffold(
      appBar: AppBar(
        title: Text(step == 0 ? s.get('create.step1') : s.get('create.step2')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: step == 0 ? _step1(s) : _step2(s, store),
      ),
    );
  }

  Widget _step1(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1 / 2', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: s.get('create.name')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: speciesCtrl,
          decoration: InputDecoration(labelText: s.get('create.species')),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            setState(() => step = 1);
          },
          child: Text(s.get('create.next')),
        ),
      ],
    );
  }

  Widget _step2(S s, SpaceStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('2 / 2', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(s.get('create.type.hint'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        _typeTile(s, PetType.real, 'create.type.real'),
        _typeTile(s, PetType.missed, 'create.type.missed'),
        _typeTile(s, PetType.fiction, 'create.type.fiction'),
        const Spacer(),
        FilledButton(
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
      ],
    );
  }

  Widget _typeTile(S s, PetType t, String key) {
    final selected = type == t;
    return ListTile(
      leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
          color: const Color(0xFFC45C26)),
      title: Text(s.get(key)),
      selected: selected,
      onTap: () => setState(() => type = t),
    );
  }
}
