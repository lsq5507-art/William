import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/screens/chat_screen.dart';
import 'package:little_paw/screens/profile_tab.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/space_store.dart';
import 'package:little_paw/theme/lp_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('S0-2 profileDebugToolsVisible defaults off', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    expect(store.profileDebugToolsVisible, isFalse);
  });

  testWidgets('S0-2 Profile permanently hides INS/Prices (hard-hide)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
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

    final s = S(store.localeZh);
    expect(find.text(s.get('profile.ins_layout_toggle')), findsNothing);
    expect(find.textContaining('Prices (hypotheses)'), findsNothing);
    expect(find.textContaining('INS 图流'), findsNothing);
    expect(find.textContaining('调试'), findsNothing);

    // Flag alone must NOT surface those strings (S0-2 hard-hide).
    store.setProfileDebugToolsVisible(true);
    await tester.pumpAndSettle();
    expect(find.text(s.get('profile.ins_layout_toggle')), findsNothing);
    expect(find.textContaining('Prices (hypotheses)'), findsNothing);
    expect(find.textContaining('hypotheses'), findsNothing);
  });

  test('S0-2 profile_tab source has no user-visible INS/Prices nodes', () {
    Directory root = Directory.current;
    if (!File('pubspec.yaml').existsSync()) root = Directory('..');
    final src =
        File('${root.path}/lib/screens/profile_tab.dart').readAsStringSync();
    expect(src.contains('Prices (hypotheses)'), isFalse);
    expect(src.contains('hypotheses'), isFalse);
    expect(src.contains('ins_layout_toggle'), isFalse);
    expect(src.contains('INS 图流'), isFalse);
    expect(src.contains('调试'), isFalse);
  });

  testWidgets('S0-1 Chat send uses near-black ctaInverse, not terracotta',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    final auth = FakeAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          ChangeNotifierProvider<AuthService>.value(value: auth),
        ],
        child: MaterialApp(
          theme: LpTheme.light(),
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tokens = LpTheme.light().extension<LpTokens>()!;
    final sendLabel = S(store.localeZh).get('activity.chat.send');
    final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
    IconButton? send;
    for (final b in buttons) {
      if (b.tooltip == sendLabel) send = b;
    }
    if (send != null) {
      final bg = send.style?.backgroundColor?.resolve({});
      expect(bg, tokens.ctaInverse);
      expect(bg, isNot(const Color(0xFF8E4D2E)));
      expect(bg, isNot(LpTheme.brandPrimary));
    } else {
      final materials = tester.widgetList<Material>(find.byType(Material));
      expect(
        materials.any((m) => m.color == tokens.ctaInverse),
        isTrue,
        reason: 'send fill must be ctaInverse',
      );
    }
  });

  test('S1 chat/activity/profile avoid blush page bottom + terracotta send',
      () {
    Directory root = Directory.current;
    if (!File('pubspec.yaml').existsSync()) root = Directory('..');
    for (final rel in [
      'lib/screens/chat_screen.dart',
      'lib/screens/activity_tab.dart',
      'lib/screens/profile_tab.dart',
    ]) {
      final src = File('${root.path}/$rel').readAsStringSync();
      expect(src.contains('0xFFFFF8F6'), isFalse, reason: rel);
      expect(src.contains('8E4D2E'), isFalse, reason: rel);
    }
  });

  test('S1-4 ring tokens stay same-hue warm orange only', () {
    final t = LpTheme.light().extension<LpTokens>()!;
    expect(t.ringUnreadStart, const Color(0xFFE07A3A));
    expect(t.ringUnreadEnd, const Color(0xFFC45C26));
  });
}
