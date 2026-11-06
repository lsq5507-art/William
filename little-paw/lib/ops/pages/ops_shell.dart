import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../ops_constants.dart';
import '../ops_path.dart';
import '../ops_theme.dart';
import 'ops_deny_page.dart';

class OpsShell extends StatelessWidget {
  const OpsShell({
    super.key,
    required this.initialTab,
    this.onTab,
    this.child,
    this.overview,
  });

  final OpsTab initialTab;
  final ValueChanged<OpsTab>? onTab;
  final Widget? child;
  final Widget? overview;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final body = child ?? overview ?? const SizedBox.shrink();
    final tab = initialTab;

    Widget navItem(OpsTab t, String label) {
      final selected = tab == t;
      return InkWell(
        onTap: onTab == null ? null : () => onTab!(t),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: selected ? OpsTheme.chip : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? OpsTheme.navy : OpsTheme.muted,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OpsTheme.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 210,
            decoration: const BoxDecoration(
              color: OpsTheme.surface,
              border: Border(right: BorderSide(color: OpsTheme.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Little Paw Ops',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: OpsTheme.ink,
                    ),
                  ),
                ),
                const Divider(height: 1, color: OpsTheme.line),
                navItem(OpsTab.overview, '概览'),
                navItem(OpsTab.users, '用户'),
                navItem(OpsTab.funnel, '漏斗'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    key: const Key('ops.build.chip'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: OpsTheme.chip,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      OpsConstants.buildChip,
                      style: TextStyle(
                        fontSize: 11,
                        color: OpsTheme.muted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    OpsDenyPage.maskEmail(auth.currentUser?.email),
                    style: const TextStyle(fontSize: 12, color: OpsTheme.muted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: TextButton(
                    onPressed: () => context.read<AuthService>().signOut(),
                    child: const Text('退出', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
