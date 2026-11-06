/// Economy + simulated coin wallet (LP-P-14 / economy-web-v0.14).
/// Prices & grants are configurable constants (§6.4). No real charge.
class CoinLedgerEntry {
  final String id;
  final String type; // credit | debit
  final int amount;
  final String reason;
  final String atIso;

  const CoinLedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.atIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'reason': reason,
        'atIso': atIso,
      };

  factory CoinLedgerEntry.fromJson(Map<String, dynamic> j) => CoinLedgerEntry(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'credit',
        amount: j['amount'] as int? ?? 0,
        reason: j['reason'] as String? ?? '',
        atIso: j['atIso'] as String? ?? '',
      );
}

class FeedbackRecord {
  final String id;
  final String type; // problem | suggestion
  final String body;
  final String createdAtIso;
  String status; // submitted | adopted
  bool rewardGranted;

  FeedbackRecord({
    required this.id,
    required this.type,
    required this.body,
    required this.createdAtIso,
    this.status = 'submitted',
    this.rewardGranted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'body': body,
        'createdAtIso': createdAtIso,
        'status': status,
        'rewardGranted': rewardGranted,
      };

  factory FeedbackRecord.fromJson(Map<String, dynamic> j) => FeedbackRecord(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'suggestion',
        body: j['body'] as String? ?? '',
        createdAtIso: j['createdAtIso'] as String? ?? '',
        status: j['status'] as String? ?? 'submitted',
        rewardGranted: j['rewardGranted'] as bool? ?? false,
      );
}

class Economy {
  // --- Quota truth ---
  static const int freeStoriesPerUtcDay = 2;
  static const int freeRepliesPerUtcDay = 10;
  static const int freeLifetimeLifetimeImagesLifetime = 3;

  /// Slightly raised vs free (member benefit; P-14 日赠币+略抬额度).
  static const int memberStoriesPerUtcDay = 5;
  static const int memberRepliesPerUtcDay = 50;
  static const int memberImagesPer30Days = 30;

  // --- §6.4 parameter table (no magic numbers elsewhere) ---
  static const int coinsPerCny = 10000;
  static const double priceSubMonthlyCny = 6.0;
  static const double priceSubYearlyCny = 48.0;
  static const int coinCheckinDaily = 500;
  static const int coinCheckinStreak7 = 2000;
  static const int coinTaskChat = 200;
  static const int coinTaskStoryImpress = 100;
  static const int coinTaskCustomMedia = 300;
  static const int coinInviteInviter = 2000;
  static const int coinInviteInvitee = 1000;
  static const int coinFeedbackAdopted = 1000;
  static const int coinCostChat = 20;
  static const int coinCostCustomCharacter = 5000;
  static const int coinCostImageGen = 2000;
  static const int coinSubGrantMonthly = 30000;
  static const int coinMemberDailyGrant = 300;

  /// Legacy display aliases (map to new sub prices).
  static const double priceMonthly = priceSubMonthlyCny;
  static const double priceYearly = priceSubYearlyCny;
  static const double priceCard = 9.90;
  static const double priceBook = 19.90;

  bool isMemberSimulated;
  int storiesUsedToday;
  int repliesUsedToday;
  int imagesUsedLifetime;
  String utcDay;

  int coinBalance;
  List<CoinLedgerEntry> ledger;
  String? lastCheckinUtcDay;
  int checkinStreak;
  String? taskChatProgressUtcDay;
  String? taskChatClaimedUtcDay;
  String? taskStoryImpressProgressUtcDay;
  String? taskStoryImpressClaimedUtcDay;
  String? taskCustomMediaProgressUtcDay;
  String? taskCustomMediaClaimedUtcDay;
  String? inviteCode;
  bool inviteInviterRedeemed;
  bool inviteInviteeRedeemed;
  String? memberDailyGrantUtcDay;
  List<FeedbackRecord> feedbacks;
  int _seq;

