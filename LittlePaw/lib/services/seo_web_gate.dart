import 'event_log.dart';
import 'first_daily_gate.dart';

/// LP-DEV-16: marketing shell vs app entry gate (pure Dart; DOM via callbacks).
/// LP-DEV-19: hostname-gated buildStamp / first-daily experiment.
class SeoWebGate {
  SeoWebGate._();

  /// Test / bootstrap override. When null, [platformHostname] is used.
  static String? hostnameOverride;

  /// Bound on web to `window.location.hostname`; empty on stub/native.
  static String Function() platformHostname = () => '';

  static String get resolvedHostname =>
      (hostnameOverride ?? platformHostname()).trim().toLowerCase();

  static String get buildStamp =>
      FirstDailyGate.buildStampForHost(resolvedHostname);

  static bool get firstDailyExperimentEnabled =>
      FirstDailyGate.experimentEnabledForHost(resolvedHostname);

  static const String landingElementId = 'seo-landing';
  static const String appQueryValue = '1';

  /// Enter app shell when `?app=1` or path `/app` (optional trailing slash).
  static bool wantsAppShell(Uri uri) {
    final app = uri.queryParameters['app'];
    if (app == appQueryValue || app == 'true') return true;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1 && segments.first == 'app') return true;
    return false;
  }

  static bool shouldHideLandingShell(Uri uri) => wantsAppShell(uri);

  /// App deep links may be noindex; marketing shell stays indexable.
  static bool shouldNoIndex(Uri uri) => wantsAppShell(uri);

  /// Apply entry policy once at startup (web). Safe no-ops if callbacks unused.
  static void applyEntry(
    Uri uri, {
    required EventLog eventLog,
    void Function()? hideLandingShell,
    void Function()? setNoIndex,
  }) {
    if (wantsAppShell(uri)) {
      hideLandingShell?.call();
      if (shouldNoIndex(uri)) setNoIndex?.call();
      eventLog.seoCtaClick();
      return;
    }
    eventLog.seoLandingView();
  }
}
