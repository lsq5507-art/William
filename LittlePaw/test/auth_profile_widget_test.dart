import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/screens/profile_tab.dart';
import 'package:little_paw/services/auth_service.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/space_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SpaceStore> pumpProfile(
    WidgetTester tester, {
    required AuthService auth,
    CloudSyncService? sync,
    SpaceStore? store,
  }) async {
    late SpaceStore resolved;
    if (store == null) {
      SharedPreferences.setMockInitialValues({});
      resolved = SpaceStore();
      await resolved.load();
    } else {
      resolved = store;
    }
    final syncSvc = sync ?? CloudSyncService(backend: MemoryCloudBackend());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: resolved),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          Provider<CloudSyncService>.value(value: syncSvc),
        ],
        child: const MaterialApp(home: ProfileTab()),
      ),
    );
    return resolved;
  }

  testWidgets('guest shows Google sign-in', (tester) async {
    final auth = FakeAuthService();
    await pumpProfile(tester, auth: auth);
    expect(find.text(S(true).get('auth.sign_in_google')), findsOneWidget);
    expect(find.text(S(true).get('auth.guest')), findsOneWidget);
  });

  testWidgets('signed-in shows email and sign-out', (tester) async {
    final auth = FakeAuthService(
      initial: const AuthUserInfo(
        uid: 'u',
        email: 'me@example.com',
      ),
    );
    await pumpProfile(tester, auth: auth);
    expect(find.textContaining('me@example.com'), findsOneWidget);
    expect(find.text(S(true).get('auth.sign_out')), findsOneWidget);
  });

  testWidgets('tap sign-in updates UI', (tester) async {
    final auth = FakeAuthService();
    final sync = CloudSyncService(backend: MemoryCloudBackend());
    await pumpProfile(tester, auth: auth, sync: sync);
    await tester.tap(find.text(S(true).get('auth.sign_in_google')));
    await tester.pumpAndSettle();
    expect(find.textContaining('tester@example.com'), findsOneWidget);
    expect(find.text(S(true).get('auth.sign_out')), findsOneWidget);
  });

  // DEF-FB01-03
  testWidgets('firebaseReady=false shows unavailable copy', (tester) async {
    final auth = FakeAuthService(ready: false);
    await pumpProfile(tester, auth: auth);
    expect(find.text(S(true).get('auth.guest')), findsOneWidget);
    expect(
      find.text(S(true).get('auth.firebase_unavailable')),
      findsOneWidget,
    );
  });

  // DEF-FB01-02
  testWidgets('sign-out keeps local SpaceStore / prefs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SpaceStore();
    await store.load();
    store.welcomeSeen = true;
    store.localeZh = false;
    await store.persist();
    final stamp = store.updatedAt;
    expect(stamp, isNotNull);

    final auth = FakeAuthService(
      initial: const AuthUserInfo(uid: 'u2', email: 'keep@example.com'),
    );
    final sync = CloudSyncService(backend: MemoryCloudBackend());
    await pumpProfile(tester, auth: auth, sync: sync, store: store);

    final s = S(store.localeZh);
    await tester.tap(find.text(s.get('auth.sign_out')));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.text(s.get('auth.guest')), findsOneWidget);
    expect(store.welcomeSeen, isTrue);
    expect(store.localeZh, isFalse);
    expect(store.updatedAt, stamp);
    expect(store.onAfterPersist, isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('little_paw_space_v1'), isNotNull);
  });
}
