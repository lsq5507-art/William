enum OpsFunnelRail { none, formal, simulated }

class OpsFunnelStep {
  final String id;
  final String eventName;
  final String denomDef;
  final String numerDef;
  final String window;
  final String source;
  final String note;
  final OpsFunnelRail rail;
  final bool pendingDictionary;

  const OpsFunnelStep({
    required this.id,
    required this.eventName,
    required this.denomDef,
    required this.numerDef,
    this.window = '近7日',
    this.source = 'BQ',
    required this.note,
    this.rail = OpsFunnelRail.none,
    this.pendingDictionary = false,
  });
}

/// Hard-locked F0–F7b step definitions (P-21 §5.4 / D-21).
class OpsFunnelDefs {
  OpsFunnelDefs._();

  static const List<OpsFunnelStep> steps = [
    OpsFunnelStep(
      id: 'F0',
      eventName: 'app_open',
      denomDef: '进入漏斗观察窗的会话/打开',
      numerDef: '触发 app_open',
      note: '漏斗起点',
    ),
    OpsFunnelStep(
      id: 'F1',
      eventName: 'seo_* / 待确认',
      denomDef: 'F0',
      numerDef: '落地 CTA（若可分）',
      note: '待工程确认事件字典',
      pendingDictionary: true,
    ),
    OpsFunnelStep(
      id: 'F2a',
      eventName: 'auth_guest',
      denomDef: 'F0',
      numerDef: 'Guest 可玩',
      note: '与 F2b 分列，勿混加总报激活率',
    ),
    OpsFunnelStep(
      id: 'F2b',
      eventName: 'auth_sign_in_result(success=true)',
      denomDef: 'F0',
      numerDef: '登录成功',
      note: '与 F2a 分列',
    ),
    OpsFunnelStep(
      id: 'F3',
      eventName: 'story_impression_complete',
      denomDef: 'F0',
      numerDef: '≥1 次完整 impress（排除 demo fill）',
      note: '故事曝光',
    ),
    OpsFunnelStep(
      id: 'F4',
      eventName: 'feed_view',
      denomDef: 'F0',
      numerDef: '进入宠圈可见',
      note: '',
    ),
    OpsFunnelStep(
      id: 'F5',
      eventName: 'custom_media_posted',
      denomDef: 'F0',
      numerDef: '选图发帖成功',
      note: '',
    ),
    OpsFunnelStep(
      id: 'F6',
      eventName: 'chat_message_sent',
      denomDef: 'F0',
      numerDef: '聊天发送成功',
      note: '',
    ),
    OpsFunnelStep(
      id: 'F7a',
      eventName: 'pay_intent_choice (is_simulated_commerce=false)',
      denomDef: 'F0',
      numerDef: '正式付费意愿',
      note: '正式轨 · 不作已付费',
      rail: OpsFunnelRail.formal,
    ),
    OpsFunnelStep(
      id: 'F7b',
      eventName: 'simulate_purchase_* (is_simulated_commerce=true)',
      denomDef: 'F0',
      numerDef: '模拟购',
      note: '模拟轨 · ≠正式付费',
      rail: OpsFunnelRail.simulated,
    ),
  ];
}
