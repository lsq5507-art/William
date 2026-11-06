import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/economy.dart';
import '../services/role_gen_capabilities.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import 'economy_pages.dart';

String _zh(SpaceStore s, String zh, String en) => s.localeZh ? zh : en;

/// SCR-17-ROLE-CREATE
class RoleCreatePage extends StatefulWidget {
  const RoleCreatePage({super.key});

  @override
  State<RoleCreatePage> createState() => _RoleCreatePageState();
}

class _RoleCreatePageState extends State<RoleCreatePage> {
  final nameCtrl = TextEditingController();
  final blurbCtrl = TextEditingController();
  String species = '猫';
  String tone = '温柔';
  String? fieldError;
  bool saving = false;

  static const speciesOptions = ['猫', '狗', '其他'];
  static const toneOptions = ['温柔', '活泼', '冷静'];

  @override
  void dispose() {
    nameCtrl.dispose();
    blurbCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    final store = context.read<SpaceStore>();
    final name = nameCtrl.text.trim();
    final blurb = blurbCtrl.text.trim();
    if (name.isEmpty || blurb.isEmpty) {
      setState(() => fieldError = _zh(store, '请填写名字和一句话设定',
          'Name and one-line blurb required'));
      return;
    }
    setState(() {
      fieldError = null;
      saving = true;
    });

    if (store.economy.coinBalance < Economy.coinCostCustomCharacter) {
      setState(() => saving = false);
      if (!mounted) return;
      await showCoinInsufficientSheet(
        context,
        needAmount: Economy.coinCostCustomCharacter,
        reasonZh: '保存角色需要 ${Economy.coinCostCustomCharacter} 金币。',
        reasonEn:
            'Saving a character needs ${Economy.coinCostCustomCharacter} coins.',
      );
      return;
    }

    final confirmed = await showSpendConfirmSheet(
      context,
      amount: Economy.coinCostCustomCharacter,
      bodyZh: '将消耗 ${Economy.coinCostCustomCharacter} 金币保存该角色。\n仅保存成功后扣币；取消不扣。',
      bodyEn:
          'Spend ${Economy.coinCostCustomCharacter} coins to save this character.\nDebit only after success; cancel = no charge.',
    );
    if (confirmed != true) {
      if (mounted) setState(() => saving = false);
      return;
    }
    if (!mounted) return;

    final result = await store.createCustomCharacter(
      name: name,
      blurb: blurb,
      species: species,
      tone: tone,
    );
    if (!mounted) return;
    setState(() => saving = false);

    if (result.blockedInsufficient) {
      await showCoinInsufficientSheet(
        context,
        needAmount: Economy.coinCostCustomCharacter,
        reasonZh: '保存角色需要 ${Economy.coinCostCustomCharacter} 金币。',
        reasonEn:
            'Saving a character needs ${Economy.coinCostCustomCharacter} coins.',
      );
      return;
    }
    if (!result.ok) {
      setState(() => fieldError = _zh(store, '保存失败，没有扣币 · 可以重试',
          'Save failed · no coins charged · retry'));
      return;
    }

    showEconomyCoinToast(
      context,
      store: store,
      amount: -Economy.coinCostCustomCharacter,
      labelZh: '已保存 · −${Economy.coinCostCustomCharacter} 金币',
      labelEn: 'Saved · −${Economy.coinCostCustomCharacter} coins',
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RolePickPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final tokens = context.lpTokens;
    if (!RoleGenCapabilities.customCharacterEnabled) {
      return const RoleUnavailablePage(kind: RoleUnavailableKind.character);
    }
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(_zh(store, '创建自定义角色', 'Create custom character')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_zh(store, '名字 *', 'Name *')),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('role.name'),
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: _zh(store, '例如：小橘', 'e.g. Mikan'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(_zh(store, '一句话设定 / 性格 *', 'One-line persona *')),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('role.blurb'),
                    controller: blurbCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          _zh(store, '温柔、爱晒太阳…', 'Gentle, loves sun…'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: species,
                          decoration: InputDecoration(
                            labelText: _zh(store, '物种（可选）', 'Species'),
                            border: const OutlineInputBorder(),
                          ),
                          items: speciesOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: saving
                              ? null
                              : (v) => setState(() => species = v ?? species),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: tone,
                          decoration: InputDecoration(
                            labelText: _zh(store, '语气（可选）', 'Tone'),
                            border: const OutlineInputBorder(),
                          ),
                          items: toneOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: saving
                              ? null
                              : (v) => setState(() => tone = v ?? tone),
                        ),
                      ),
                    ],
                  ),
                  if (fieldError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      fieldError!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _zh(
                      store,
                      '费用提示：保存成功后消耗 ${Economy.coinCostCustomCharacter} 金币（失败不扣 · 本机可用）',
                      'Cost: ${Economy.coinCostCustomCharacter} coins after successful save (no charge on fail · on-device)',
                    ),
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('role.save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.ctaInverse,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: saving ? null : _save,
                    child: Text(
                      saving
                          ? _zh(store, '保存中…', 'Saving…')
                          : _zh(
                              store,
                              '保存角色 · ${Economy.coinCostCustomCharacter}',
                              'Save · ${Economy.coinCostCustomCharacter}',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _zh(
              store,
              '消耗为本机模拟经济 · 非商店发币或返佣。',
              'Simulated local economy · not store payouts.',
            ),
            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// SCR-17-ROLE-PICK
class RolePickPage extends StatelessWidget {
  const RolePickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final tokens = context.lpTokens;
    final list = store.customCharacters;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '选用角色', 'Pick companion'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _zh(store, '本机角色 · 单选', 'On-device · single select'),
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_zh(store, '还没有自定义角色 · 去创建',
                        'No custom characters yet · create one')),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.ctaInverse,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RoleCreatePage(),
                          ),
                        );
                      },
                      child: Text(_zh(store, '去创建', 'Create')),
                    ),
                  ],
                ),
              ),
            )
          else
            ...list.map((c) {
              final selected = store.selectedCustomCharacterId == c.id;
              return Card(
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: ListTile(
                    leading: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? tokens.ctaInverse : tokens.textTertiary,
                    ),
                    title: Text(c.name),
                    subtitle: Text(
                      c.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => store.selectCustomCharacter(c.id),
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          if (list.isNotEmpty)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.ctaInverse,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: store.selectedCustomCharacterId == null
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(_zh(store, '使用选中的角色', 'Use selected')),
            ),
          const SizedBox(height: 8),
          Text(
            _zh(store, '仅本机可用 · 非角色市场',
                'On-device only · not a character market'),
            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// SCR-17-IMG-GEN — fail-closed when AI stack unavailable.
class ImageGenPage extends StatefulWidget {
  const ImageGenPage({super.key});

  @override
  State<ImageGenPage> createState() => _ImageGenPageState();
}

class _ImageGenPageState extends State<ImageGenPage> {
  final promptCtrl = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final store = context.read<SpaceStore>();
    if (!RoleGenCapabilities.imageGenEnabled) {
      setState(() => error = _zh(store, '暂不可用 · 能力未启用',
          'Unavailable · capability not enabled'));
      return;
    }
    if (store.economy.coinBalance < Economy.coinCostImageGen) {
      await showCoinInsufficientSheet(
        context,
        needAmount: Economy.coinCostImageGen,
        reasonZh: '生成一张图需要 ${Economy.coinCostImageGen} 金币。',
        reasonEn:
            'Generating an image needs ${Economy.coinCostImageGen} coins.',
      );
      return;
    }
    final confirmed = await showSpendConfirmSheet(
      context,
      amount: Economy.coinCostImageGen,
      bodyZh: '将消耗 ${Economy.coinCostImageGen} 金币生成一张图。\n仅成功出图后扣币；取消不扣。',
      bodyEn:
          'Spend ${Economy.coinCostImageGen} coins for one image.\nDebit only after success; cancel = no charge.',
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    final r = await store.generateImage(prompt: promptCtrl.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (r.unavailable || !r.ok) {
      setState(() => error = _zh(
            store,
            r.unavailable
                ? '暂不可用 · 能力未启用'
                : '这次没有生成出来 · 没有扣币 · 可以稍后重试',
            r.unavailable
                ? 'Unavailable · capability not enabled'
                : 'No image · no coins charged · retry later',
          ));
      return;
    }
    showEconomyCoinToast(
      context,
      store: store,
      amount: -Economy.coinCostImageGen,
      labelZh: '已出图 · −${Economy.coinCostImageGen} 金币',
      labelEn: 'Image ready · −${Economy.coinCostImageGen} coins',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final tokens = context.lpTokens;
    if (!RoleGenCapabilities.imageGenEnabled) {
      return const RoleUnavailablePage(kind: RoleUnavailableKind.image);
    }
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '生成一张图', 'Generate an image'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: promptCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _zh(store, '描述想生成的画面…', 'Describe the image…'),
              border: const OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _zh(
              store,
              '费用：成功出图后消耗 ${Economy.coinCostImageGen} 金币',
              'Cost: ${Economy.coinCostImageGen} coins after a usable image',
            ),
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Color(0xFFB42318))),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ctaInverse,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: busy ? null : _generate,
            child: Text(
              busy
                  ? _zh(store, '生成中…', 'Generating…')
                  : _zh(store, '生成 · ${Economy.coinCostImageGen}',
                      'Generate · ${Economy.coinCostImageGen}'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _zh(store, '消耗为本机模拟经济 · 非商店发币或返佣。',
                'Simulated local economy · not store payouts.'),
            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

enum RoleUnavailableKind { character, image }

/// SCR-17-UNAVAILABLE
class RoleUnavailablePage extends StatelessWidget {
  const RoleUnavailablePage({super.key, required this.kind});

  final RoleUnavailableKind kind;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final tokens = context.lpTokens;
    final title = kind == RoleUnavailableKind.image
        ? _zh(store, '生图暂不可用', 'Image gen unavailable')
        : _zh(store, '角色创建暂不可用', 'Character create unavailable');
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _zh(store, '当前环境未启用该能力。',
                  'This capability is not enabled in the current environment.'),
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(_zh(store, '关闭', 'Close')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Should: large spend confirm sheet (G-01 cancel = no debit).
Future<bool?> showSpendConfirmSheet(
  BuildContext context, {
  required int amount,
  required String bodyZh,
  required String bodyEn,
}) {
  final store = context.read<SpaceStore>();
  return showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final tokens = ctx.lpTokens;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _zh(store, '确认消耗', 'Confirm spend'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(_zh(store, bodyZh, bodyEn)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.ctaInverse,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_zh(store, '确认消耗 $amount 金币',
                    'Confirm $amount coins')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_zh(store, '取消', 'Cancel')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
