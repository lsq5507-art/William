import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'ops_allowlist.dart';
import 'ops_path.dart';
import 'ops_repository.dart';
import 'ops_theme.dart';
import 'pages/ops_deny_page.dart';
import 'pages/ops_funnel_page.dart';
import 'pages/ops_login_page.dart';
import 'pages/ops_overview_page.dart';
import 'pages/ops_shell.dart';
import 'pages/ops_users_page.dart';

/// Auth + allowlist gate for `/ops*`.
class OpsGate extends StatefulWidget {
  const OpsGate({
    super.key,
    this.skipRemoteAllowlist = false,
    this.repository,
    this.initialTab,
  });

  /// Tests: skip Firestore allowlist fetch.
  final bool skipRemoteAllowlist;
  final OpsRepository? repository;
  final OpsTab? initialTab;

  @override
  State<OpsGate> createState() => _OpsGateState();
}

class _OpsGateState extends State<OpsGate> {
  List<String> _remoteEmails = const [];
  bool _allowlistLoading = true;
  late OpsRepository _repo;

  @override
  void initState() {
    super.initState();
    // Avoid constructing FirestoreOpsRepository in tests / signed-out pumps.
    _repo = widget.repository ?? const OpsRepositoryStub.empty();
    _loadAllowlist();
  }

  OpsRepository _liveRepo() {
    if (widget.repository != null) return widget.repository!;
    if (widget.skipRemoteAllowlist) return const OpsRepositoryStub.empty();
    return FirestoreOpsRepository();
  }

  Future<void> _loadAllowlist() async {
    if (widget.skipRemoteAllowlist) {
      setState(() => _allowlistLoading = false);
      return;
    }
    try {
      final live = _liveRepo();
      _repo = live;
      final emails = await live.fetchAllowlistEmails();
      if (!mounted) return;
      setState(() {
        _remoteEmails = emails;
        _allowlistLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _allowlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: OpsTheme.material(),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return const OpsLoginPage();
          }
          if (_allowlistLoading && !widget.skipRemoteAllowlist) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final ok = OpsAllowlist.isAllowlisted(
            user.email,
            firestoreEmails: _remoteEmails,
          );
          if (!ok) {
            return const OpsDenyPage();
          }
          return _OpsAuthedBody(
            repository: _repo,
            initialTab: widget.initialTab ?? OpsPath.tabFromPath() ?? OpsTab.overview,
          );
        },
      ),
    );
  }
}

class _OpsAuthedBody extends StatefulWidget {
  const _OpsAuthedBody({
    required this.repository,
    required this.initialTab,
  });

  final OpsRepository repository;
  final OpsTab initialTab;

  @override
  State<_OpsAuthedBody> createState() => _OpsAuthedBodyState();
}

class _OpsAuthedBodyState extends State<_OpsAuthedBody> {
  late OpsTab _tab;
  OpsOverviewStats? _stats;
  List<OpsUserRow> _rows = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await widget.repository.fetchOverview();
      final rows = await widget.repository.fetchUsers();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_tab) {
      case OpsTab.overview:
        body = OpsOverviewPage(
          key: const Key('ops.overview.page'),
          stats: _stats,
          loading: _loading,
          error: _error,
          onRetry: _reload,
        );
      case OpsTab.users:
        body = OpsUsersPage(
          rows: _rows,
          loading: _loading,
          error: _error,
          onRetry: _reload,
        );
      case OpsTab.funnel:
        body = const OpsFunnelPage();
    }
    return OpsShell(
      initialTab: _tab,
      onTab: (t) => setState(() => _tab = t),
      overview: body,
      child: body,
    );
  }
}
