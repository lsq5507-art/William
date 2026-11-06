import 'package:flutter/material.dart';

import '../ops_constants.dart';
import '../ops_repository.dart';
import '../ops_theme.dart';

class OpsOverviewPage extends StatelessWidget {
  const OpsOverviewPage({
    super.key,
    required this.stats,
    required this.loading,
    this.error,
    this.onRetry,
  });

  final OpsOverviewStats? stats;
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
            '概览',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: OpsTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            OpsConstants.overviewFootnote,
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
          Wrap(
            key: const Key('ops.overview.cards'),
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: 'Auth 用户数',
                value: loading
                    ? '…'
                    : (stats?.authUserCount?.toString() ?? '—'),
                subtitle: 'users 集合近似（≠全部 Guest）',
              ),
              _StatCard(
                title: '有云状态',
                value: loading
                    ? '…'
                    : (stats?.cloudStateCount?.toString() ?? '—'),
                subtitle: '存在 state/current',
              ),
              const _StatCard(
                title: '近 7 日 app_open',
                value: '待开通',
                subtitle: '依赖 BigQuery',
                pending: true,
              ),
              const _StatCard(
                title: '正式付费意愿',
                value: '待开通',
                subtitle: '正式轨 · 近7日 · BQ',
                rail: _Rail.formal,
                pending: true,
              ),
              const _StatCard(
                title: '模拟购',
                value: '待开通',
                subtitle: '模拟轨 · 近7日 · BQ',
                rail: _Rail.sim,
                pending: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Rail { none, formal, sim }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.rail = _Rail.none,
    this.pending = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final _Rail rail;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    Color? bar;
    if (rail == _Rail.formal) bar = OpsTheme.railFormal;
    if (rail == _Rail.sim) bar = OpsTheme.railSim;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OpsTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: OpsTheme.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bar != null)
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: 12),
                color: bar,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: OpsTheme.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: pending ? OpsTheme.warn : OpsTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: OpsTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
