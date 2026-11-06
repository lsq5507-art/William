import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'ops/ops_path.dart';
import 'ops/ops_repository.dart';
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

/// Mirror Auth metadata onto `users/{uid}` for ops Users table (no Admin SDK).
Future<void> mirrorOpsAuthProfile() async {
  if (!firebaseInitialized) return;
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) return;
  try {
    await FirestoreOpsRepository.mirrorAuthProfile(
      db: FirebaseFirestore.instance,
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
      providers: u.providerData.map((p) => p.providerId).toList(),
      createdAt: u.metadata.creationTime?.toUtc().toIso8601String(),
      lastSignInAt: u.metadata.lastSignInTime?.toUtc().toIso8601String(),
    );
  } catch (e) {
    debugPrint('ops profile mirror failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
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

  final entryUri = seoCurrentUri();
  // LP-DEV-21: /ops is internal — hide marketing shell, noindex.
  if (OpsPath.isOpsPath(entryUri.path)) {
    seoHideLandingShell();
    seoSetDocumentNoIndex();
  } else {
    SeoWebGate.applyEntry(
      entryUri,
      eventLog: store.eventLog,
      hideLandingShell: seoHideLandingShell,
      setNoIndex: seoSetDocumentNoIndex,
    );
  }

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
    await mirrorOpsAuthProfile();
    wireCloudPush();
  });

  // If already signed in from a prior session.
  if (auth.currentUser != null) {
    try {
      await sync.syncOnLogin(store, auth.currentUser!.uid);
    } catch (e) {
      debugPrint('initial syncOnLogin error: $e');
    }
    await mirrorOpsAuthProfile();
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
