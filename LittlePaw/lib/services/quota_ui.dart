/// Pure helpers for SCR-07 quota bar copy / CTA gating (LP-D-02 / LP-P-09).
enum QuotaPresentation { defer, ready }

class QuotaUi {
  /// When [flagOn], formal auto wall only after first-session core.
  static bool mayAutoPresentFormalQuotaSheet({
    required bool flagOn,
    required bool firstSessionCoreComplete,
  }) {
    if (!flagOn) return true;
    return firstSessionCoreComplete;
  }

  /// Resolve which copy block to show.
  static String kind({
    required bool storiesHit,
    required bool repliesHit,
    String preferred = 'stories',
  }) {
    if (storiesHit && repliesHit) return 'both';
    if (repliesHit && !storiesHit) return 'replies';
    if (storiesHit && !repliesHit) return 'stories';
    return preferred;
  }

  static String titleKey(String kind) {
    switch (kind) {
      case 'both':
        return 'quota.both.title';
      case 'replies':
        return 'quota.replies.title';
      default:
        return 'quota.stories.title';
    }
  }

  static String bodyKey(String kind) {
    switch (kind) {
      case 'both':
        return 'quota.both.body';
      case 'replies':
        return 'quota.replies.body';
      default:
        return 'quota.stories.body';
    }
  }

  /// D-18 / P-18: exhausted banner/sheet only when remaining == 0 for [kind].
  /// kind: stories | replies | both — aligns with existing hit counters.
  static bool mayShowExhaustedUi({
    required int storiesLeft,
    required int repliesLeft,
    String kind = 'stories',
  }) {
    switch (kind) {
      case 'replies':
        return repliesLeft == 0;
      case 'both':
        return storiesLeft == 0 && repliesLeft == 0;
      default:
        return storiesLeft == 0;
    }
  }

  /// D-20 / P-20 F2: 「今日免费动态发帖」墙 — only after a successful post
  /// that exhausted remaining free posts. Hidden while picker/confirm in flight.
  static bool mayShowPostQuotaWall({
    required int storiesLeft,
    required bool afterSuccessfulPost,
    bool pickerOrConfirmInFlight = false,
  }) {
    if (pickerOrConfirmInFlight) return false;
    if (!afterSuccessfulPost) return false;
    return storiesLeft == 0;
  }

  /// S1: strong secondary CTA only when active UTC days >= 3 and intent entry on.
  static bool showStrongSecondary({
    required int activeUtcDays,
    required bool intentEntryEnabled,
    int threshold = 3,
  }) {
    return intentEntryEnabled && activeUtcDays >= threshold;
  }

  /// Soft secondary (allowance info only) when intent on but S1 not met.
  static bool showSoftSecondary({
    required int activeUtcDays,
    required bool intentEntryEnabled,
    int threshold = 3,
  }) {
    if (!intentEntryEnabled) return false;
    return activeUtcDays < threshold;
  }
}
