import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/models/pet.dart';
import 'package:little_paw/screens/profile_tab.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SpaceStore, S)> pumpProfile(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'cat',
      type: PetType.real,
      createdAt: DateTime.utc(2026, 1, 1),
    ));
    final auth = FakeAuthService();
    final sync = CloudSyncService(backend: MemoryCloudBackend());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          Provider<CloudSyncService>.value(value: sync),
        ],
        child: MaterialApp(
          theme: LpTheme.light(),
          home: const ProfileTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (store, S(store.localeZh));
  }

  Future<void> scrollTap(WidgetTester tester, Finder f) async {
    // Ensure lazy ListView children are built before searching.
    final list = find.byType(ListView);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.drag(list.first, const Offset(0, 2500));
      await tester.pumpAndSettle();
    }
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(f, 300, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  test('renamePet updates pet name and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '旧名',
      species: 'cat',
      type: PetType.real,
      createdAt: DateTime.utc(2026, 1, 1),
    ));
    await store.renamePet('新名');
    expect(store.pet?.name, '新名');
    final store2 = SpaceStore();
    await store2.load();
    expect(store2.pet?.name, '新名');
  });

  test('renamePet rejects empty / trims and caps length', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    await store.createPet(Pet(
      id: 'p1',
      name: '瓜瓜',
      species: 'cat',
      type: PetType.real,
      createdAt: DateTime.utc(2026, 1, 1),
    ));
    expect(() => store.renamePet('   '), throwsA(isA<ArgumentError>()));
    await store.renamePet('  短  ');
    expect(store.pet?.name, '短');
    await store.renamePet('一二三四五六七八九十一二三四五六七八九十超长');
    expect(store.pet!.name.length, lessThanOrEqualTo(20));
  });

  testWidgets('PC Must: identity + shop/invite/legal; no fake buy/prices',
      (tester) async {
    final (_, s) = await pumpProfile(tester);

    expect(find.text('瓜瓜'), findsWidgets);
    expect(find.byKey(const Key('profile.edit')), findsOneWidget);
    expect(find.text(s.get('profile.edit')), findsOneWidget);
    expect(find.text(s.get('profile.intent_entry')), findsOneWidget);
    expect(find.text(s.get('auth.guest')), findsOneWidget);

    // Intent toggle only after Advanced expands.
    expect(find.text(s.get('profile.intent_toggle')), findsNothing);
    await scrollTap(tester, find.byKey(const Key('profile.advanced')));
    expect(find.text(s.get('profile.intent_toggle')), findsOneWidget);

    expect(find.textContaining('调试'), findsNothing);
    expect(find.textContaining('Debug'), findsNothing);
    expect(find.textContaining('Prices (hypotheses)'), findsNothing);
    expect(find.text(s.get('profile.demo_store')), findsNothing);

    await scrollTap(tester, find.byKey(const Key('profile.shop')));
    // P-14: shop shell routes to simulated membership (no real buy).
    expect(find.textContaining('当前不会向'), findsWidgets);
    expect(find.text('购买'), findsNothing);
    expect(find.textContaining('USD'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await scrollTap(tester, find.byKey(const Key('profile.invite')));
    expect(find.text('邀请朋友'), findsWidgets);
    expect(find.textContaining('本机模拟到账'), findsWidgets);
    expect(find.textContaining('已获奖'), findsNothing);
    expect(find.textContaining('已获得奖励'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await scrollTap(tester, find.byKey(const Key('profile.privacy')));
    expect(find.text(s.get('profile.privacy')), findsWidgets);
    expect(
      find.textContaining(s.get('profile.legal_placeholder')),
      findsOneWidget,
    );

    // Prefs still present on root after returning later — reopen profile path.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await scrollTap(tester, find.byKey(const Key('profile.terms')));
    expect(find.text(s.get('profile.terms')), findsWidgets);
  });

  testWidgets('guest can rename pet via edit sheet', (tester) async {
    final (store, s) = await pumpProfile(tester);
    await tester.tap(find.byKey(const Key('profile.edit')));
    await tester.pumpAndSettle();
    expect(find.text(s.get('profile.edit_title')), findsOneWidget);
    expect(find.bySemanticsLabel(s.get('profile.edit_a11y')), findsWidgets);

    await tester.enterText(find.byType(TextField), '豆豆');
    await tester.pump();
    await tester
        .tap(find.widgetWithText(FilledButton, s.get('profile.edit_save')));
    await tester.pumpAndSettle();

    expect(store.pet?.name, '豆豆');
    expect(find.text('豆豆'), findsWidgets);
  });
}
