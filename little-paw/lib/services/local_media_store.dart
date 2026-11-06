import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistent local image bytes for Feed posts (LP-P-08).
/// Scheme: `localmedia://<id>` — never a temporary blob URL.
class LocalMediaStore {
  LocalMediaStore._();
  static final LocalMediaStore instance = LocalMediaStore._();

  static const prefsKey = 'little_paw_local_media_v1';
  static const scheme = 'localmedia://';
  static const maxBytes = 4 * 1024 * 1024; // 4 MiB soft cap

  final Map<String, Uint8List> _cache = {};
  bool _loaded = false;

  static bool isLocalMediaUrl(String? url) =>
      url != null && url.startsWith(scheme);

  static String? idFromUrl(String? url) {
    if (!isLocalMediaUrl(url)) return null;
    final id = url!.substring(scheme.length).trim();
    return id.isEmpty ? null : id;
  }

  static String urlForId(String id) => '$scheme$id';

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    _cache.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          final b64 = e.value?.toString();
          if (b64 == null || b64.isEmpty) continue;
          _cache[e.key] = Uint8List.fromList(base64Decode(b64));
        }
      } catch (_) {
        // Keep empty cache on corrupt payload.
      }
    }
    _loaded = true;
  }

  Uint8List? bytesFor(String? url) {
    final id = idFromUrl(url);
    if (id == null) return null;
    return _cache[id];
  }

  Uint8List? bytesById(String id) => _cache[id];

  Future<String> putBytes(Uint8List bytes, {String? preferredId}) async {
    await load();
    if (bytes.lengthInBytes > maxBytes) {
      throw StateError('too_large');
    }
    final id = preferredId ??
        'm_${DateTime.now().millisecondsSinceEpoch}_${_cache.length}';
    _cache[id] = bytes;
    await _persist();
    return urlForId(id);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, String>{
      for (final e in _cache.entries) e.key: base64Encode(e.value),
    };
    await prefs.setString(prefsKey, jsonEncode(encoded));
  }

  /// Test helper: clear in-memory + disk.
  Future<void> clearForTest() async {
    _cache.clear();
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
