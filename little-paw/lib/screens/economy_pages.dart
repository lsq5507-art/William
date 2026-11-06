import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/custom_media_flow.dart';
import '../services/economy.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import '../widgets/coin_reward_snack.dart';
import 'intent_sheet.dart';
import 'role_gen_pages.dart';
import '../services/role_gen_capabilities.dart';

String _zh(SpaceStore s, String zh, String en) => s.localeZh ? zh : en;

/// SCR-14-WALLET
class EconomyWalletPage extends StatefulWidget {
  const EconomyWalletPage({super.key});

  @override
  State<EconomyWalletPage> createState() => _EconomyWalletPageState();
}

class _EconomyWalletPageState extends State<EconomyWalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<SpaceStore>();
      store.eventLog.log(
        'coin_balance_view',
        props: {'balance': store.economy.coinBalance},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final e = store.economy;
    final tokens = context.lpTokens;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '金币钱包', 'Coin wallet'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${e.coinBalance}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _zh(
              store,
              '本机账本 · 模拟经济 · 非商店充值余额',
              'Local ledger · simulated · not store balance',
            ),
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          if (e.ledger.isEmpty)
            Text(
              _zh(store, '还没有流水 · 去签到或聊聊', 'No entries yet · check in or chat'),
              style: TextStyle(color: tokens.textSecondary),
            )
          else
            ...e.ledger.reversed.take(50).map((row) {
              final plus = row.type == 'credit';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${plus ? '+' : '−'}${row.amount}  ${_reasonLabel(store, row.reason)}',
                  style: TextStyle(
                    color: plus
                        ? const Color(0xFF2E7D4F)
                        : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  row.atIso,
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                ),
              );
            }),
        ],
      ),
    );
  }
}

String economyReasonLabel(bool zhLocale, String reason) {
  const zh = {
    'checkin': '每日签到',
    'task_chat': '今日任务·聊天',
    'task_story_impress': '今日任务·故事',
    'task_custom_media': '今日任务·放进圈子',
    'invite_inviter': '邀请奖励',
    'invite_invitee': '受邀奖励',
    'feedback_adopted': '反馈采纳',
    'chat': '聊天发送',
    'sub_grant': '会员开通赠币',
    'member_daily': '会员日赠币',
    'chat_refund': '聊天退回',
    'coin_cost_custom_character': '自定义角色',
    'coin_cost_image_gen': '生成图片',
  };
  const en = {
    'checkin': 'Daily check-in',
    'task_chat': 'Daily task · chat',
    'task_story_impress': 'Daily task · story',
    'task_custom_media': 'Daily task · circle post',
    'invite_inviter': 'Invite reward',
    'invite_invitee': 'Invitee reward',
    'feedback_adopted': 'Feedback adopted',
    'chat': 'Chat send',
    'sub_grant': 'Sub grant',
    'member_daily': 'Member daily',
    'chat_refund': 'Chat refund',
    'coin_cost_custom_character': 'Custom character',
    'coin_cost_image_gen': 'Image generation',
  };
  return zhLocale ? (zh[reason] ?? reason) : (en[reason] ?? reason);
}

String _reasonLabel(SpaceStore s, String reason) =>
    economyReasonLabel(s.localeZh, reason);

void showEconomyCoinToast(
  BuildContext context, {
  required SpaceStore store,
  required int amount,
  String? subtitle,
  String? labelZh,
  String? labelEn,
}) {
  // F1/F3: top-anchored CoinRewardSnack (≤2.5s + X); +N is delta only.
  final String body;
  if (labelZh != null || labelEn != null) {
    body = _zh(store, labelZh ?? labelEn!, labelEn ?? labelZh!);
  } else if (amount < 0) {
    body =
        _zh(store, '−${-amount} 金币', '−${-amount} coins') +
        (subtitle == null || subtitle.isEmpty
            ? ''
            : _zh(store, ' · $subtitle', ' · $subtitle'));
  } else {
    body =
        _zh(store, '+$amount 金币', '+$amount coins') +
        (subtitle == null || subtitle.isEmpty
            ? ''
            : _zh(store, ' · $subtitle', ' · $subtitle'));
  }
  CoinRewardSnack.show(
    context,
    message: body,
    walletLabel: _zh(store, '查看钱包', 'Wallet'),
    closeSemanticLabel: _zh(store, '关闭', 'Close'),
    topAnchor: true,
    onWallet: () {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const EconomyWalletPage()));
    },
  );
}

