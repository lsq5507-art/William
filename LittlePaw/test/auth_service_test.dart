import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/auth_service.dart';

void main() {
  group('FakeAuthService', () {
    test('empty / signed-out state', () {
      final auth = FakeAuthService();
      expect(auth.currentUser, isNull);
      expect(auth.firebaseReady, isTrue);
      expect(auth.lastError, isNull);
    });

    test('sign in then sign out', () async {
      final auth = FakeAuthService();
      final user = await auth.signInWithGoogle();
      expect(user, isNotNull);
      expect(auth.currentUser?.email, 'tester@example.com');
      expect(auth.currentUser?.uid, 'fake-uid-1');

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });

    test('unavailable firebase rejects sign-in', () async {
      final auth = FakeAuthService(ready: false);
      expect(auth.firebaseReady, isFalse);
      expect(auth.currentUser, isNull);
      await expectLater(auth.signInWithGoogle(), throwsStateError);
      expect(auth.lastError, 'firebase_unavailable');
      expect(auth.currentUser, isNull);
    });

    test('authStateChanges emits on sign-in', () async {
      final auth = FakeAuthService();
      final events = <AuthUserInfo?>[];
      final sub = auth.authStateChanges.listen(events.add);
      await auth.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(events.any((e) => e?.uid == 'fake-uid-1'), isTrue);
      await sub.cancel();
      auth.dispose();
    });
  });
}
