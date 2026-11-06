/// LP-DEV-19 / 19b: first-session daily exposure experiment helpers.
///
/// Feed「完整曝光」映射（相对现网 story impress）：
/// - 现网 Feed/Story：`StoryImpressionTracker` 默认 ≥80% 立即 或 部分可见 dwell 2s →
///   `markStoryImpressed` → `story_impression_complete`（非 demo fill）亦满足曝光门禁。
/// - 本刀 D-19 完整曝光：主帖可见 ≥50% 持续 ≥1.0s（`immediateRatio: 1.1` +
///   `dwellMinRatio: 0.5` + `dwell: 1s`）→ 可打 `first_daily_forced_impression`。
/// - Story 通道：既有 `story_impression_complete`（非 demo fill）。
/// - 空态唯一例外：`first_daily_skipped` 后允许进聊。
///
/// LP-DEV-19b 三态：`dailyExposureCompleted` / `firstDailyCoachShown` /
/// `firstDailyPinConsumed` — 曝光完成 **不得** 吞 coach/pin。
class FirstDailyGate {
  FirstDailyGate._();

  static const String stampExperiment = 'first-daily-test-v0.19';
  static const String stampBaseline = 'onboarding-ux-web-v0.18';

  /// LP-DEV-20 dual-domain hotfix stamp (does not promote E01 CURRENT).
  static const String stampHotfix = 'ux-hotfix-web-v0.20';

  static bool isPetHost(String hostname) {
    final h = hostname.trim().toLowerCase();
    return h == 'littlepaw.pet' || h == 'www.littlepaw.pet';
  }

  /// web.app / localhost / empty(debug·native) → experiment on; pet → off.
  static bool experimentEnabledForHost(String hostname) {
    if (isPetHost(hostname)) return false;
    return true;
  }

  static String buildStampForHost(String hostname) {
    // Dual-domain same build for UX hotfix; experiment gate stays host-based.
    return stampHotfix;
  }

  /// Coach: ignore exposure — only experiment + onboarding + not yet shown.
  static bool shouldShowCoach({
    required bool experimentEnabled,
    required bool onboardingComplete,
    required bool coachShown,
  }) {
    if (!experimentEnabled) return false;
    if (!onboardingComplete) return false;
    if (coachShown) return false;
    return true;
  }

  /// Pin: ignore exposure — experiment + eligible content + not consumed.
  static bool shouldShowPin({
    required bool experimentEnabled,
    required bool hasEligibleContent,
    required bool pinConsumed,
  }) {
    if (!experimentEnabled) return false;
    if (!hasEligibleContent) return false;
    if (pinConsumed) return false;
    return true;
  }
}
