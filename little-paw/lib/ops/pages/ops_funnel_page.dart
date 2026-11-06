import 'package:flutter/material.dart';

import '../ops_constants.dart';
import '../ops_funnel_defs.dart';
import '../ops_theme.dart';

class OpsFunnelPage extends StatelessWidget {
  const OpsFunnelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = !OpsConstants.bqExportEnabled;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '行为漏斗',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OpsTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (blocked) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: OpsTheme.line),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColoredBox(
                    color: OpsTheme.warn,
                    child: SizedBox(width: 3, height: 120),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: OpsTheme.warn, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '待开通 · BigQuery',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: OpsTheme.ink,
                                ),
                              ),
                              SizedBox(width: 10),
                              _BlockedBadge(),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '行为漏斗依赖 Analytics → BigQuery 导出。当前未开通或不可读（Billing=No、未 Link），本区不展示假数据。',
                            style: TextStyle(
                                fontSize: 13, color: OpsTheme.muted, height: 1.4),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '已就绪：鉴权 / 用户表 / 非 BQ 汇总　·　未就绪：漏斗分子分母',
                            style: TextStyle(fontSize: 12, color: OpsTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  key: const Key('ops.funnel.table'),
                  headingRowHeight: 40,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('步骤')),
                    DataColumn(label: Text('事件名')),
                    DataColumn(label: Text('分母')),
                    DataColumn(label: Text('分子')),
                    DataColumn(label: Text('分母 n')),
                    DataColumn(label: Text('分子 n')),
                    DataColumn(label: Text('窗')),
                    DataColumn(label: Text('源')),
                    DataColumn(label: Text('备注')),
                  ],
                  rows: [
                    for (final s in OpsFunnelDefs.steps)
                      DataRow(
                        cells: [
                          DataCell(_StepCell(step: s)),
                          DataCell(Text(s.eventName)),
                          DataCell(Text(s.denomDef)),
                          DataCell(Text(s.numerDef)),
                          const DataCell(Text('—')),
                          const DataCell(Text('—')),
                          DataCell(Text(s.window)),
                          DataCell(Text(blocked ? 'BQ·待开通' : s.source)),
                          DataCell(Text(
                            s.pendingDictionary
                                ? '待工程确认事件字典'
                                : s.note,
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1CC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OpsTheme.warn.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'Blocked',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: OpsTheme.warn,
        ),
      ),
    );
  }
}

class _StepCell extends StatelessWidget {
  const _StepCell({required this.step});
  final OpsFunnelStep step;

  @override
  Widget build(BuildContext context) {
    Color? bar;
    if (step.rail == OpsFunnelRail.formal) bar = OpsTheme.railFormal;
    if (step.rail == OpsFunnelRail.simulated) bar = OpsTheme.railSim;
    return Row(
      children: [
        if (bar != null)
          Container(
            width: 3,
            height: 18,
            margin: const EdgeInsets.only(right: 8),
            color: bar,
          ),
        Text(step.id, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
