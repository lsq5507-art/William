import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/auth_service.dart';
import '../services/space_store.dart';
import '../theme/lp_theme.dart';

/// SCR-10-EDIT — rename pet sheet (G-01: close/cancel never unlocks).
Future<void> showEditPetSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.lpTokens.radiusLg),
      ),
    ),
    builder: (ctx) => const _EditPetSheetBody(),
  );
}

class _EditPetSheetBody extends StatefulWidget {
  const _EditPetSheetBody();

  @override
  State<_EditPetSheetBody> createState() => _EditPetSheetBodyState();
}

class _EditPetSheetBodyState extends State<_EditPetSheetBody> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _ctrl.text = context.read<SpaceStore>().pet?.name ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final auth = context.watch<AuthService>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.get('profile.edit_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: s.get('profile.edit_cancel'),
                child: IconButton(
                  tooltip: s.get('profile.edit_cancel'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.get('profile.edit_name_label'),
              style: TextStyle(color: tokens.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: SpaceStore.petNameMaxLen,
            decoration: InputDecoration(
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (auth.currentUser != null) ...[
            const SizedBox(height: 4),
            Text(
              s.get('profile.edit_sync_note'),
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.ctaInverse,
              foregroundColor: tokens.onCtaInverse,
              minimumSize: Size.fromHeight(tokens.hitMin),
            ),
            onPressed: () async {
              final raw = _ctrl.text;
              if (raw.trim().isEmpty) {
                setState(() => _error = s.get('profile.edit_empty'));
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(context);
              try {
                await store.renamePet(raw);
              } on ArgumentError {
                setState(() => _error = s.get('profile.edit_empty'));
                return;
              }
              if (!context.mounted) return;
              Navigator.pop(context);
              messenger?.showSnackBar(
                SnackBar(content: Text(s.get('profile.edit_saved'))),
              );
            },
            child: Text(s.get('profile.edit_save')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.get('profile.edit_cancel')),
          ),
        ],
      ),
    );
  }
}

/// SCR-10-SHOP / INVITE / LEGAL placeholder pages — no fake purchase / rewards.
class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({
    super.key,
    required this.title,
    required this.body,
    this.inviteCopy = false,
  });

  final String title;
  final String body;
  final bool inviteCopy;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.hourglass_empty_outlined,
                size: 48, color: tokens.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              key: const Key('profile.placeholder.title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: tokens.textSecondary, height: 1.4)),
            if (inviteCopy) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.ctaInverse,
                  side: BorderSide(color: tokens.ctaInverse),
                  minimumSize: Size.fromHeight(tokens.hitMin),
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: s.get('profile.invite_copy_text')),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.get('profile.invite_copied'))),
                    );
                  }
                },
                child: Text(s.get('profile.invite_copy')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileLegalPage extends StatelessWidget {
  const ProfileLegalPage({
    super.key,
    required this.title,
    required this.body,
    this.showCounselNote = true,
  });

  final String title;
  final String body;
  final bool showCounselNote;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (showCounselNote) ...[
            Text(
              s.get('profile.legal_placeholder'),
              style: TextStyle(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(body, style: TextStyle(color: tokens.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

/// SCR-12 — 本机已发宠圈只读列表（LP-P-12 / D-12）.
class ProfileMyPostsPage extends StatefulWidget {
  const ProfileMyPostsPage({super.key});

  @override
  State<ProfileMyPostsPage> createState() => _ProfileMyPostsPageState();
}

class _ProfileMyPostsPageState extends State<ProfileMyPostsPage> {
  bool _loading = true;
  bool _error = false;
  List<Story> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final store = context.read<SpaceStore>();
      final items = List<Story>.from(store.visualFeedStories())
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _openFeedComposer(BuildContext context, SpaceStore store) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    store.requestFocusStory('__open_feed_from_my_posts__');
  }

  String _timeLabel(Story story, bool zh) {
    final local = story.createdAt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return zh ? '$mm-$dd $hh:$mi' : '$mm/$dd $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final tokens = context.lpTokens;

    return Scaffold(
      key: const Key('profile.my_posts.page'),
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(s.get('profile.my_posts'))),
      body: _buildBody(context, store, s, tokens),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SpaceStore store,
    S s,
    LpTokens tokens,
  ) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.get('profile.my_posts_caption'),
            style: TextStyle(fontSize: 12, color: tokens.textTertiary),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            _SkeletonRow(tokens: tokens),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.get('profile.my_posts_error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('profile.my_posts.retry'),
                onPressed: _load,
                child: Text(s.get('profile.my_posts_retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.photo_outlined, size: 56, color: tokens.textTertiary),
            const SizedBox(height: 16),
            Text(
              s.get('profile.my_posts_empty_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              s.get('profile.my_posts_empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('profile.my_posts.empty_cta'),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.ctaInverse,
                foregroundColor: tokens.onCtaInverse,
                minimumSize: Size.fromHeight(tokens.hitMin),
              ),
              onPressed: () => _openFeedComposer(context, store),
              child: Text(s.get('profile.my_posts_empty_cta')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.get('profile.my_posts_empty_back')),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length + 1,
      separatorBuilder: (context, _) =>
          Divider(height: 1, color: tokens.borderHairline),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              s.get('profile.my_posts_caption'),
              style: TextStyle(fontSize: 12, color: tokens.textTertiary),
            ),
          );
        }
        final story = _items[index - 1];
        final body = story.body(store.localeZh).trim();
        return Material(
          color: Colors.white,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: _Thumb(url: story.imageUrl, tokens: tokens),
            title: Text(
              body.isEmpty ? '·' : body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_timeLabel(story, store.localeZh)} · ${s.get('profile.my_posts_readonly_badge')}',
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
            onTap: () {
              // Should: open Feed and focus this post (readonly).
              Navigator.of(context).popUntil((route) => route.isFirst);
              store.requestFocusStory(story.id);
            },
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.tokens});

  final String? url;
  final LpTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.startsWith('assets/')
          ? Image.asset(url!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_outlined, color: tokens.textTertiary);
            })
          : Icon(Icons.image_outlined, color: tokens.textTertiary),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.tokens});

  final LpTokens tokens;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: tokens.bgMuted,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Row(
      children: [
        bar(72, 72),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(double.infinity, 12),
              const SizedBox(height: 8),
              bar(160, 12),
            ],
          ),
        ),
      ],
    );
  }
}
