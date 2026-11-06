import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Lightweight signed-in user view (keeps UI/tests off Firebase User).
class AuthUserInfo {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthUserInfo({
    required this.uid,
    this.email,
    this.displayName,
  });

  factory AuthUserInfo.fromFirebase(User user) => AuthUserInfo(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
}

/// Testable auth façade — Firebase impl + in-memory fake.
abstract class AuthService extends ChangeNotifier {
  AuthUserInfo? get currentUser;
  Stream<AuthUserInfo?> get authStateChanges;
  bool get firebaseReady;
  Future<AuthUserInfo?> signInWithGoogle();
  Future<void> signOut();
  String? get lastError;
}

/// Production Google / Firebase Auth wrapper.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    this.firebaseReady = true,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  final bool firebaseReady;
  bool _googleSignInInitialized = false;
  String? _lastError;

  @override
  String? get lastError => _lastError;

  @override
  AuthUserInfo? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AuthUserInfo.fromFirebase(u);
  }

  @override
  Stream<AuthUserInfo?> get authStateChanges => _auth.authStateChanges().map(
        (u) => u == null ? null : AuthUserInfo.fromFirebase(u),
      );

  Future<void> _ensureGoogleSignIn() async {
    if (kIsWeb || _googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  @override
  Future<AuthUserInfo?> signInWithGoogle() async {
    _lastError = null;
    if (!firebaseReady) {
      _lastError = 'firebase_unavailable';
      notifyListeners();
      throw StateError('Firebase is not initialized');
    }
    try {
      final UserCredential cred;
      if (kIsWeb) {
        // Web: Firebase Auth signInWithPopup(GoogleAuthProvider) — no app-side
        // google_sign_in clientId required; uses Firebase/Google provider + authorized domains.
        final provider = GoogleAuthProvider();
        cred = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignIn();
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      final user = cred.user;
      notifyListeners();
      return user == null ? null : AuthUserInfo.fromFirebase(user);
    } on FirebaseAuthException catch (e) {
      _lastError = e.code;
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _lastError = null;
    try {
      if (!kIsWeb && _googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      _lastError = e.toString();
      try {
        await _auth.signOut();
      } catch (_) {}
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }
}

/// In-memory fake for unit/widget tests (no network).
class FakeAuthService extends AuthService {
  FakeAuthService({AuthUserInfo? initial, this.ready = true}) : _user = initial;

  AuthUserInfo? _user;
  final _controller = StreamController<AuthUserInfo?>.broadcast();
  String? _lastError;
  bool ready;

  @override
  bool get firebaseReady => ready;

  @override
  String? get lastError => _lastError;

  @override
  AuthUserInfo? get currentUser => _user;

  @override
  Stream<AuthUserInfo?> get authStateChanges async* {
    yield _user;
    yield* _controller.stream;
  }

  void setUser(AuthUserInfo? user) {
    _user = user;
    _controller.add(user);
    notifyListeners();
  }

  @override
  Future<AuthUserInfo?> signInWithGoogle() async {
    _lastError = null;
    if (!ready) {
      _lastError = 'firebase_unavailable';
      notifyListeners();
      throw StateError('Firebase is not initialized');
    }
    final user = const AuthUserInfo(
      uid: 'fake-uid-1',
      email: 'tester@example.com',
      displayName: 'Tester',
    );
    setUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _lastError = null;
    setUser(null);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
