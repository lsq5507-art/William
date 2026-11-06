import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../ops_constants.dart';
import '../ops_theme.dart';

class OpsLoginPage extends StatefulWidget {
  const OpsLoginPage({super.key});

  @override
  State<OpsLoginPage> createState() => _OpsLoginPageState();
}

class _OpsLoginPageState extends State<OpsLoginPage> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    final auth = context.read<AuthService>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = auth.lastError ?? e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpsTheme.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Little Paw · 内部运营后台',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: OpsTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    OpsConstants.buildChip,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OpsTheme.muted,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '使用 Google 账号登录以继续。仅白名单成员可访问。Guest 不可进入。',
                    style: TextStyle(fontSize: 14, color: OpsTheme.muted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('ops.login.google'),
                    onPressed: _busy ? null : _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: OpsTheme.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('使用 Google 登录'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: OpsTheme.deny, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    '非公开站点 · 禁止外发链接给非授权人员',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: OpsTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
