import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../screens/custom_media_confirm_screen.dart';
import 'local_media_store.dart';
import 'space_store.dart';

/// Shared pick → validate → confirm → persist → Feed post (LP-P-08 / D-08).
class CustomMediaFlow {
  CustomMediaFlow._();

  static Future<void> start(BuildContext context) async {
    final store = context.read<SpaceStore>();
    if (!store.customMediaToFeedEnabled) return;
    final s = S(store.localeZh);
    final petName = store.pet?.name ?? 'Little Paw';

    // D-20 F2: never show post-quota wall while picker/confirm is open.
    store.armCustomMediaFlowInFlight();
    try {
      PlatformFile? file;
      try {
        file = await FilePicker.pickFile(type: FileType.image);
      } catch (_) {
        if (!context.mounted) return;
        await _showMessage(
          context,
          title: s.get('custom.permission.title'),
          body: s.get('custom.permission.body'),
          closeLabel: s.get('custom.permission.close'),
        );
        return;
      }

      if (!context.mounted) return;
      if (file == null) {
        // Cancel — no dirty post.
        return;
      }

      Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        if (!context.mounted) return;
        await _bad(context, s, 'custom.bad.corrupt');
        return;
      }

      if (!context.mounted) return;
      if (bytes.isEmpty) {
        await _bad(context, s, 'custom.bad.corrupt');
        return;
      }
      if (!_looksLikeImage(file.name, file.extension)) {
        await _bad(context, s, 'custom.bad.not_image');
        return;
      }
      if (bytes.lengthInBytes > LocalMediaStore.maxBytes) {
        await _bad(context, s, 'custom.bad.too_large');
        return;
      }
      final okDecode = await _canDecode(bytes);
      if (!context.mounted) return;
      if (!okDecode) {
        await _bad(context, s, 'custom.bad.corrupt');
        return;
      }

      final confirm = await Navigator.of(context)
          .push<CustomMediaConfirmResult>(
            MaterialPageRoute(
              builder: (_) =>
                  CustomMediaConfirmScreen(bytes: bytes, petName: petName),
            ),
          );
      if (!context.mounted) return;
      if (confirm == null || !confirm.dayConfirmed) {
        // Cancel confirm — no dirty post.
        return;
      }

      try {
        final url = await LocalMediaStore.instance.putBytes(confirm.bytes);
        final story = await store.addCustomMediaStory(
          imageUrl: url,
          caption: confirm.caption,
        );
        if (!context.mounted) return;
        if (story == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s.get('custom.post.fail'))));
          return;
        }
        store.requestFocusStory(story.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.get('custom.success.toast'))));
      } catch (e) {
        if (!context.mounted) return;
        final key = e.toString().contains('too_large')
            ? 'custom.bad.too_large'
            : 'custom.post.fail';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.get(key))));
      }
    } finally {
      store.clearCustomMediaFlowInFlight();
    }
  }

  static bool _looksLikeImage(String name, String? ext) {
    final e = (ext ?? '').toLowerCase();
    if (e.isNotEmpty) {
      return const {
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'heic',
        'bmp',
      }.contains(e);
    }
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  static Future<bool> _canDecode(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _bad(BuildContext context, S s, String key) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.get(key)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('retry'),
            child: Text(s.get('custom.bad.retry')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('close'),
            child: Text(s.get('custom.bad.close')),
          ),
        ],
      ),
    );
    if (action == 'retry' && context.mounted) {
      await start(context);
    }
  }

  static Future<void> _showMessage(
    BuildContext context, {
    required String title,
    String? body,
    required String closeLabel,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}