/// SCR-14-CHECKIN
class EconomyCheckinPage extends StatelessWidget {
  const EconomyCheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final e = store.economy;
    final tokens = context.lpTokens;
    final claimed = e.checkinClaimedToday;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '每日签到', 'Daily check-in'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _zh(
                store,
                '连续 ${e.checkinStreak} 天 · ${claimed ? "今日已领" : "今日未领"}',
                'Streak ${e.checkinStreak} · ${claimed ? "claimed" : "available"}',
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _zh(
                store,
                '第 7 日连签可得 ${Economy.coinCheckinStreak7} 金币',
                'Day-7 streak grants ${Economy.coinCheckinStreak7} coins',
              ),
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.ctaInverse,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(tokens.hitMin),
              ),
              onPressed: claimed
                  ? null
                  : () async {
                      final n = await store.claimCheckin();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n == null
                                ? _zh(store, '今日已签到', 'Already checked in')
                                : _zh(store, '+$n 金币已到账', '+$n coins credited'),
                          ),
                        ),
                      );
                    },
              child: Text(
                claimed
                    ? _zh(store, '今日已签到', 'Checked in today')
                    : _zh(
                        store,
                        '领取 ${Economy.coinCheckinDaily} 金币',
                        'Claim ${Economy.coinCheckinDaily} coins',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SCR-15-TASKS (was SCR-14-TASKS)
class EconomyTasksPage extends StatefulWidget {
  const EconomyTasksPage({super.key});

  @override
  State<EconomyTasksPage> createState() => _EconomyTasksPageState();
}

class _EconomyTasksPageState extends State<EconomyTasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushToast());
  }

  void _flushToast() {
    if (!mounted) return;
    final store = context.read<SpaceStore>();
    final n = store.takePendingCoinToast();
    if (n == null) return;
    showEconomyCoinToast(context, store: store, amount: n);
  }

  Widget _taskRow({
    required SpaceStore store,
    required LpTokens tokens,
    required String titleZh,
    required String titleEn,
    required String subZh,
    required String subEn,
    required bool claimed,
    required VoidCallback? onGo,
  }) {
    return Card(
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: ListTile(
          title: Text(_zh(store, titleZh, titleEn)),
          subtitle: Text(
            claimed
                ? _zh(store, '今日已领', 'Claimed today')
                : _zh(store, subZh, subEn),
            style: TextStyle(color: tokens.textSecondary),
          ),
          trailing: claimed
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.bgMuted,
                    foregroundColor: tokens.textTertiary,
                    disabledBackgroundColor: tokens.bgMuted,
                    disabledForegroundColor: tokens.textTertiary,
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: null,
                  child: Text(_zh(store, '今日已领', 'Claimed today')),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.ctaInverse,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(88, 44),
                  ),
                  onPressed: onGo,
                  child: Text(_zh(store, '去完成', 'Go')),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final e = store.economy;
    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '今日任务', "Today's tasks"))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _taskRow(
            store: store,
            tokens: tokens,
            titleZh: '完成 1 次聊天发送',
            titleEn: 'Send 1 chat message',
            subZh: '去互动页聊一句 · +${Economy.coinTaskChat}',
            subEn: 'Chat on Activity · +${Economy.coinTaskChat}',
            claimed: e.taskChatClaimedToday,
            onGo: () {
              store.requestShellTab(1);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 8),
          _taskRow(
            store: store,
            tokens: tokens,
            titleZh: '看完一则它的故事',
            titleEn: 'Finish one of its stories',
            subZh: '去看看 · +${Economy.coinTaskStoryImpress}',
            subEn: 'Open stories · +${Economy.coinTaskStoryImpress}',
            claimed: e.taskStoryImpressClaimedToday,
            onGo: () {
              store.requestShellTab(0);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 8),
          _taskRow(
            store: store,
            tokens: tokens,
            titleZh: '把一张日常放进圈子',
            titleEn: 'Post a daily photo to the circle',
            subZh: '去发一张 · +${Economy.coinTaskCustomMedia}',
            subEn: 'Add a photo · +${Economy.coinTaskCustomMedia}',
            claimed: e.taskCustomMediaClaimedToday,
            onGo: () async {
              await CustomMediaFlow.start(context);
              if (!context.mounted) return;
              final n = store.takePendingCoinToast();
              if (n != null) {
                showEconomyCoinToast(context, store: store, amount: n);
              }
            },
          ),
          const SizedBox(height: 12),
          _roleGenTaskRow(
            context: context,
            store: store,
            tokens: tokens,
            enabled: RoleGenCapabilities.customCharacterEnabled,
            titleZh: '创建自定义角色',
            titleEn: 'Create custom character',
            readySubZh: '保存成功后可用 · ${Economy.coinCostCustomCharacter} 金币',
            readySubEn:
                'Usable after save · ${Economy.coinCostCustomCharacter} coins',
            ctaZh: '去创建',
            ctaEn: 'Create',
            onGo: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RoleCreatePage()),
              );
            },
          ),
          const SizedBox(height: 8),
          _roleGenTaskRow(
            context: context,
            store: store,
            tokens: tokens,
            enabled: RoleGenCapabilities.imageGenEnabled,
            titleZh: '生成一张图',
            titleEn: 'Generate an image',
            readySubZh: '成功出图 · ${Economy.coinCostImageGen} 金币',
            readySubEn: 'On success · ${Economy.coinCostImageGen} coins',
            ctaZh: '去生成',
            ctaEn: 'Generate',
            onGo: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ImageGenPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _zh(
              store,
              '任务奖励与消耗为本机模拟经济 · 非商店发币或返佣',
              'Task rewards & spends are local simulated · not store payouts',
            ),
            style: TextStyle(fontSize: 11, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// SCR-14-SUB
class EconomySubPage extends StatelessWidget {
  const EconomySubPage({super.key});

  Future<void> _confirmSim(BuildContext context, String sku) async {
    final store = context.read<SpaceStore>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.lpTokens;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _zh(
                    store,
                    '确认模拟开通？不会产生真实扣款。',
                    'Confirm simulated unlock? No real charge.',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.ctaInverse,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(tokens.hitMin),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(_zh(store, '确认模拟开通', 'Confirm simulate')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(_zh(store, '取消', 'Cancel')),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return;
    await store.simulatePurchase(sku);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _zh(
            store,
            '已模拟开通 · 日赠币规则已生效',
            'Simulated unlock · daily grant active',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final e = store.economy;
    final tokens = context.lpTokens;
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '会员', 'Membership'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(color: tokens.borderHairline),
            ),
            child: Text(
              _zh(
                store,
                '当前不会向 App Store / Google Play 扣款；仅本机模拟权益。',
                'No App Store / Play charge now; local simulated benefits only.',
              ),
              style: TextStyle(color: tokens.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _zh(store, '陪伴会员（模拟开通）', 'Companion membership (simulated)'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _zh(
              store,
              '· 每日赠送金币（会员）\n· 免费日额度略提高（故事/浏览）\n· 聊天同样耗币，可用日赠币覆盖',
              '· Daily coin grant (member)\n· Slightly higher free daily quotas\n· Chat still costs coins; daily grant covers',
            ),
            style: TextStyle(color: tokens.textSecondary, height: 1.5),
          ),
          if (e.isMemberSimulated) ...[
            const SizedBox(height: 12),
            Text(
              _zh(store, '模拟会员生效中', 'Simulated membership active'),
              style: TextStyle(
                color: const Color(0xFF2E7D4F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EconomyWalletPage(),
                ),
              ),
              child: Text(_zh(store, '查看钱包', 'Open wallet')),
            ),
          ] else ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.ctaInverse,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(tokens.hitMin),
              ),
              onPressed: () => _confirmSim(context, 'sub_monthly'),
              child: Text(
                _zh(
                  store,
                  '模拟开通每月 · ¥${Economy.priceSubMonthlyCny.toStringAsFixed(2)}',
                  'Simulate monthly · ¥${Economy.priceSubMonthlyCny.toStringAsFixed(2)}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.ctaInverse,
                side: BorderSide(color: tokens.ctaInverse),
                minimumSize: Size.fromHeight(tokens.hitMin),
              ),
              onPressed: () => _confirmSim(context, 'sub_yearly'),
              child: Text(
                _zh(
                  store,
                  '模拟开通每年 · ¥${Economy.priceSubYearlyCny.toStringAsFixed(2)}',
                  'Simulate yearly · ¥${Economy.priceSubYearlyCny.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                showFormalIntentSheet(context, from: 'economy_sub'),
            child: Text(
              _zh(store, '登记正式意愿（不解锁）', 'Register formal interest (no unlock)'),
            ),
          ),
          Text(
            _zh(
              store,
              '价格为产品假设参数，可配置',
              'Prices are configurable product hypotheses',
            ),
            style: TextStyle(fontSize: 11, color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// SCR-14-INVITE
class EconomyInvitePage extends StatefulWidget {
  const EconomyInvitePage({super.key});

  @override
  State<EconomyInvitePage> createState() => _EconomyInvitePageState();
}

class _EconomyInvitePageState extends State<EconomyInvitePage> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final e = store.economy;
    final tokens = context.lpTokens;
    final code = e.inviteCode ?? e.ensureInviteCode();
    final link = 'https://little-paw-prod.web.app/?invite=$code';
    if (e.inviteCode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        store.ensureInviteCodePersisted();
      });
    }
    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(_zh(store, '邀请朋友', 'Invite friends'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _zh(
              store,
              '完成后可得金币（本机模拟到账）。非正式分成计划 · 无返佣结算。无约遛/加好友/同城匹配。',
              'Coins credit locally (simulated). Not a referral payout. No social graph.',
            ),
            style: TextStyle(color: tokens.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ctaInverse,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(tokens.hitMin),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              await store.copyInviteShare();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_zh(store, '已复制邀请链接', 'Invite link copied')),
                ),
              );
            },
            child: Text(_zh(store, '复制邀请链接/码', 'Copy invite link/code')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: e.inviteInviterRedeemed
                ? null
                : () async {
                    final n = await store.redeemInviteSim(role: 'inviter');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          n == null
                              ? _zh(store, '已领取过', 'Already claimed')
                              : _zh(store, '邀请人模拟到账 +$n', 'Inviter sim +$n'),
                        ),
                      ),
                    );
                  },
            child: Text(_zh(store, '模拟核销·邀请人奖励', 'Simulate inviter reward')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              labelText: _zh(store, '输入他人邀请码（受邀）', 'Enter invite code'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: e.inviteInviteeRedeemed
                ? null
                : () async {
                    final n = await store.redeemInviteSim(
                      role: 'invitee',
                      code: _codeCtrl.text,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          n == null
                              ? _zh(store, '无法核销（已领/自码/空）', 'Cannot redeem')
                              : _zh(store, '受邀模拟到账 +$n', 'Invitee sim +$n'),
                        ),
                      ),
                    );
                  },
            child: Text(_zh(store, '模拟核销·受邀奖励', 'Simulate invitee reward')),
          ),
        ],
      ),
    );
  }
}

