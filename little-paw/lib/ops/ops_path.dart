/// Detect Hosting `/ops*` entry without GoRouter.
class OpsPath {
  OpsPath._();

  static bool isOpsPath([String? path]) {
    final p = (path ?? Uri.base.path).trim();
    if (p == '/ops' || p == '/ops/') return true;
    return p.startsWith('/ops/');
  }

  static OpsTab? tabFromPath([String? path]) {
    final p = (path ?? Uri.base.path).trim();
    if (p.startsWith('/ops/users')) return OpsTab.users;
    if (p.startsWith('/ops/funnel')) return OpsTab.funnel;
    if (p == '/ops' ||
        p == '/ops/' ||
        p.startsWith('/ops/overview') ||
        p.startsWith('/ops/login')) {
      return OpsTab.overview;
    }
    if (isOpsPath(p)) return OpsTab.overview;
    return null;
  }
}

enum OpsTab { overview, users, funnel }
