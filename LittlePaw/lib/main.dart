import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/event_log.dart';
import 'services/seo_web_dom.dart';
import 'services/seo_web_gate.dart';
import 'services/firebase_analytics_bridge.dart';
import 'services/cloud_sync_service.dart';
import 'services/local_media_store.dart';
import 'services/space_store.dart';
import 'world/world_store.dart';

/// True when Firebase.initializeApp succeeded. Tests may inject services.
@visibleForTesting
bool firebaseInitialized = false;

Future<bool> initializeFirebaseApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    return true;
  } catch (e, st) {
    firebaseInitialized = false;
    debugPrint('Firebase.initializeApp failed (degraded guest mode): $e\n$st');
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  seoBindHostname();
  final ready = await initializeFirebaseApp();

  final store = SpaceStore();
  await store.load();
  await LocalMediaStore.instance.load();
  // LP-DEV-13: Analytics dual-write (kill via EventLog.analyticsEnabled).
  if (ready) {
    store.eventLog.analyticsSink = FirebaseAnalyticsBridge();
    store.eventLog.analyticsEnabled = kAnalyticsDualWriteEnabled;
  }
  await store.onAppOpen();

  // LP-DEV-16: marketing shell vs app entry (web DOM + EventLog).
  SeoWebGate.applyEntry(
    seoCurrentUri(),
    eventLog: store.eventLog,
    hideLandingShell: seoHideLandingShell,
    setNoIndex: seoSetDocumentNoIndex,
  );

  final AuthService auth =
      FirebaseAuthService(firebaseReady: ready);
  final sync = CloudSyncService(
    backend: ready ? FirestoreCloudBackend() : null,
    enabled: ready,
  );

  void wireCloudPush() {
    final user = auth.currentUser;
    if (user == null || !sync.isConfigured) {
      store.onAfterPersist = null;
      return;
    }
    final uid = user.uid;
    store.onAfterPersist = (_) => sync.pushLocal(store, uid);
  }

  auth.authStateChanges.listen((user) async {
    if (user == null) {
      store.onAfterPersist = null;
      sync.resetLoginSyncLatch();
      return;
    }
    try {
      await sync.syncOnLogin(store, user.uid);
    } catch (e) {
      debugPrint('syncOnLogin error: $e');
    }
    wireCloudPush();
  });

  // If already signed in from a prior session.
  if (auth.currentUser != null) {
    try {
      await sync.syncOnLogin(store, auth.currentUser!.uid);
    } catch (e) {
      debugPrint('initial syncOnLogin error: $e');
    }
    wireCloudPush();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider(create: (_) => WorldStore()),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<CloudSyncService>.value(value: sync),
      ],
      child: const LittlePawApp(),
    ),
  );
}
