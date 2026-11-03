/// Read-only economy source aligned with handoff / v5_economy semantics.
/// DO NOT change price or quota truth values without commander + product approval.
///
/// Free: 2 stories / 10 replies per UTC day; lifetime 3 image experiences.
/// Member display: 4/40 daily; 30 images / 30 days anchored to create.
/// Prices (hypotheses): monthly 9.90 / yearly 59 / card 9.90 / book 19.90.
class Economy {
  // --- Quota truth (read-only) ---
  static const int freeStoriesPerUtcDay = 2;
  static const int freeRepliesPerUtcDay = 10;
  static const int freeLifetimeLifetimeImagesLifetime = 3;

  static const int memberStoriesPerUtcDay = 4;
  static const int memberRepliesPerUtcDay = 40;
  static const int memberImagesPer30Days = 30;

  // --- Price hypotheses (display / intent only; no real charge) ---
  static const double priceMonthly = 9.90;
  static const double priceYearly = 59.0;
  static const double priceCard = 9.90;
  static const double priceBook = 19.90;

  bool isMemberSimulated;
  int storiesUsedToday;
  int repliesUsedToday;
  int imagesUsedLifetime;
  String utcDay;

  Economy({
    this.isMemberSimulated = false,
    this.storiesUsedToday = 0,
    this.repliesUsedToday = 0,
    this.imagesUsedLifetime = 0,
    String? utcDay,
  }) : utcDay = utcDay ?? _todayUtc();

  static String _todayUtc() {
    final n = DateTime.now().toUtc();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  void ensureUtcDay([String? day]) {
    final d = day ?? _todayUtc();
    if (d != utcDay) {
      utcDay = d;
      storiesUsedToday = 0;
      repliesUsedToday = 0;
    }
  }

  int get storiesLimit =>
      isMemberSimulated ? memberStoriesPerUtcDay : freeStoriesPerUtcDay;

  int get repliesLimit =>
      isMemberSimulated ? memberRepliesPerUtcDay : freeRepliesPerUtcDay;

  int get storiesLeft => (storiesLimit - storiesUsedToday).clamp(0, storiesLimit);

  int get repliesLeft => (repliesLimit - repliesUsedToday).clamp(0, repliesLimit);

  bool get storiesHit => storiesUsedToday >= storiesLimit;

  bool get repliesHit => repliesUsedToday >= repliesLimit;

  /// Consume one story impression slot. Returns false if already at cap.
  bool consumeStory() {
    ensureUtcDay();
    if (storiesHit) return false;
    storiesUsedToday++;
    return true;
  }

  /// Consume one reply slot. Returns false if already at cap.
  bool consumeReply() {
    ensureUtcDay();
    if (repliesHit) return false;
    repliesUsedToday++;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'isMemberSimulated': isMemberSimulated,
        'storiesUsedToday': storiesUsedToday,
        'repliesUsedToday': repliesUsedToday,
        'imagesUsedLifetime': imagesUsedLifetime,
        'utcDay': utcDay,
      };

  factory Economy.fromJson(Map<String, dynamic> j) {
    final e = Economy(
      isMemberSimulated: j['isMemberSimulated'] as bool? ?? false,
      storiesUsedToday: j['storiesUsedToday'] as int? ?? 0,
      repliesUsedToday: j['repliesUsedToday'] as int? ?? 0,
      imagesUsedLifetime: j['imagesUsedLifetime'] as int? ?? 0,
      utcDay: j['utcDay'] as String?,
    );
    e.ensureUtcDay();
    return e;
  }
}
