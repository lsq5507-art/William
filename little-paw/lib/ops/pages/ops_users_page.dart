import 'package:flutter/material.dart';

import '../ops_constants.dart';
import '../ops_repository.dart';
import '../ops_theme.dart';
import 'ops_deny_page.dart';

class OpsUsersPage extends StatelessWidget {
  const OpsUsersPage({
    super.key,
    required this.rows,
    required this.loading,
    this.error,
    this.onRetry,
  });

  final List<OpsUserRow> rows;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '用户',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OpsTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            OpsConstants.usersFootnote,
            style: TextStyle(fontSize: 12, color: OpsTheme.muted),
          ),
          const SizedBox(height: 16),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '加载失败：$error',
                      style: const TextStyle(color: OpsTheme.deny, fontSize: 13),
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: const Text('重试')),
                ],
              ),
            ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            const Text(
              '暂无 Auth 用户镜像（登录后会写入 users/{uid} profile）',
              style: TextStyle(color: OpsTheme.muted, fontSize: 13),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    key: const Key('ops.users.table'),
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(label: Text('uid')),
                      DataColumn(label: Text('email')),
                      DataColumn(label: Text('displayName')),
                      DataColumn(label: Text('providers')),
                      DataColumn(label: Text('createdAt')),
                      DataColumn(label: Text('lastSignInAt')),
                      DataColumn(label: Text('云状态')),
                      DataColumn(label: Text('stateUpdatedAt')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(
                          cells: [
                            DataCell(Text(_short(r.uid))),
                            DataCell(Text(OpsDenyPage.maskEmail(r.email))),
                            DataCell(Text(r.displayName ?? '—')),
                            DataCell(Text(
                              r.providers.isEmpty ? '—' : r.providers.join(','),
                            )),
                            DataCell(Text(r.createdAt ?? '—')),
                            DataCell(Text(r.lastSignInAt ?? '—')),
                            DataCell(Text(r.hasCloudState ? '是' : '否')),
                            DataCell(Text(r.stateUpdatedAt ?? '—')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '※ Auth 用户 ≠ 全部 Guest 打开过 App 的人',
            style: TextStyle(fontSize: 12, color: OpsTheme.muted),
          ),
        ],
      ),
    );
  }

  static String _short(String uid) {
    if (uid.length <= 12) return uid;
    return '${uid.substring(0, 8)}…';
  }
}
