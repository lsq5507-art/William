import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'ops_allowlist.dart';

class OpsUserRow {
  final String uid;
  final String? email;
  final String? displayName;
  final List<String> providers;
  final String? createdAt;
  final String? lastSignInAt;
  final bool hasCloudState;
  final String? stateUpdatedAt;

  const OpsUserRow({
    required this.uid,
    this.email,
    this.displayName,
    this.providers = const [],
    this.createdAt,
    this.lastSignInAt,
    this.hasCloudState = false,
    this.stateUpdatedAt,
  });
}

class OpsOverviewStats {
  final int? authUserCount;
  final int? cloudStateCount;
  /// BQ-dependent cards: null means pending/blocked.
  final bool bqPending;

  const OpsOverviewStats({
    this.authUserCount,
    this.cloudStateCount,
    this.bqPending = true,
  });
}

/// Abstraction so widget tests need no Firestore.
abstract class OpsRepository {
  Future<List<String>> fetchAllowlistEmails();
  Future<OpsOverviewStats> fetchOverview();
  Future<List<OpsUserRow>> fetchUsers();
}

class OpsRepositoryStub implements OpsRepository {
  OpsRepositoryStub({
    this.emails = const [],
    this.stats = const OpsOverviewStats(
      authUserCount: 0,
      cloudStateCount: 0,
      bqPending: true,
    ),
    this.rows = const [],
  });

  const OpsRepositoryStub.empty()
      : emails = const [],
        stats = const OpsOverviewStats(
          authUserCount: 0,
          cloudStateCount: 0,
          bqPending: true,
        ),
        rows = const [];

  final List<String> emails;
  final OpsOverviewStats stats;
  final List<OpsUserRow> rows;

  @override
  Future<List<String>> fetchAllowlistEmails() async => emails;

  @override
  Future<OpsOverviewStats> fetchOverview() async => stats;

  @override
  Future<List<OpsUserRow>> fetchUsers() async => rows;
}

class FirestoreOpsRepository implements OpsRepository {
  FirestoreOpsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<String>> fetchAllowlistEmails() async {
    try {
      final snap = await _db.collection('ops').doc('allowlist').get();
      if (!snap.exists) return const [];
      final raw = snap.data()?['emails'];
      if (raw is! List) return const [];
      return raw.map((e) => '$e'.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
    } catch (e) {
      debugPrint('OpsAllowlist fetch failed: $e');
      return const [];
    }
  }

  @override
  Future<OpsOverviewStats> fetchOverview() async {
    final users = await fetchUsers();
    final cloud = users.where((u) => u.hasCloudState).length;
    return OpsOverviewStats(
      authUserCount: users.length,
      cloudStateCount: cloud,
      bqPending: true, // BQ not linked
    );
  }

  @override
  Future<List<OpsUserRow>> fetchUsers() async {
    final out = <OpsUserRow>[];
    final snap = await _db.collection('users').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      var hasState = false;
      String? stateUpdatedAt;
      try {
        final state = await doc.reference.collection('state').doc('current').get();
        hasState = state.exists;
        if (state.exists) {
          final rawAt = '${state.data()?['updatedAt'] ?? ''}';
          stateUpdatedAt = rawAt.isEmpty ? null : rawAt;
        }
      } catch (e) {
        debugPrint('ops state read ${doc.id}: $e');
      }
      final providersRaw = data['providers'];
      final providers = providersRaw is List
          ? providersRaw.map((e) => '$e').toList()
          : const <String>[];
      out.add(
        OpsUserRow(
          uid: doc.id,
          email: data['email'] as String?,
          displayName: data['displayName'] as String?,
          providers: providers,
          createdAt: data['createdAt'] as String?,
          lastSignInAt: data['lastSignInAt'] as String?,
          hasCloudState: hasState,
          stateUpdatedAt: stateUpdatedAt,
        ),
      );
    }
    return out;
  }

  /// Login-time Auth metadata mirror onto `users/{uid}` (no Admin SDK).
  static Future<void> mirrorAuthProfile({
    required FirebaseFirestore db,
    required String uid,
    required String? email,
    required String? displayName,
    required List<String> providers,
    required String? createdAt,
    required String? lastSignInAt,
  }) async {
    await db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'providers': providers,
      'createdAt': createdAt,
      'lastSignInAt': lastSignInAt,
      'mirroredAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  static bool resolveAllowlisted(String? email, List<String> remote) =>
      OpsAllowlist.isAllowlisted(email, firestoreEmails: remote);
}