Widget _roleGenTaskRow({
  required BuildContext context,
  required SpaceStore store,
  required LpTokens tokens,
  required bool enabled,
  required String titleZh,
  required String titleEn,
  required String readySubZh,
  required String readySubEn,
  required String ctaZh,
  required String ctaEn,
  required VoidCallback onGo,
}) {
  if (!enabled) {
    return Card(
      color: tokens.bgMuted,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: ListTile(
          title: Text(
            _zh(store, titleZh, titleEn),
            style: TextStyle(color: tokens.textTertiary),
          ),
          subtitle: Text(
            _zh(store, '暂不可用 · 能力未启用', 'Unavailable · not enabled'),
            style: TextStyle(color: tokens.textTertiary, fontSize: 12),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RoleUnavailablePage(
                  kind: titleZh.contains('图')
                      ? RoleUnavailableKind.image
                      : RoleUnavailableKind.character,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  return Card(
    color: Colors.white,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ListTile(
        title: Text(_zh(store, titleZh, titleEn)),
        subtitle: Text(
          _zh(store, readySubZh, readySubEn),
          style: TextStyle(color: tokens.textSecondary, fontSize: 12),
        ),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tokens.ctaInverse,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 44),
          ),
          onPressed: onGo,
          child: Text(_zh(store, ctaZh, ctaEn)),
        ),
      ),
    ),
  );
}

Future<void> showCoinInsufficientSheet(
  BuildContext context, {
  int? needAmount,
  String? reasonZh,
  String? reasonEn,
}) {
  final store = context.read<SpaceStore>();
  store.eventLog.paywallIntentShown(from: 'coin_insufficient');
  final amount = needAmount ?? Economy.coinCostChat;
  final bodyZh = reasonZh ?? '发一条消息需要 $amount 金币。';
  final bodyEn = reasonEn ?? 'Sending needs $amount coins.';
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final tokens = ctx.lpTokens;
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _zh(store, '金币不够了', 'Not enough coins'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_zh(store, bodyZh, bodyEn)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.ctaInverse,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EconomyCheckinPage(),
                      ),
                    );
                  },
                  child: Text(_zh(store, '去签到', 'Check in')),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EconomyTasksPage(),
                      ),
                    );
                  },
                  child: Text(_zh(store, '看今日任务', 'Today\'s tasks')),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EconomySubPage(),
                      ),
                    );
                  },
                  child: Text(_zh(store, '了解会员（模拟）', 'Membership (sim)')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showFormalIntentSheet(context, from: 'coin_insufficient');
                  },
                  child: Text(
                    _zh(store, '登记正式意愿（不解锁）', 'Formal interest (no unlock)'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_zh(store, '关闭', 'Close')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showFeedbackSheet(BuildContext context) {
  final store = context.read<SpaceStore>();
  store.eventLog.log('feedback_open');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _FeedbackSheetBody(),
  );
}

class _FeedbackSheetBody extends StatefulWidget {
  const _FeedbackSheetBody();

  @override
  State<_FeedbackSheetBody> createState() => _FeedbackSheetBodyState();
}

class _FeedbackSheetBodyState extends State<_FeedbackSheetBody> {
  String type = 'suggestion';
  final bodyCtrl = TextEditingController();
  String? error;

  @override
  void dispose() {
    bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final tokens = context.lpTokens;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _zh(store, '反馈', 'Feedback'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_zh(store, '关闭', 'Close')),
              ),
            ],
          ),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'problem',
                label: Text(_zh(store, '问题', 'Problem')),
              ),
              ButtonSegment(
                value: 'suggestion',
                label: Text(_zh(store, '建议', 'Suggestion')),
              ),
            ],
            selected: {type},
            onSelectionChanged: (v) => setState(() => type = v.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bodyCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: _zh(
                store,
                '写一点具体内容（至少约 5 字）',
                'A bit more detail (≥ ~5 chars)',
              ),
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _zh(
              store,
              '我们会阅读；不承诺回复时效。无人工客服工单号。',
              'We read it; no reply SLA. No support ticket id.',
            ),
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ctaInverse,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(tokens.hitMin),
            ),
            onPressed: () async {
              if (bodyCtrl.text.trim().length < 5) {
                setState(
                  () => error = _zh(store, '再写细一点', 'Please add a bit more'),
                );
                return;
              }
              final id = await store.submitFeedback(
                type: type,
                body: bodyCtrl.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    id == null
                        ? _zh(store, '提交失败', 'Submit failed')
                        : _zh(store, '已收到', 'Received'),
                  ),
                ),
              );
            },
            child: Text(_zh(store, '提交', 'Submit')),
          ),
        ],
      ),
    );
  }
}
