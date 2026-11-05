import 'role_gen_capabilities.dart';

class ImageGenResult {
  final bool ok;
  final bool unavailable;
  final String? errorMessage;
  final String? imageBytesOrPath;

  const ImageGenResult({
    required this.ok,
    this.unavailable = false,
    this.errorMessage,
    this.imageBytesOrPath,
  });
}

/// Fail-closed image generation. No fake images. No debit on failure.
class ImageGenService {
  static bool get isAvailable => RoleGenCapabilities.imageGenEnabled;

  /// When unavailable, never calls [onSuccessWouldDebit].
  static Future<ImageGenResult> generate({
    required String prompt,
    bool Function()? onSuccessWouldDebit,
  }) async {
    if (!isAvailable) {
      return const ImageGenResult(
        ok: false,
        unavailable: true,
        errorMessage: '暂不可用 · 能力未启用',
      );
    }
    // Reserved for a real Firebase AI / Gemini image path once authorized.
    // Must not debit before a usable image exists.
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return const ImageGenResult(
        ok: false,
        errorMessage: '请输入提示词',
      );
    }
    return const ImageGenResult(
      ok: false,
      unavailable: true,
      errorMessage: '暂不可用 · 能力未启用',
    );
  }
}
