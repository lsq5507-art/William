import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';
import 'intent_sheet.dart';
import 'economy_pages.dart';
import 'profile_center_pages.dart';
import 'role_gen_pages.dart';

/// SCR-10 Profile Center — P-10 / D-11.
/// S0-2 hard-hide: no INS layout toggle / assumed-price UI nodes on this surface.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _versionTaps = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final e = store.economy;
    final tokens = context.lpTokens;
    final auth = context.watch<AuthService>();
    final sync = context.read<CloudSyncService>();

    final petName = (store.pet?.name.trim().isNotEmpty ?? false)
        ? store.pet!.name
        : s.get('profile.name_placeholder');
    final quotaLine = s.fmt('profile.quota_line', {
      'storiesUsed': '${e.storiesUsedToday}',
      'storiesLimit': '${e.storiesLimit}',
      'repliesUsed': '${e.repliesUsedToday}',
      'repliesLimit': '${e.repliesLimit}',
    });

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(s.get('profile.tab'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // —— Identity card ——
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              onTap: () => showEditPetSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: tokens.brandSoft,
                      child: Icon(Icons.pets, color: tokens.ctaInverse),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quotaLine,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const EconomyWalletPage(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on_outlined,
                                  size: 16,
                                  color: tokens.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${e.coinBalance}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: s.get('profile.edit_a11y'),
                      child: TextButton(
                        key: const Key('profile.edit'),
                        onPressed: () => showEditPetSheet(context),
                        child: Text(s.get('profile.edit')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // —— 本宠日常（D-12 S1）——
          if (store.profileMyPostsReadonlyEnabled) ...[
            _SectionCard(
              title: s.get('profile.section_daily'),
              children: [
                ListTile(
                  key: const Key('profile.my_posts'),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(s.get('profile.my_posts')),
                  subtitle: Text(
                    s.get('profile.my_posts_sub'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    store.eventLog.log(
                      'my_moments_open',
                      props: {'entry': 'profile'},
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileMyPostsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // —— Account ——
          _SectionCard(
            title: s.get('auth.section'),
            children: [
              if (auth.currentUser != null) ...[
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(
                    s.fmt('auth.signed_in_as', {
                      'email': auth.currentUser!.email ?? auth.currentUser!.uid,
                    }),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(s.get('auth.sign_out')),
                  onTap: () => _signOut(context, auth, store),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(s.get('auth.guest')),
                  subtitle: !auth.firebaseReady
                      ? Text(
                          s.get('auth.firebase_unavailable'),
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(s.get('auth.sign_in_google')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _signIn(context, auth, sync, store, s),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // —— Growth ——
          _SectionCard(
            title: s.get('profile.section_growth'),
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(store.localeZh ? '金币钱包' : 'Coin wallet'),
                subtitle: Text(
                  store.localeZh
                      ? '余额 ${e.coinBalance}'
                      : 'Balance ${e.coinBalance}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EconomyWalletPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(store.localeZh ? '每日签到' : 'Daily check-in'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EconomyCheckinPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_outlined),
                title: Text(store.localeZh ? '今日任务' : "Today's tasks"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EconomyTasksPage(),
                  ),
                ),
              ),
              ListTile(
                key: const Key('profile.role_pick'),
                leading: const Icon(Icons.pets_outlined),
                title: Text(
                  store.localeZh ? '本机角色 / 选伴' : 'On-device companions',
                ),
                subtitle: Text(
                  store.localeZh
                      ? '自定义角色轻选用 · 非角色市场'
                      : 'Light pick · not a marketplace',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RolePickPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(store.localeZh ? '会员 / 模拟订阅' : 'Membership (sim)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EconomySubPage(),
                  ),
                ),
              ),
              if (store.intentEntryEnabled)
                ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(s.get('profile.intent_entry')),
                  subtitle: Text(
                    store.s1StrongIntentOk
                        ? s.get('profile.intent_entry_sub')
                        : s.get('quota.s1_hint'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showFormalIntentSheet(context, from: 'profile'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text(s.get('intent.entry_paused_title')),
                  subtitle: Text(s.get('intent.entry_paused_body')),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // —— Discover (shop / invite shells) ——
          _SectionCard(
            title: s.get('profile.section_discover'),
            children: [
              ListTile(
                key: const Key('profile.shop'),
                leading: const Icon(Icons.storefront_outlined),
                title: Text(s.get('profile.shop')),
                subtitle: Text(
                  s.get('profile.shop_sub'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EconomySubPage(),
                    ),
                  );
                },
              ),
              ListTile(
                key: const Key('profile.invite'),
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: Text(s.get('profile.invite')),
                subtitle: Text(
                  s.get('profile.invite_sub'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EconomyInvitePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // —— Prefs ——
          _SectionCard(
            title: s.get('profile.section_prefs'),
            children: [
              ListTile(
                key: const Key('profile.feedback'),
                leading: const Icon(Icons.feedback_outlined),
                title: Text(s.get('profile.feedback')),
                subtitle: Text(
                  s.get('profile.feedback_sub'),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showFeedbackSheet(context),
              ),
              ListTile(
                title: Text(s.get('profile.lang')),
                trailing: SegmentedButton<bool>(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return tokens.ctaInverse;
                      }
                      return tokens.textSecondary;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return tokens.brandSoft;
                      }
                      return Colors.transparent;
                    }),
                  ),
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(s.get('profile.lang_zh')),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(s.get('profile.lang_en')),
                    ),
                  ],
                  selected: {store.localeZh},
                  onSelectionChanged: (v) => store.setLocaleZh(v.first),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(s.get('profile.export_trial')),
                subtitle: Text(
                  s.get('profile.export_trust'),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => _exportTrial(context, store, s),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // —— Legal ——
          _SectionCard(
            title: s.get('profile.section_legal'),
            children: [
              ListTile(
                key: const Key('profile.about'),
                leading: const Icon(Icons.info_outline),
                title: Text(s.get('profile.about')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileLegalPage(
                        title: s.get('profile.about'),
                        body: s.get('profile.about_body'),
                        showCounselNote: false,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                key: const Key('profile.privacy'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(s.get('profile.privacy')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileLegalPage(
                        title: s.get('profile.privacy'),
                        body: s.get('profile.legal_privacy_body'),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                key: const Key('profile.terms'),
                leading: const Icon(Icons.description_outlined),
                title: Text(s.get('profile.terms')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileLegalPage(
                        title: s.get('profile.terms'),
                        body: s.get('profile.legal_terms_body'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // —— Advanced (intent toggle + reset) ——
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const Key('profile.advanced'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  s.get('profile.advanced'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  SwitchListTile(
                    title: Text(s.get('profile.intent_toggle')),
                    subtitle: Text(
                      store.localeZh
                          ? '关闭后隐藏意向入口与触顶强 CTA'
                          : 'Off hides interest entry & strong quota CTA',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: store.intentEntryEnabled,
                    onChanged: (v) => store.setIntentEntryEnabled(v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mark_email_read_outlined),
                    title: Text(
                      store.localeZh ? '模拟标记反馈采纳' : 'Simulate adopt feedback',
                    ),
                    subtitle: Text(
                      store.localeZh
                          ? '对最近一条未采纳反馈发币一次'
                          : 'Credit once for latest unadopted feedback',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () async {
                      final pending = store.economy.feedbacks
                          .where((f) => !f.rewardGranted)
                          .toList();
                      if (pending.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              store.localeZh
                                  ? '没有可采纳的反馈'
                                  : 'No feedback to adopt',
                            ),
                          ),
                        );
                        return;
                      }
                      final n = await store.adoptFeedbackSim(pending.last.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n == null
                                ? (store.localeZh ? '已采纳过' : 'Already adopted')
                                : (store.localeZh
                                      ? '反馈已采纳，+$n 金币'
                                      : 'Adopted +$n coins'),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text(s.get('profile.reset')),
                    onTap: () => _confirmReset(context, store, s),
                  ),
                ],
              ),
            ),
          ),

          // DEF-QA091-01: 7x tap remains (research latch); S0-2: no INS/price UI nodes.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _versionTaps += 1;
              if (_versionTaps < 7) return;
              _versionTaps = 0;
              store.setProfileDebugToolsVisible(
                !store.profileDebugToolsVisible,
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                'little paw',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: tokens.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    SpaceStore store,
    S s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.get('profile.reset_confirm_title')),
        content: Text(s.get('profile.reset_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.get('profile.reset_confirm_cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.get('profile.reset_confirm_ok')),
          ),
        ],
      ),
    );
    if (ok == true) await store.resetSpace();
  }

  Future<void> _signIn(
    BuildContext context,
    AuthService auth,
    CloudSyncService sync,
    SpaceStore store,
    S s,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(s.get('auth.syncing'))));
    try {
      final user = await auth.signInWithGoogle();
      if (user == null) {
        store.eventLog.log(
          'auth_sign_in_result',
          props: {'success': false, 'error_class': 'cancelled_or_null'},
        );
        return;
      }
      store.eventLog.log('auth_sign_in_result', props: {'success': true});
      try {
        await sync.syncOnLogin(store, user.uid);
        store.onAfterPersist = (_) => sync.pushLocal(store, user.uid);
        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(s.get('auth.sync_ok'))),
          );
        }
      } catch (_) {
        if (context.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(s.get('auth.sync_fail'))),
          );
        }
      }
    } catch (e) {
      final raw = auth.lastError ?? e.toString();
      final errorClass = raw.contains('popup')
          ? 'popup_blocked'
          : (raw.contains('network') ? 'network' : 'auth_error');
      store.eventLog.log(
        'auth_sign_in_result',
        props: {'success': false, 'error_class': errorClass},
      );
      final err = raw;
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(s.fmt('auth.sign_in_fail', {'error': err}))),
        );
      }
    }
  }

  Future<void> _signOut(
    BuildContext context,
    AuthService auth,
    SpaceStore store,
  ) async {
    store.onAfterPersist = null;
    context.read<CloudSyncService>().resetLoginSyncLatch();
    try {
      await auth.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _exportTrial(BuildContext context, SpaceStore store, S s) async {
    final log = store.eventLog;
    if (!log.hasBusinessEvents) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.get('profile.export_empty_title')),
          content: Text(s.get('profile.export_empty_body')),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    ClipboardData(text: log.exportHeaderOnly()),
                  );
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(s.get('profile.export_empty_copy_header')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.get('space.load_corrupt_ok')),
            ),
          ],
        ),
      );
      return;
    }

    final text = log.exportText();
    final n = log.businessEventCount;
    var copied = false;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      copied = true;
    } catch (_) {
      copied = false;
    }

    if (!context.mounted) return;
    if (copied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fmt('profile.export_ok_detail', {'n': '$n'}))),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.get('profile.export_fail'))));
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.get('profile.export_trial')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!copied)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      s.get('profile.export_fail'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SelectableText(text),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.get('intent.thanks.close')),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.lpTokens;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
