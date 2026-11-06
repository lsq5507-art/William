import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_paw/services/cloud_sync_service.dart';
import 'package:little_paw/services/space_store.dart';

void main() {
  group('StateSyncMerger', () {
    test('no cloud → local wins and should push', () {
      final local = {
        'localeZh': true,
        'updatedAt': '2026-11-03T10:00:00.000Z',
      };
      final d = StateSyncMerger.decide(local: local, cloudDoc: null);
      expect(d.winner, SyncWinner.local);
      expect(d.shouldPush, isTrue);
      expect(d.state['localeZh'], true);
    });

    test('cloud newer than local → cloud wins', () {
      final local = {
        'localeZh': true,
        'updatedAt': '2026-11-03T10:00:00.000Z',
      };
      final cloud = {
        'updatedAt': '2026-11-03T12:00:00.000Z',
        'payload': {
          'localeZh': false,
          'updatedAt': '2026-11-03T12:00:00.000Z',
        },
      };
      final d = StateSyncMerger.decide(local: local, cloudDoc: cloud);
      expect(d.winner, SyncWinner.cloud);
      expect(d.shouldPush, isFalse);
      expect(d.state['localeZh'], false);
    });

    test('local newer than cloud → local wins and push', () {
      final local = {
        'localeZh': true,
        'updatedAt': '2026-11-03T14:00:00.000Z',
      };
      final cloud = {
        'updatedAt': '2026-11-03T12:00:00.000Z',
        'payload': {
          'localeZh': false,
          'updatedAt': '2026-11-03T12:00:00.000Z',
        },
      };
      final d = StateSyncMerger.decide(local: local, cloudDoc: cloud);
      expect(d.winner, SyncWinner.local);
      expect(d.shouldPush, isTrue);
    });

    test('equal updatedAt → cloud wins (strictly-after local required)', () {
      const stamp = '2026-11-03T12:00:00.000Z';
      final local = {
        'localeZh': true,
        'updatedAt': stamp,
      };
      final cloud = {
        'updatedAt': stamp,
        'payload': {
          'localeZh': false,
          'updatedAt': stamp,
        },
      };
      final d = StateSyncMerger.decide(local: local, cloudDoc: cloud);
      expect(d.winner, SyncWinner.cloud);
      expect(d.shouldPush, isFalse);
      expect(d.state['localeZh'], false);
    });

    test('cloud without updatedAt → local overwrites', () {
      final local = {
        'localeZh': true,
        'updatedAt': '2026-11-03T14:00:00.000Z',
      };
      final cloud = {
        'payload': {'localeZh': false},
      };
      final d = StateSyncMerger.decide(local: local, cloudDoc: cloud);
      expect(d.winner, SyncWinner.local);
      expect(d.shouldPush, isTrue);
    });

    test('parseUpdatedAt supports ms epoch', () {
      final ms = DateTime.utc(2026, 11, 3, 8).millisecondsSinceEpoch;
      final dt = StateSyncMerger.parseUpdatedAt(ms);
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
    });
  });

  group('CloudSyncService with MemoryCloudBackend', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('syncOnLogin with no cloud pushes local', () async {
      final store = SpaceStore();
      await store.load();
      store.localeZh = false;
      await store.persist();

      final backend = MemoryCloudBackend();
      final sync = CloudSyncService(backend: backend);
      final decision = await sync.syncOnLogin(store, 'u1');
      expect(decision?.winner, SyncWinner.local);
      expect(backend.docs['u1'], isNotNull);
      expect(backend.docs['u1']!['payload'], isA<Map>());
      expect(backend.docs['u1']!['updatedAt'], isNotNull);
    });

    test('syncOnLogin applies newer cloud into store', () async {
      final store = SpaceStore();
      await store.load();
      store.localeZh = true;
      await store.persist();
      // Force older local stamp (do not save() — that re-touches updatedAt)
      store.updatedAt = '2026-11-01T00:00:00.000Z';

      final backend = MemoryCloudBackend();
      backend.docs['u1'] = {
        'updatedAt': '2026-11-03T00:00:00.000Z',
        'payload': {
          'localeZh': false,
          'welcomeSeen': true,
          'onboardingComplete': false,
          'stories': [],
          'comments': [],
          'economy': {},
          'events': [],
          'updatedAt': '2026-11-03T00:00:00.000Z',
        },
      };
      final sync = CloudSyncService(backend: backend);
      final decision = await sync.syncOnLogin(store, 'u1');
      expect(decision?.winner, SyncWinner.cloud);
      expect(store.localeZh, isFalse);
      expect(store.welcomeSeen, isTrue);
    });
  });

  group('SpaceStore export/import updatedAt', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persist refreshes updatedAt', () async {
      final store = SpaceStore();
      await store.load();
      expect(store.updatedAt, isNull);
      await store.persist();
      expect(store.updatedAt, isNotNull);
      final exported = store.exportStateJson(touch: false);
      expect(exported['updatedAt'], store.updatedAt);
    });

    test('exportStateJson touches when updatedAt is null', () async {
      final store = SpaceStore();
      await store.load();
      expect(store.updatedAt, isNull);
      final exported = store.exportStateJson(touch: false);
      expect(exported['updatedAt'], isNotNull);
      expect(store.updatedAt, isNotNull);
      expect(exported['updatedAt'], store.updatedAt);
    });

    test('exportStateJson does not retouch existing stamp when touch=false', () async {
      final store = SpaceStore();
      await store.load();
      store.updatedAt = '2026-01-01T00:00:00.000Z';
      final exported = store.exportStateJson(touch: false);
      expect(exported['updatedAt'], '2026-01-01T00:00:00.000Z');
    });

    test('importStateJson round-trip', () async {
      final store = SpaceStore();
      await store.load();
      store.welcomeSeen = true;
      store.localeZh = false;
      await store.persist();
      final snap = store.exportStateJson(touch: false);

      final other = SpaceStore();
      await other.load();
      await other.importStateJson(snap);
      expect(other.welcomeSeen, isTrue);
      expect(other.localeZh, isFalse);
      expect(other.updatedAt, snap['updatedAt']);
    });
  });

  group('syncOnLogin latch', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('concurrent syncOnLogin same uid shares one pull', () async {
      final store = SpaceStore();
      await store.load();
      await store.persist();

      final backend = _CountingBackend();
      final sync = CloudSyncService(backend: backend);

      final a = sync.syncOnLogin(store, 'u-latch');
      final b = sync.syncOnLogin(store, 'u-latch');
      final ra = await a;
      final rb = await b;
      expect(identical(ra, rb) || (ra?.winner == rb?.winner), isTrue);
      expect(backend.pullCount, 1);
      expect(backend.pushCount, 1);

      // Session dedupe: second wave is no-op
      final c = await sync.syncOnLogin(store, 'u-latch');
      expect(c, isNull);
      expect(backend.pullCount, 1);

      sync.resetLoginSyncLatch();
      final d = await sync.syncOnLogin(store, 'u-latch');
      expect(d, isNotNull);
      expect(backend.pullCount, 2);
    });
  });
}

class _CountingBackend implements CloudSyncBackend {
  final MemoryCloudBackend _inner = MemoryCloudBackend();
  int pullCount = 0;
  int pushCount = 0;

  @override
  Future<Map<String, dynamic>?> pull(String uid) async {
    pullCount++;
    // Yield so concurrent callers can join inflight.
    await Future<void>.delayed(Duration.zero);
    return _inner.pull(uid);
  }

  @override
  Future<void> push(String uid, Map<String, dynamic> wrappedDoc) async {
    pushCount++;
    await _inner.push(uid, wrappedDoc);
  }
}