  Economy({
    this.isMemberSimulated = false,
    this.storiesUsedToday = 0,
    this.repliesUsedToday = 0,
    this.imagesUsedLifetime = 0,
    String? utcDay,
    this.coinBalance = 0,
    List<CoinLedgerEntry>? ledger,
    this.lastCheckinUtcDay,
    this.checkinStreak = 0,
    this.taskChatProgressUtcDay,
    this.taskChatClaimedUtcDay,
    this.taskStoryImpressProgressUtcDay,
    this.taskStoryImpressClaimedUtcDay,
    this.taskCustomMediaProgressUtcDay,
    this.taskCustomMediaClaimedUtcDay,
    this.inviteCode,
    this.inviteInviterRedeemed = false,
    this.inviteInviteeRedeemed = false,
    this.memberDailyGrantUtcDay,
    List<FeedbackRecord>? feedbacks,
    int? seq,
  })  : utcDay = utcDay ?? _todayUtc(),
        ledger = ledger ?? <CoinLedgerEntry>[],
        feedbacks = feedbacks ?? <FeedbackRecord>[],
        _seq = seq ?? 0;

  static String _todayUtc() {
    final n = DateTime.now().toUtc();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseUtcDay(String day) {
    final p = day.split('-');
    if (p.length != 3) return null;
    return DateTime.utc(
      int.parse(p[0]),
      int.parse(p[1]),
      int.parse(p[2]),
    );
  }

  static String _prevUtcDay(String day) {
    final d = _parseUtcDay(day);
    if (d == null) return day;
    final p = d.subtract(const Duration(days: 1));
    return '${p.year.toString().padLeft(4, '0')}-'
        '${p.month.toString().padLeft(2, '0')}-'
        '${p.day.toString().padLeft(2, '0')}';
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

  bool get canAffordChat => coinBalance >= coinCostChat;

  bool get checkinClaimedToday {
    ensureUtcDay();
    return lastCheckinUtcDay == utcDay;
  }

  bool get taskChatReadyToday {
    ensureUtcDay();
    return taskChatProgressUtcDay == utcDay && taskChatClaimedUtcDay != utcDay;
  }

  bool get taskChatClaimedToday {
    ensureUtcDay();
    return taskChatClaimedUtcDay == utcDay;
  }

  bool get taskStoryImpressClaimedToday {
    ensureUtcDay();
    return taskStoryImpressClaimedUtcDay == utcDay;
  }

  bool get taskCustomMediaClaimedToday {
    ensureUtcDay();
    return taskCustomMediaClaimedUtcDay == utcDay;
  }

  bool consumeStory() {
    ensureUtcDay();
    if (storiesHit) return false;
    storiesUsedToday++;
    return true;
  }

  bool consumeReply() {
    ensureUtcDay();
    if (repliesHit) return false;
    repliesUsedToday++;
    return true;
  }

  String _nextId(String prefix) {
    _seq++;
    return '${prefix}_${DateTime.now().toUtc().millisecondsSinceEpoch}_$_seq';
  }

  void credit(int amount, String reason, {DateTime? at}) {
    if (amount <= 0) return;
    final ts = (at ?? DateTime.now().toUtc()).toIso8601String();
    coinBalance += amount;
    ledger = [
      ...ledger,
      CoinLedgerEntry(
        id: _nextId('c'),
        type: 'credit',
        amount: amount,
        reason: reason,
        atIso: ts,
      ),
    ];
  }

  bool debit(int amount, String reason, {DateTime? at}) {
    if (amount <= 0) return false;
    if (coinBalance < amount) return false;
    final ts = (at ?? DateTime.now().toUtc()).toIso8601String();
    coinBalance -= amount;
    ledger = [
      ...ledger,
      CoinLedgerEntry(
        id: _nextId('d'),
        type: 'debit',
        amount: amount,
        reason: reason,
        atIso: ts,
      ),
    ];
    return true;
  }

  bool tryDebitChat() => debit(coinCostChat, 'chat');

  /// Returns granted amount, or null if already claimed today.
  int? claimCheckin({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    if (lastCheckinUtcDay == d) return null;

    if (lastCheckinUtcDay == _prevUtcDay(d)) {
      checkinStreak += 1;
    } else {
      checkinStreak = 1;
    }
    lastCheckinUtcDay = d;
    final amount =
        checkinStreak > 0 && checkinStreak % 7 == 0
            ? coinCheckinStreak7
            : coinCheckinDaily;
    credit(amount, 'checkin');
    return amount;
  }

  void markTaskChatProgress({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    taskChatProgressUtcDay = d;
  }

  int? claimTaskChat({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    if (taskChatClaimedUtcDay == d) return null;
    if (taskChatProgressUtcDay != d) return null;
    taskChatClaimedUtcDay = d;
    credit(coinTaskChat, 'task_chat');
    return coinTaskChat;
  }

  void markTaskStoryImpressProgress({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    taskStoryImpressProgressUtcDay = d;
  }

  int? claimTaskStoryImpress({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    if (taskStoryImpressClaimedUtcDay == d) return null;
    if (taskStoryImpressProgressUtcDay != d) return null;
    taskStoryImpressClaimedUtcDay = d;
    credit(coinTaskStoryImpress, 'task_story_impress');
    return coinTaskStoryImpress;
  }

  void markTaskCustomMediaProgress({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    taskCustomMediaProgressUtcDay = d;
  }

  int? claimTaskCustomMedia({String? day}) {
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    if (taskCustomMediaClaimedUtcDay == d) return null;
    if (taskCustomMediaProgressUtcDay != d) return null;
    taskCustomMediaClaimedUtcDay = d;
    credit(coinTaskCustomMedia, 'task_custom_media');
    return coinTaskCustomMedia;
  }

  String ensureInviteCode() {
    if (inviteCode != null && inviteCode!.isNotEmpty) return inviteCode!;
    inviteCode =
        'LP${DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    return inviteCode!;
  }

  int? redeemInviteAsInviter() {
    if (inviteInviterRedeemed) return null;
    inviteInviterRedeemed = true;
    credit(coinInviteInviter, 'invite_inviter');
    return coinInviteInviter;
  }

  int? redeemInviteAsInvitee(String code) {
    if (inviteInviteeRedeemed) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    if (inviteCode != null && trimmed == inviteCode) return null;
    inviteInviteeRedeemed = true;
    credit(coinInviteInvitee, 'invite_invitee');
    return coinInviteInvitee;
  }

  String submitFeedback({required String type, required String body}) {
    final id = _nextId('fb');
    feedbacks = [
      ...feedbacks,
      FeedbackRecord(
        id: id,
        type: type,
        body: body,
        createdAtIso: DateTime.now().toUtc().toIso8601String(),
      ),
    ];
    return id;
  }

  int? adoptFeedback(String id) {
    final idx = feedbacks.indexWhere((f) => f.id == id);
    if (idx < 0) return null;
    final f = feedbacks[idx];
    if (f.rewardGranted || f.status == 'adopted') return null;
    f.status = 'adopted';
    f.rewardGranted = true;
    credit(coinFeedbackAdopted, 'feedback_adopted');
    return coinFeedbackAdopted;
  }

  void applySimulatedSub(String sku) {
    final s = sku.toLowerCase();
    if (s.contains('month') ||
        s.contains('year') ||
        s == 'member' ||
        s.startsWith('sub_')) {
      isMemberSimulated = true;
    }
    if (s == 'sub_monthly' || s == 'monthly') {
      credit(coinSubGrantMonthly, 'sub_grant');
    } else if (s == 'sub_yearly' || s == 'yearly') {
      // Yearly: one monthly-equivalent grant (thin Should).
      credit(coinSubGrantMonthly, 'sub_grant');
    }
  }

  int? ensureMemberDailyGrant({String? day}) {
    if (!isMemberSimulated) return null;
    final d = day ?? _todayUtc();
    ensureUtcDay(d);
    if (memberDailyGrantUtcDay == d) return null;
    memberDailyGrantUtcDay = d;
    credit(coinMemberDailyGrant, 'member_daily');
    return coinMemberDailyGrant;
  }

  Map<String, dynamic> toJson() => {
        'isMemberSimulated': isMemberSimulated,
        'storiesUsedToday': storiesUsedToday,
        'repliesUsedToday': repliesUsedToday,
        'imagesUsedLifetime': imagesUsedLifetime,
        'utcDay': utcDay,
        'coinBalance': coinBalance,
        'ledger': ledger.map((e) => e.toJson()).toList(),
        'lastCheckinUtcDay': lastCheckinUtcDay,
        'checkinStreak': checkinStreak,
        'taskChatProgressUtcDay': taskChatProgressUtcDay,
        'taskChatClaimedUtcDay': taskChatClaimedUtcDay,
        'taskStoryImpressProgressUtcDay': taskStoryImpressProgressUtcDay,
        'taskStoryImpressClaimedUtcDay': taskStoryImpressClaimedUtcDay,
        'taskCustomMediaProgressUtcDay': taskCustomMediaProgressUtcDay,
        'taskCustomMediaClaimedUtcDay': taskCustomMediaClaimedUtcDay,
        'inviteCode': inviteCode,
        'inviteInviterRedeemed': inviteInviterRedeemed,
        'inviteInviteeRedeemed': inviteInviteeRedeemed,
        'memberDailyGrantUtcDay': memberDailyGrantUtcDay,
        'feedbacks': feedbacks.map((e) => e.toJson()).toList(),
        'seq': _seq,
      };

  factory Economy.fromJson(Map<String, dynamic> j) {
    final e = Economy(
      isMemberSimulated: j['isMemberSimulated'] as bool? ?? false,
      storiesUsedToday: j['storiesUsedToday'] as int? ?? 0,
      repliesUsedToday: j['repliesUsedToday'] as int? ?? 0,
      imagesUsedLifetime: j['imagesUsedLifetime'] as int? ?? 0,
      utcDay: j['utcDay'] as String?,
      coinBalance: j['coinBalance'] as int? ?? 0,
      ledger: (j['ledger'] as List? ?? [])
          .map((e) =>
              CoinLedgerEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastCheckinUtcDay: j['lastCheckinUtcDay'] as String?,
      checkinStreak: j['checkinStreak'] as int? ?? 0,
      taskChatProgressUtcDay: j['taskChatProgressUtcDay'] as String?,
      taskChatClaimedUtcDay: j['taskChatClaimedUtcDay'] as String?,
      taskStoryImpressProgressUtcDay:
          j['taskStoryImpressProgressUtcDay'] as String?,
      taskStoryImpressClaimedUtcDay:
          j['taskStoryImpressClaimedUtcDay'] as String?,
      taskCustomMediaProgressUtcDay:
          j['taskCustomMediaProgressUtcDay'] as String?,
      taskCustomMediaClaimedUtcDay:
          j['taskCustomMediaClaimedUtcDay'] as String?,
      inviteCode: j['inviteCode'] as String?,
      inviteInviterRedeemed: j['inviteInviterRedeemed'] as bool? ?? false,
      inviteInviteeRedeemed: j['inviteInviteeRedeemed'] as bool? ?? false,
      memberDailyGrantUtcDay: j['memberDailyGrantUtcDay'] as String?,
      feedbacks: (j['feedbacks'] as List? ?? [])
          .map((e) =>
              FeedbackRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      seq: j['seq'] as int? ?? 0,
    );
    e.ensureUtcDay();
    return e;
  }
}
