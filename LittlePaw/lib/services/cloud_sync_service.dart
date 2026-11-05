import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'space_store.dart';

/// Which side wins a local↔cloud merge, and whether to write back.
enum SyncWinner { local, cloud }

class SyncDecision {
  final SyncWinner winner;
  final Map<String, dynamic> state;
  final bool shouldPush;

  const SyncDecision({
    required this.winner,
    required this.state,
    required this.shouldPush,
  });
}

/// Pure merge by `updatedAt` (ISO8601 or epoch ms). No I/O — unit-testable.
///
/// Rules (product):
/// - No cloud doc → local wins, push
/// - Cloud missing `updatedAt` → local overwrites cloud, push
/// - Else compare timestamps; newer wins; if local wins, push
/// - Equal `updatedAt` → **cloud wins** (local must be strictly after cloud)
class StateSyncMerger {
  static DateTime? parseUpdatedAt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) {
      // Heuristic: ms vs seconds
      if (raw > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    }
    if (raw is num) {
      return parseUpdatedAt(raw.toInt());
    }
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      final asInt = int.tryParse(s);
      if (asInt != null) return parseUpdatedAt(asInt);
      return DateTime.tryParse(s)?.toUtc();
    }
    return null;
  }

  /// [cloudDoc] is the Firestore document map with `payload` + `updatedAt`,
  /// or a legacy flat state map that already contains space fields + updatedAt.
  static SyncDecision decide({
    required Map<String, dynamic> local,
    Map<String, dynamic>? cloudDoc,
  }) {
    if (cloudDoc == null) {
      return SyncDecision(
        winner: SyncWinner.local,
        state: Map<String, dynamic>.from(local),
        shouldPush: true,
      );
    }

    final cloudState = _extractPayload(cloudDoc);
    final cloudAt = parseUpdatedAt(cloudDoc['updatedAt']) ??
        parseUpdatedAt(cloudState['updatedAt']);

    // No usable cloud timestamp → local overwrites cloud.
    if (cloudAt == null) {
      return SyncDecision(
        winner: SyncWinner.local,
        state: Map<String, dynamic>.from(local),
        shouldPush: true,
      );
    }

    final localAt = parseUpdatedAt(local['updatedAt']);
    if (localAt == null || !localAt.isAfter(cloudAt)) {
      // Cloud newer or equal (or local missing updatedAt) → prefer cloud.
      return SyncDecision(
        winner: SyncWinner.cloud,
        state: Map<String, dynamic>.from(cloudState),
        shouldPush: false,
      );
    }

    return SyncDecision(
      winner: SyncWinner.local,
      state: Map<String, dynamic>.from(local),
      shouldPush: true,
    );
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> doc) {
    final p = doc['payload'];
    if (p is Map) {
      final m = Map<String, dynamic>.from(p);
      // Prefer top-level updatedAt if payload lacks it.
      m['updatedAt'] ??= doc['updatedAt'];
      return m;
    }
    // Flat document: treat whole doc as state (minus wrapper-only keys).
    final m = Map<String, dynamic>.from(doc);
    return m;
  }

  static Map<String, dynamic> wrapForCloud(Map<String, dynamic> state) {
    final updatedAt = state['updatedAt'] ?? DateTime.now().toUtc().toIso8601String();
    return {
      'payload': state,
      'updatedAt': updatedAt,
    };
  }
}

/// Firestore I/O around [StateSyncMerger]. Injectable for tests via [backend].
abstract class CloudSyncBackend {
  Future<Map<String, dynamic>?> pull(String uid);
  Future<void> push(String uid, Map<String, dynamic> wrappedDoc);
}

class FirestoreCloudBackend implements CloudSyncBackend {
  FirestoreCloudBackend({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('state').doc('current');

  @override
  Future<Map<String, dynamic>?> pull(String uid) async {
    final snap = await _ref(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  @override
  Future<void> push(String uid, Map<String, dynamic> wrappedDoc) async {
    await _ref(uid).set(wrappedDoc, SetOptions(merge: true));
  }
}

class MemoryCloudBackend implements CloudSyncBackend {
  final Map<String, Map<String, dynamic>> docs = {};

  @override
  Future<Map<String, dynamic>?> pull(String uid) async =>
      docs[uid] == null ? null : Map<String, dynamic>.from(docs[uid]!);

  @override
  Future<void> push(String uid, Map<String, dynamic> wrappedDoc) async {
    docs[uid] = Map<String, dynamic>.from(wrappedDoc);
  }
}

class CloudSyncService {
  CloudSyncService({
    this.backend,
    this.enabled = true,
  });

  CloudSyncBackend? backend;
  bool enabled;
  String? lastError;

  /// Inflight + session latch so Profile sign-in and authStateChanges
  /// do not double-run [syncOnLogin] for the same uid.
  Future<SyncDecision?>? _inflightLoginSync;
  String? _inflightLoginUid;
  String? _loginSyncedUid;

  bool get isConfigured => enabled && backend != null;

  void attachBackend(CloudSyncBackend b) {
    backend = b;
  }

  /// Clear login-sync latch (call on sign-out so next login syncs again).
  void resetLoginSyncLatch() {
    _loginSyncedUid = null;
    // Do not cancel inflight; just allow a fresh sync after it finishes.
  }

  /// Login merge: prefer newer `updatedAt`; missing cloud/updatedAt → push local.
  /// Concurrent/duplicate calls for the same [uid] share one inflight future;
  /// a second call after success is a no-op until [resetLoginSyncLatch].
  Future<SyncDecision?> syncOnLogin(SpaceStore store, String uid) {
    lastError = null;
    if (!isConfigured) return Future<SyncDecision?>.value(null);

    if (_loginSyncedUid == uid && _inflightLoginSync == null) {
      return Future<SyncDecision?>.value(null);
    }
    if (_inflightLoginSync != null && _inflightLoginUid == uid) {
      return _inflightLoginSync!;
    }

    _inflightLoginUid = uid;
    final fut = _syncOnLoginBody(store, uid);
    _inflightLoginSync = fut;
    fut.whenComplete(() {
      if (identical(_inflightLoginSync, fut)) {
        _inflightLoginSync = null;
        _inflightLoginUid = null;
      }
    });
    return fut;
  }

  Future<SyncDecision?> _syncOnLoginBody(SpaceStore store, String uid) async {
    try {
      final local = store.exportStateJson();
      final cloud = await backend!.pull(uid);
      final decision = StateSyncMerger.decide(local: local, cloudDoc: cloud);
      if (decision.winner == SyncWinner.cloud) {
        await store.importStateJson(decision.state);
      }
      if (decision.shouldPush) {
        final toPush = decision.winner == SyncWinner.local
            ? store.exportStateJson()
            : decision.state;
        await backend!.push(uid, StateSyncMerger.wrapForCloud(toPush));
      }
      _loginSyncedUid = uid;
      return decision;
    } catch (e, st) {
      lastError = e.toString();
      debugPrint('CloudSyncService.syncOnLogin failed: $e\n$st');
      rethrow;
    }
  }

  /// Upsert current local state (after persist while signed in).
  Future<void> pushLocal(SpaceStore store, String uid) async {
    lastError = null;
    if (!isConfigured) return;
    try {
      final state = store.exportStateJson();
      await backend!.push(uid, StateSyncMerger.wrapForCloud(state));
    } catch (e, st) {
      lastError = e.toString();
      debugPrint('CloudSyncService.pushLocal failed: $e\n$st');
      rethrow;
    }
  }
}
