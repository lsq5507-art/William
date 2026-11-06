import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/models/custom_character.dart';
import 'package:little_paw/screens/economy_pages.dart';
import 'package:little_paw/screens/role_gen_pages.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/image_gen_service.dart';
import 'package:little_paw/services/role_gen_capabilities.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('costs locked', () {
    test('5000 / 2000 constants', () {
      expect(Economy.coinCostCustomCharacter, 5000);
      expect(Economy.coinCostImageGen, 2000);
    });
  });

  group('M1/M2 success debit after persist', () {
    test('save success debits 5000 with coin_cost_custom_character', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(10000, 'checkin');
      final before = store.economy.coinBalance;

      final result = await store.createCustomCharacter(
        name: '小橘',
        blurb: '温柔、爱晒太阳',
        species: '猫',
        tone: '温柔',
      );

      expect(result.ok, true);
      expect(result.character, isNotNull);
      expect(result.character!.name, '小橘');
      expect(store.customCharacters.length, 1);
      expect(store.economy.coinBalance, before - 5000);
      expect(store.economy.ledger.last.type, 'debit');
      expect(store.economy.ledger.last.reason, 'coin_cost_custom_character');
      expect(store.economy.ledger.last.amount, 5000);
      expect(
        store.eventLog.events.any((e) =>
            e.event == 'character_create_success' ||
            (e.event == 'coin_debit' &&
                e.props['reason'] == 'coin_cost_custom_character')),
        true,
      );
    });

    test('persists across reload', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(8000, 'checkin');
      await store.createCustomCharacter(
        name: '豆豆',
        blurb: '活泼',
      );
      expect(store.customCharacters.length, 1);

      final store2 = SpaceStore();
      await store2.load();
      expect(store2.customCharacters.length, 1);
      expect(store2.customCharacters.first.name, '豆豆');
      expect(store2.economy.coinBalance, 8000 - 5000);
    });
  });

  group('M3 insufficient blocks', () {
    test('balance < 5000 does not create and does not debit', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(4999, 'checkin');
      final before = store.economy.coinBalance;
      final ledgerLen = store.economy.ledger.length;

      final result = await store.createCustomCharacter(
        name: '穷穷',
        blurb: '没钱',
      );

      expect(result.ok, false);
      expect(result.blockedInsufficient, true);
      expect(store.customCharacters, isEmpty);
      expect(store.economy.coinBalance, before);
      expect(store.economy.ledger.length, ledgerLen);
    });
  });

  group('M4 validation failure no debit', () {
    test('empty name/blurb fails without debit', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(9000, 'checkin');
      final before = store.economy.coinBalance;

      final a = await store.createCustomCharacter(name: '', blurb: 'x');
      final b = await store.createCustomCharacter(name: 'x', blurb: '  ');
      expect(a.ok, false);
      expect(b.ok, false);
      expect(store.customCharacters, isEmpty);
      expect(store.economy.coinBalance, before);
    });
  });

  group('M6–M9 image gen fail-closed', () {
    test('capabilities: role on, image off without AI stack', () {
      expect(RoleGenCapabilities.customCharacterEnabled, true);
      expect(RoleGenCapabilities.imageGenEnabled, false);
      expect(ImageGenService.isAvailable, false);
    });

    test('generateImage fails closed with zero debit', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(5000, 'checkin');
      final before = store.economy.coinBalance;

      final r = await store.generateImage(prompt: '一只橘猫晒太阳');
      expect(r.ok, false);
      expect(r.unavailable, true);
      expect(r.imageBytesOrPath, isNull);
      expect(store.economy.coinBalance, before);
      expect(
        store.economy.ledger
            .where((e) => e.reason == 'coin_cost_image_gen')
            .isEmpty,
        true,
      );
    });

    test('even with balance, unavailable path never fake-succeeds', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(2000, 'checkin');
      final r = await ImageGenService.generate(
        prompt: 'test',
        onSuccessWouldDebit: () => store.economy.debit(
          Economy.coinCostImageGen,
          'coin_cost_image_gen',
        ),
      );
      expect(r.ok, false);
      expect(store.economy.coinBalance, 2000);
    });
  });

  group('role pick', () {
    test('selectCustomCharacter sets active id', () async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(10000, 'checkin');
      final created = await store.createCustomCharacter(
        name: '小橘',
        blurb: '温柔',
      );
      expect(created.ok, true);
      await store.selectCustomCharacter(created.character!.id);
      expect(store.selectedCustomCharacterId, created.character!.id);
      expect(store.selectedCustomCharacter?.name, '小橘');
    });
  });

  group('ledger labels', () {
    test('display names for role-gen reasons', () {
      expect(
        economyReasonLabel(true, 'coin_cost_custom_character'),
        '自定义角色',
      );
      expect(economyReasonLabel(true, 'coin_cost_image_gen'), '生成图片');
    });
  });

  group('M5 tasks UI', () {
    testWidgets('role row ready; image row gray unavailable', (tester) async {
      final store = SpaceStore();
      await store.load();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const EconomyTasksPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('创建自定义角色'), findsOneWidget);
      expect(find.textContaining('生成一张图'), findsOneWidget);
      expect(find.textContaining('暂不可用 · 能力未启用'), findsWidgets);
      expect(find.textContaining('去创建'), findsOneWidget);
      // Image must NOT show a primary "去生成" when disabled.
      expect(find.text('去生成'), findsNothing);
      expect(find.textContaining('筹备中'), findsNothing);
    });
  });

  group('create page insufficient sheet', () {
    testWidgets('save with low balance opens insufficient, no character',
        (tester) async {
      final store = SpaceStore();
      await store.load();
      store.economy.credit(100, 'checkin');

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: LpTheme.light(),
            home: const RoleCreatePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('role.name')), '小橘');
      await tester.enterText(find.byKey(const Key('role.blurb')), '温柔');
      await tester.tap(find.byKey(const Key('role.save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('金币不够了'), findsOneWidget);
      expect(find.textContaining('5000'), findsWidgets);
      expect(store.customCharacters, isEmpty);
      expect(store.economy.coinBalance, 100);
    });
  });

  group('build stamp', () {
    test('ux-hotfix-web-v0.20', () {
      expect(FirstDailyGate.buildStampForHost('littlepaw.pet'), 'ux-hotfix-web-v0.20');
    });
  });

  group('CustomCharacter model', () {
    test('json roundtrip', () {
      final c = CustomCharacter(
        id: 'c1',
        name: '小橘',
        blurb: '温柔',
        species: '猫',
        tone: '温柔',
        createdAtIso: '2026-11-04T08:00:00.000Z',
      );
      final copy = CustomCharacter.fromJson(c.toJson());
      expect(copy.name, '小橘');
      expect(copy.blurb, '温柔');
      expect(copy.species, '猫');
    });
  });
}
