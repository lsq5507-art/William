import 'dart:async';

import 'package:flutter/material.dart';

/// LP-D-20 SCR-20-SNACK — short dismissible coin reward toast.
/// Top-anchored by default so chat composer / story caption stay free.
class CoinRewardSnack {
  CoinRewardSnack._();

  static const Duration defaultAutoDismiss = Duration(milliseconds: 2500);
  static const Duration maxAutoDismiss = Duration(seconds: 3);
  static const double closeHitMin = 44;

  /// +N is a delta toast only — never a second balance surface.
  static const bool isDeltaOnly = true;

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    required String walletLabel,
    required VoidCallback onWallet,
    String closeSemanticLabel = '关闭',
    Duration? duration,
    bool topAnchor = true,
  }) {
    dismiss();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    var d = duration ?? defaultAutoDismiss;
    if (d > maxAutoDismiss) d = maxAutoDismiss;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final topPad = media.padding.top + 8;
        final bottomPad = media.padding.bottom + 8;
        return Positioned(
          left: 12,
          right: 12,
          top: topAnchor ? topPad : null,
          bottom: topAnchor ? null : bottomPad + 56,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              bottom: false,
              child: _CoinRewardSnackBar(
                message: message,
                walletLabel: walletLabel,
                closeSemanticLabel: closeSemanticLabel,
                onWallet: () {
                  dismiss();
                  onWallet();
                },
                onClose: dismiss,
              ),
            ),
          ),
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(d, () {
      if (_entry == entry) dismiss();
    });
  }
}

class _CoinRewardSnackBar extends StatelessWidget {
  final String message;
  final String walletLabel;
  final String closeSemanticLabel;
  final VoidCallback onWallet;
  final VoidCallback onClose;

  const _CoinRewardSnackBar({
    required this.message,
    required this.walletLabel,
    required this.closeSemanticLabel,
    required this.onWallet,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('coin_reward_snack'),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                key: const Key('coin_reward_snack.message'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const Key('coin_reward_snack.wallet'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  CoinRewardSnack.closeHitMin,
                  CoinRewardSnack.closeHitMin,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onWallet,
              child: Text(walletLabel),
            ),
            IconButton(
              key: const Key('coin_reward_snack.close'),
              tooltip: closeSemanticLabel,
              constraints: const BoxConstraints(
                minWidth: CoinRewardSnack.closeHitMin,
                minHeight: CoinRewardSnack.closeHitMin,
              ),
              padding: EdgeInsets.zero,
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
