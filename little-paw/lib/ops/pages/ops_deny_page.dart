import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../ops_theme.dart';

/// 403 — zero table/card/skeleton leakage (D-21 SCR-21-DENY).
class OpsDenyPage extends StatelessWidget {
  const OpsDenyPage({super.key});

  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '—';
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) {
      return '${local[0]}***$domain';
    }
    return '${local[0]}***${local[local.length - 1]}$domain';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final email = auth.currentUser?.email;
    return Scaffold(
      backgroundColor: OpsTheme.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 40, color: OpsTheme.deny),
                const SizedBox(height: 16),
                const Text(
                  '无权访问',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: OpsTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '当前账号不在运营白名单中。你看不到任何用户、汇总或漏斗数据。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: OpsTheme.muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                Text(
                  '已登录：${maskEmail(email)}',
                  style: const TextStyle(fontSize: 13, color: OpsTheme.muted),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  key: const Key('ops.deny.logout'),
                  onPressed: () => context.read<AuthService>().signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OpsTheme.ink,
                    side: const BorderSide(color: OpsTheme.line),
                  ),
                  child: const Text('退出登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
