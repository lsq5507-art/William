/// Ops-admin train constants (isolated from user-side stamps).
class OpsConstants {
  OpsConstants._();

  /// Shell build chip — Must X4 / D-21.
  static const String buildChip = 'ops-admin-funnel-web-v0.21';

  /// Analytics→BigQuery export readiness.
  /// Fact 2026-11-05: Billing=No, not Linked → funnel Must Blocked.
  static const bool bqExportEnabled = false;

  static const String usersFootnote =
      'Auth 用户 ≠ 全部打开过 App 的人（纯本机 Guest 可能无 Auth 行）';

  static const String overviewFootnote =
      '模拟 ≠ 正式付费。本页无「已收款」指标。数值以查询当时为准。';
}
