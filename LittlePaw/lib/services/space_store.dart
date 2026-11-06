import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/comment.dart';
import '../models/custom_character.dart';
import '../models/pet.dart';
import '../models/story.dart';
import 'economy.dart';
import 'event_log.dart';
import 'feed_fill.dart';
import 'image_gen_service.dart';
import 'life_scripts.dart';
import 'pet_subject_media.dart';
import 'quota_ui.dart';
import 'role_gen_capabilities.dart';
import 'seo_web_gate.dart';

/// Local space persistence — pet, stories, comments, economy, events, flags.
class SpaceStore extends ChangeNotifier {
  static const _key = 'little_paw_space_v1';

  Pet? pet;
  List<Story> stories = [];
  List<CommentThread> comments = [];
  late Economy economy;
  final EventLog eventLog = EventLog();

  bool welcomeSeen = false;
  bool onboardingComplete = false;
  bool commentGuideDone = false;
  bool commentGuideSkipped = false;
  bool localeZh = true;
  bool hadQuotaHit = false;
  String? lastQuotaHitUtcDay;
  String? lastIntentChoice;
  String? intentNote;

  Set<String> impressedStoryIds = {};

  /// When set, HomeShell switches to Feed and FeedTab scrolls/highlights.
  String? focusStoryId;

  /// When set, HomeShell selects this tab index (0 feed / 1 activity / 2 world / 3 profile).
  int? pendingShellTab;

  /// One-shot toast after auto task credit: amount to show as「+N 金币」.
  int? pendingCoinToastAmount;

  /// D-20 F2: show stories/post exhausted strip only after a successful post.
  bool pendingPostQuotaWall = false;
  bool customMediaFlowInFlight = false;

  /// D2-07: set when persisted JSON fails to parse; UI shows one-shot notice.
  bool loadCorrupt = false;
  bool loadCorruptAcknowledged = false;

  /// D2-10: when false, formal intent entry is paused (Profile + quota secondary).
  bool intentEntryEnabled = true;

  /// D-03 local optimistic likes.
  Set<String> likedStoryIds = {};

  /// Optional visual fill (≥6 cards). Product default false (off).
  bool feedDemoFillEnabled = false;

  /// D-04 / P-03: INS PostCard layout. false → classic text cards.
  bool insFeedLayoutEnabled = true;

  /// LP-P-07: full-screen story ring player (default on).
  bool storiesRingPlayerEnabled = true;

  /// LP-P-07: Feed main media must be pet-subject (default on).
  bool feedPetSubjectMediaOnly = true;

  /// LP-P-07: Activity tab = chat primary path (default on).
  bool activityChatPrimaryEnabled = true;

  /// LP-P-08: custom local photo → Feed post (default on).
  bool customMediaToFeedEnabled = true;

  /// LP-P-08: legacy open-box illustration card (default off).
  bool interactiveBoxCardLegacyEnabled = false;

  /// LP-DEV-09.2: Profile debug tools (INS toggle / hypothesis prices). Default hidden.
  bool profileDebugToolsVisible = false;

  /// LP-P-09 / D-10: hide fake claw + like/comment skeleton posts (default on).
  bool feedNoFakePlaceholderPosts = true;

  /// LP-P-09 / D-10: story X must dismiss (default on).
  bool storyCloseDismisses = true;

  /// LP-P-09 / D-10: formal quota wall only after first-session core (default on).
  bool quotaWallAfterFirstSessionCore = true;

  /// LP-P-12 / D-12: Profile「我的动态」只读入口（default on）.
  bool profileMyPostsReadonlyEnabled = true;

  /// Rings the user entered and dismissed (X / back) this install.
  Set<String> coreDismissedRingIds = {};

  /// Opening story all frames completed.
  bool coreOpeningCompleted = false;

  /// At least one successful custom media post.
  bool coreCustomPosted = false;

  /// UTC day stamp for in-progress core gate; incomplete resets on day change.
  String? coreProgressUtcDay;

  /// Once true, stays true (install-level latch after core done).
  bool firstSessionCoreLatched = false;

  /// LP-DEV-19b: daily exposure completed (impress or empty skip).
  /// Legacy `firstDailyCompleted` migrates into this on import.
  bool dailyExposureCompleted = false;

  /// LP-DEV-19b: soft coach sheet actually presented (after visible).
  bool firstDailyCoachShown = false;

  /// LP-DEV-19b: pin guide consumed (only after pin was presented + soft dismiss).
  bool firstDailyPinConsumed = false;

  /// Pin was rendered at least once this install/session path.
  bool firstDailyPinPresented = false;

  Timer? _pinSoftDismissTimer;

  /// LP-DEV-19: chat blocked because first-daily gate not satisfied.
  bool lastChatBlockedByFirstDaily = false;

  /// Legacy alias — prefer [dailyExposureCompleted]. Kept for migration/tests.
  bool get firstDailyCompleted => dailyExposureCompleted;
  set firstDailyCompleted(bool v) => dailyExposureCompleted = v;

  /// Local chat history for SCR-06-CHAT (guest-safe).
  List<ChatMessage> chatMessages = [];

  /// LP-P-17 local custom characters (not marketplace).
  List<CustomCharacter> customCharacters = [];

  /// Selected custom character id for light companion pick.
  String? selectedCustomCharacterId;

  /// Rings marked seen after finishing player content.
  Set<String> seenRingIds = {};

  /// ISO8601 UTC stamp refreshed on every persist (cloud sync).
  String? updatedAt;

  /// Optional hook after local persist (e.g. cloud upsert when signed in).
  Future<void> Function(Map<String, dynamic> state)? onAfterPersist;

  bool get hasPet => pet != null;

  int get unreadStoryCount =>
      stories.where((s) => !s.isOnboarding && s.isUnread).length;

  int get unreadReplyCount => comments.where((c) => c.replyUnread).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    economy = Economy();
    if (raw == null) {
      notifyListeners();
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      await importStateJson(j, notify: false);
    } catch (_) {
      // Keep defaults on corrupt payload; expose flag for one-shot UI (D2-07).
      loadCorrupt = true;
      loadCorruptAcknowledged = false;
      pet = null;
      stories = [];
      comments = [];
      economy = Economy();
      eventLog.loadFromJsonList([]);
      welcomeSeen = false;
      onboardingComplete = false;
    }
    notifyListeners();
  }

  /// Snapshot for local disk / cloud (includes refreshed updatedAt when [touch] is true).
  Map<String, dynamic> exportStateJson({bool touch = false}) {
    if (touch || updatedAt == null || updatedAt!.isEmpty) {
      updatedAt = DateTime.now().toUtc().toIso8601String();
    }
    return {
      'pet': pet?.toJson(),
      'stories': stories.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
      'economy': economy.toJson(),
      'events': eventLog.toJsonList(),
      'welcomeSeen': welcomeSeen,
      'onboardingComplete': onboardingComplete,
      'commentGuideDone': commentGuideDone,
      'commentGuideSkipped': commentGuideSkipped,
      'localeZh': localeZh,
      'hadQuotaHit': hadQuotaHit,
      'lastQuotaHitUtcDay': lastQuotaHitUtcDay,
      'lastIntentChoice': lastIntentChoice,
      'intentNote': intentNote,
      'impressedStoryIds': impressedStoryIds.toList(),
      'intentEntryEnabled': intentEntryEnabled,
      'likedStoryIds': likedStoryIds.toList(),
      'feedDemoFillEnabled': feedDemoFillEnabled,
      'insFeedLayoutEnabled': insFeedLayoutEnabled,
      'storiesRingPlayerEnabled': storiesRingPlayerEnabled,
      'feedPetSubjectMediaOnly': feedPetSubjectMediaOnly,
      'activityChatPrimaryEnabled': activityChatPrimaryEnabled,
      'customMediaToFeedEnabled': customMediaToFeedEnabled,
      'interactiveBoxCardLegacyEnabled': interactiveBoxCardLegacyEnabled,
      'feedNoFakePlaceholderPosts': feedNoFakePlaceholderPosts,
      'storyCloseDismisses': storyCloseDismisses,
      'quotaWallAfterFirstSessionCore': quotaWallAfterFirstSessionCore,
      'profileMyPostsReadonlyEnabled': profileMyPostsReadonlyEnabled,
      'coreDismissedRingIds': coreDismissedRingIds.toList(),
      'coreOpeningCompleted': coreOpeningCompleted,
      'coreCustomPosted': coreCustomPosted,
      'coreProgressUtcDay': coreProgressUtcDay,
      'firstSessionCoreLatched': firstSessionCoreLatched,
      'dailyExposureCompleted': dailyExposureCompleted,
      'firstDailyCompleted': dailyExposureCompleted, // legacy mirror
      'firstDailyCoachShown': firstDailyCoachShown,
      'firstDailyPinConsumed': firstDailyPinConsumed,
      'firstDailyPinPresented': firstDailyPinPresented,
      'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
      'customCharacters': customCharacters.map((e) => e.toJson()).toList(),
      'selectedCustomCharacterId': selectedCustomCharacterId,
      'seenRingIds': seenRingIds.toList(),
      'updatedAt': updatedAt,
    };
  }

  /// Apply a state map (from disk or cloud). Does not persist by itself.
  Future<void> importStateJson(
    Map<String, dynamic> j, {
    bool notify = true,
  }) async {
    try {
      if (j['pet'] != null) {
        pet = Pet.fromJson(Map<String, dynamic>.from(j['pet'] as Map));
      } else {
        pet = null;
      }
      stories = (j['stories'] as List? ?? [])
          .map((e) => Story.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      comments = (j['comments'] as List? ?? [])
          .map(
            (e) => CommentThread.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      economy = Economy.fromJson(
        Map<String, dynamic>.from(j['economy'] as Map? ?? {}),
      );
      eventLog.loadFromJsonList(j['events'] as List? ?? []);
      welcomeSeen = j['welcomeSeen'] as bool? ?? false;
      onboardingComplete = j['onboardingComplete'] as bool? ?? false;
      commentGuideDone = j['commentGuideDone'] as bool? ?? false;
      commentGuideSkipped = j['commentGuideSkipped'] as bool? ?? false;
      localeZh = j['localeZh'] as bool? ?? true;
      hadQuotaHit = j['hadQuotaHit'] as bool? ?? false;
      lastQuotaHitUtcDay = j['lastQuotaHitUtcDay'] as String?;
      lastIntentChoice = j['lastIntentChoice'] as String?;
      intentNote = j['intentNote'] as String?;
      impressedStoryIds = Set<String>.from(
        (j['impressedStoryIds'] as List? ?? []).cast<String>(),
      );
      intentEntryEnabled = j['intentEntryEnabled'] as bool? ?? true;
      likedStoryIds = Set<String>.from(
        (j['likedStoryIds'] as List? ?? []).cast<String>(),
      );
      feedDemoFillEnabled = j['feedDemoFillEnabled'] as bool? ?? false;
      insFeedLayoutEnabled = j['insFeedLayoutEnabled'] as bool? ?? true;
      storiesRingPlayerEnabled = j['storiesRingPlayerEnabled'] as bool? ?? true;
      feedPetSubjectMediaOnly = j['feedPetSubjectMediaOnly'] as bool? ?? true;
      activityChatPrimaryEnabled =
          j['activityChatPrimaryEnabled'] as bool? ?? true;
      customMediaToFeedEnabled = j['customMediaToFeedEnabled'] as bool? ?? true;
      interactiveBoxCardLegacyEnabled =
          j['interactiveBoxCardLegacyEnabled'] as bool? ?? false;
      feedNoFakePlaceholderPosts =
          j['feedNoFakePlaceholderPosts'] as bool? ?? true;
      storyCloseDismisses = j['storyCloseDismisses'] as bool? ?? true;
      quotaWallAfterFirstSessionCore =
          j['quotaWallAfterFirstSessionCore'] as bool? ?? true;
      profileMyPostsReadonlyEnabled =
          j['profileMyPostsReadonlyEnabled'] as bool? ?? true;
      coreDismissedRingIds = Set<String>.from(
        (j['coreDismissedRingIds'] as List? ?? []).cast<String>(),
      );
      coreOpeningCompleted = j['coreOpeningCompleted'] as bool? ?? false;
      coreCustomPosted = j['coreCustomPosted'] as bool? ?? false;
      coreProgressUtcDay = j['coreProgressUtcDay'] as String?;
      firstSessionCoreLatched = j['firstSessionCoreLatched'] as bool? ?? false;
      dailyExposureCompleted =
          j['dailyExposureCompleted'] as bool? ??
          j['firstDailyCompleted'] as bool? ??
          false;
      firstDailyCoachShown = j['firstDailyCoachShown'] as bool? ?? false;
      firstDailyPinConsumed = j['firstDailyPinConsumed'] as bool? ?? false;
      firstDailyPinPresented = j['firstDailyPinPresented'] as bool? ?? false;
      chatMessages = (j['chatMessages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      customCharacters = (j['customCharacters'] as List? ?? [])
          .map(
            (e) =>
                CustomCharacter.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      selectedCustomCharacterId = j['selectedCustomCharacterId'] as String?;
      seenRingIds = Set<String>.from(
        (j['seenRingIds'] as List? ?? []).cast<String>(),
      );
      final rawAt = j['updatedAt'];
      updatedAt = rawAt?.toString();
      loadCorrupt = false;
    } catch (_) {
      loadCorrupt = true;
      loadCorruptAcknowledged = false;
      pet = null;
      stories = [];
      comments = [];
      economy = Economy();
      eventLog.loadFromJsonList([]);
      welcomeSeen = false;
      onboardingComplete = false;
      chatMessages = [];
      customCharacters = [];
      selectedCustomCharacterId = null;
      seenRingIds = {};
    }
    if (notify) notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final j = exportStateJson(touch: true);
    await prefs.setString(_key, jsonEncode(j));
  }

  Future<void> persist() async {
    await save();
    notifyListeners();
    final hook = onAfterPersist;
    if (hook != null) {
      try {
        await hook(exportStateJson(touch: false));
      } catch (e) {
        debugPrint('SpaceStore.onAfterPersist failed: $e');
      }
    }
  }

  Future<void> setLocaleZh(bool zh) async {
    localeZh = zh;
    await persist();
  }

  Future<void> markWelcomeSeen() async {
    welcomeSeen = true;
    await persist();
  }

  Future<void> createPet(Pet p) async {
    pet = p;
    stories = LifeScripts.onboardingStories(p.name);
    comments = [];
    chatMessages = [];
    customCharacters = [];
    selectedCustomCharacterId = null;
    seenRingIds = {};
    onboardingComplete = false;
    commentGuideDone = false;
    commentGuideSkipped = false;
    impressedStoryIds = {};
    dailyExposureCompleted = false;
    firstDailyCoachShown = false;
    firstDailyPinConsumed = false;
    firstDailyPinPresented = false;
    lastChatBlockedByFirstDaily = false;
    economy = Economy();
    await persist();
  }

  CustomCharacter? get selectedCustomCharacter {
    final id = selectedCustomCharacterId;
    if (id == null) return null;
    for (final c in customCharacters) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Create + persist custom character; debit only after successful save.
  Future<CreateCustomCharacterResult> createCustomCharacter({
    required String name,
    required String blurb,
    String? species,
    String? tone,
  }) async {
    if (!RoleGenCapabilities.customCharacterEnabled) {
      return const CreateCustomCharacterResult(ok: false, unavailable: true);
    }
    final n = name.trim();
    final b = blurb.trim();
    if (n.isEmpty || b.isEmpty) {
      return const CreateCustomCharacterResult(
        ok: false,
        validationFailed: true,
      );
    }
    economy.ensureUtcDay();
    if (economy.coinBalance < Economy.coinCostCustomCharacter) {
      eventLog.log(
        'coin_insufficient',
        props: {
          'reason': 'coin_cost_custom_character',
          'balance': economy.coinBalance,
          'need': Economy.coinCostCustomCharacter,
        },
      );
      await persist();
      return const CreateCustomCharacterResult(
        ok: false,
        blockedInsufficient: true,
      );
    }
    final id =
        'cc_${DateTime.now().toUtc().millisecondsSinceEpoch}_${customCharacters.length}';
    final character = CustomCharacter(
      id: id,
      name: n,
      blurb: b,
      species: species?.trim().isEmpty == true ? null : species?.trim(),
      tone: tone?.trim().isEmpty == true ? null : tone?.trim(),
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    customCharacters = [...customCharacters, character];
    // Persist first; only then debit (success-after-disk).
    try {
      await persist();
    } catch (_) {
      customCharacters = customCharacters
          .where((c) => c.id != character.id)
          .toList();
      return const CreateCustomCharacterResult(ok: false, persistFailed: true);
    }
    final debited = economy.debit(
      Economy.coinCostCustomCharacter,
      'coin_cost_custom_character',
    );
    if (!debited) {
      // Race: balance changed — roll back character.
      customCharacters = customCharacters
          .where((c) => c.id != character.id)
          .toList();
      await persist();
      return const CreateCustomCharacterResult(
        ok: false,
        blockedInsufficient: true,
      );
    }
    eventLog.log(
      'coin_debit',
      props: {
        'amount': Economy.coinCostCustomCharacter,
        'reason': 'coin_cost_custom_character',
      },
    );
    eventLog.log(
      'character_create_success',
      props: {'character_id': character.id},
    );
    await persist();
    return CreateCustomCharacterResult(ok: true, character: character);
  }

  Future<void> selectCustomCharacter(String? id) async {
    if (id == null) {
      selectedCustomCharacterId = null;
      await persist();
      return;
    }
    final exists = customCharacters.any((c) => c.id == id);
    if (!exists) return;
    selectedCustomCharacterId = id;
    eventLog.log('character_select', props: {'character_id': id});
    await persist();
  }

  /// Image gen path — fail-closed when AI stack unavailable; never fake debit.
  Future<GenerateImageStoreResult> generateImage({
    required String prompt,
  }) async {
    if (!RoleGenCapabilities.imageGenEnabled || !ImageGenService.isAvailable) {
      eventLog.log(
        'image_gen_unavailable',
        props: {'prompt_len': prompt.length},
      );
      await persist();
      return const GenerateImageStoreResult(ok: false, unavailable: true);
    }
    economy.ensureUtcDay();
    if (economy.coinBalance < Economy.coinCostImageGen) {
      eventLog.log(
        'coin_insufficient',
        props: {
          'reason': 'coin_cost_image_gen',
          'balance': economy.coinBalance,
          'need': Economy.coinCostImageGen,
        },
      );
      await persist();
      return const GenerateImageStoreResult(
        ok: false,
        blockedInsufficient: true,
      );
    }
    final r = await ImageGenService.generate(prompt: prompt);
    if (!r.ok || r.imageBytesOrPath == null || r.imageBytesOrPath!.isEmpty) {
      eventLog.log(
        'image_gen_fail',
        props: {'unavailable': r.unavailable, 'error': r.errorMessage ?? ''},
      );
      await persist();
      return GenerateImageStoreResult(
        ok: false,
        unavailable: r.unavailable,
        errorMessage: r.errorMessage,
      );
    }
    final debited = economy.debit(
      Economy.coinCostImageGen,
      'coin_cost_image_gen',
    );
    if (!debited) {
      return const GenerateImageStoreResult(
        ok: false,
        blockedInsufficient: true,
      );
    }
    eventLog.log(
      'coin_debit',
      props: {
        'amount': Economy.coinCostImageGen,
        'reason': 'coin_cost_image_gen',
      },
    );
    eventLog.log('image_gen_success', props: {});
    await persist();
    return GenerateImageStoreResult(
      ok: true,
      imageBytesOrPath: r.imageBytesOrPath,
    );
  }

  /// LP-P-10 / DEV-11: rename local pet without resetting space.
  static const int petNameMaxLen = 20;

  Future<void> renamePet(String raw) async {
    if (pet == null) {
      throw StateError('no pet');
    }
    final name = raw.trim();
    if (name.isEmpty) {
      throw ArgumentError('empty name');
    }
    final capped = name.length <= petNameMaxLen
        ? name
        : name.substring(0, petNameMaxLen);
    if (pet!.name == capped) return;
    pet = pet!.copyWith(name: capped);
    await persist();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    // Mark onboarding stories read when entering feed.
    stories = stories
        .map((s) => s.isOnboarding ? s.copyWith(isUnread: false) : s)
        .toList();
    // Seed today's feed stories within free quota.
    await ensureDailyStories();
    await persist();
  }

  Future<void> ensureDailyStories() async {
    if (pet == null) return;
    economy.ensureUtcDay();
    final day = economy.utcDay;
    final already = stories.any((s) => s.id.startsWith('day_$day'));
    if (already) return;
    final want = economy.storiesLimit;
    final batch = LifeScripts.dailyStories(pet!.name, day, count: want);
    stories = [...batch, ...stories];
    await save();
  }

  Future<void> onAppOpen() async {
    final prevHitDay = lastQuotaHitUtcDay;
    economy.ensureUtcDay();
    final today = economy.utcDay;
    final afterQuota = hadQuotaHit && prevHitDay != null && prevHitDay != today;
    eventLog.appOpen(afterQuota: afterQuota);
    if (afterQuota) {
      hadQuotaHit = false;
    }
    if (onboardingComplete) {
      await ensureDailyStories();
    }
    await persist();
  }

  Future<void> markStoryImpressed(String storyId, {String? source}) async {
    if (impressedStoryIds.contains(storyId)) return;
    final idx = stories.indexWhere((s) => s.id == storyId);
    final story = idx >= 0 ? stories[idx] : null;
    // Demo fill: no formal impress event, no economy consume, no task credit.
    if (story?.isDemoFill == true) {
      impressedStoryIds.add(storyId);
      if (idx >= 0 && stories[idx].isUnread) {
        stories[idx] = stories[idx].copyWith(isUnread: false);
      }
      await persist();
      return;
    }
    impressedStoryIds.add(storyId);
    eventLog.storyImpressionComplete(storyId, source: source);

    if (idx >= 0 && stories[idx].isUnread) {
      // D-20 F2: viewing/impress no longer burns「动态发帖」quota — post path does.
      stories[idx] = stories[idx].copyWith(isUnread: false);
    }
    await _tryClaimTaskStoryImpress();
    await _maybeCompleteFirstDailyFromImpress(storyId, source: source);
    await persist();
  }

  void _markQuotaHit(String type) {
    eventLog.quotaHit(type);
    hadQuotaHit = true;
    lastQuotaHitUtcDay = economy.utcDay;
  }

  /// Attempt to read/show a story under quota. Returns false if hit.
  bool canShowMoreFeedStories() {
    economy.ensureUtcDay();
    return !economy.storiesHit;
  }

  Future<CommentThread?> sendComment({
    required String storyId,
    required String text,
  }) async {
    if (pet == null) return null;
    economy.ensureUtcDay();
    if (economy.repliesHit) {
      _markQuotaHit('replies');
      await persist();
      return null;
    }
    final ok = economy.consumeReply();
    if (!ok) {
      _markQuotaHit('replies');
      await persist();
      return null;
    }
    final thread = LifeScripts.makeReply(
      storyId: storyId,
      userText: text,
      petName: pet!.name,
    );
    eventLog.commentSent(storyId, commentId: thread.id);
    comments = [thread, ...comments];
    await persist();
    return thread;
  }

  Future<void> markReplyShown(CommentThread thread) async {
    eventLog.commentReplyShown(thread.storyId, commentId: thread.id);
    final idx = comments.indexWhere((c) => c.id == thread.id);
    if (idx >= 0) {
      comments[idx] = comments[idx].copyWith(replyUnread: false);
    }
    commentGuideDone = true;
    await persist();
  }

  Future<void> skipCommentGuide() async {
    commentGuideSkipped = true;
    await persist();
  }

  Future<void> recordIntent(String choice, {String? note}) async {
    lastIntentChoice = choice;
    intentNote = note;
    eventLog.payIntentChoice(choice, note: note);
    // Intentionally does NOT set economy.isMemberSimulated.
    await persist();
  }

  Future<void> simulatePurchase(String sku) async {
    eventLog.simulatePurchase(sku);
    economy.applySimulatedSub(sku);
    economy.ensureMemberDailyGrant();
    await persist();
  }

  Future<int?> claimCheckin() async {
    final amount = economy.claimCheckin();
    if (amount == null) return null;
    eventLog.log(
      'checkin_claim',
      props: {'streak': economy.checkinStreak, 'amount': amount},
    );
    eventLog.log('coin_credit', props: {'amount': amount, 'reason': 'checkin'});
    await persist();
    return amount;
  }

  Future<int?> claimTaskChat() async {
    final amount = economy.claimTaskChat();
    if (amount == null) return null;
    eventLog.log('task_claim', props: {'task_id': 'chat', 'amount': amount});
    eventLog.log(
      'coin_credit',
      props: {'amount': amount, 'reason': 'task_chat'},
    );
    pendingCoinToastAmount = amount;
    await persist();
    return amount;
  }

  Future<int?> _tryClaimTaskStoryImpress() async {
    economy.ensureUtcDay();
    if (economy.taskStoryImpressClaimedToday) {
      eventLog.log('coin_task_cap_hit', props: {'task_id': 'story_impress'});
      return null;
    }
    economy.markTaskStoryImpressProgress();
    final amount = economy.claimTaskStoryImpress();
    if (amount == null) return null;
    eventLog.log(
      'task_claim',
      props: {'task_id': 'story_impress', 'amount': amount},
    );
    eventLog.log(
      'coin_credit',
      props: {'amount': amount, 'reason': 'task_story_impress'},
    );
    pendingCoinToastAmount = amount;
    return amount;
  }

  Future<int?> claimTaskStoryImpress() async {
    final amount = await _tryClaimTaskStoryImpress();
    if (amount == null) return null;
    await persist();
    return amount;
  }

  Future<int?> _tryClaimTaskCustomMedia() async {
    economy.ensureUtcDay();
    if (economy.taskCustomMediaClaimedToday) {
      eventLog.log('coin_task_cap_hit', props: {'task_id': 'custom_media'});
      return null;
    }
    economy.markTaskCustomMediaProgress();
    final amount = economy.claimTaskCustomMedia();
    if (amount == null) return null;
    eventLog.log(
      'task_claim',
      props: {'task_id': 'custom_media', 'amount': amount},
    );
    eventLog.log(
      'coin_credit',
      props: {'amount': amount, 'reason': 'task_custom_media'},
    );
    pendingCoinToastAmount = amount;
    return amount;
  }

  Future<int?> claimTaskCustomMedia() async {
    final amount = await _tryClaimTaskCustomMedia();
    if (amount == null) return null;
    await persist();
    return amount;
  }

  void requestShellTab(int index) {
    pendingShellTab = index;
    notifyListeners();
  }

  int? takePendingCoinToast() {
    final n = pendingCoinToastAmount;
    pendingCoinToastAmount = null;
    return n;
  }

  bool takePendingPostQuotaWall() {
    final v = pendingPostQuotaWall;
    pendingPostQuotaWall = false;
    return v;
  }

  void armCustomMediaFlowInFlight() {
    customMediaFlowInFlight = true;
    pendingPostQuotaWall = false;
    notifyListeners();
  }

  void clearCustomMediaFlowInFlight() {
    customMediaFlowInFlight = false;
    notifyListeners();
  }

  Future<String> ensureInviteCodePersisted() async {
    final code = economy.ensureInviteCode();
    await persist();
    return code;
  }

  Future<void> copyInviteShare() async {
    economy.ensureInviteCode();
    eventLog.log('invite_share', props: {'channel': 'copy'});
    await persist();
  }

  Future<int?> redeemInviteSim({required String role, String? code}) async {
    int? amount;
    if (role == 'inviter') {
      amount = economy.redeemInviteAsInviter();
    } else {
      amount = economy.redeemInviteAsInvitee(code ?? '');
    }
    if (amount == null) return null;
    eventLog.log('invite_redeem', props: {'role': role, 'amount': amount});
    eventLog.log(
      'coin_credit',
      props: {
        'amount': amount,
        'reason': role == 'inviter' ? 'invite_inviter' : 'invite_invitee',
      },
    );
    await persist();
    return amount;
  }

  Future<String?> submitFeedback({
    required String type,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.length < 5) return null;
    final id = economy.submitFeedback(type: type, body: trimmed);
    eventLog.log('feedback_submit', props: {'type': type, 'feedback_id': id});
    await persist();
    return id;
  }

  Future<int?> adoptFeedbackSim(String id) async {
    final amount = economy.adoptFeedback(id);
    if (amount == null) return null;
    eventLog.log(
      'feedback_adopted',
      props: {'feedback_id': id, 'amount': amount},
    );
    eventLog.log(
      'coin_credit',
      props: {'amount': amount, 'reason': 'feedback_adopted'},
    );
    await persist();
    return amount;
  }

  /// Last chat send blocked by coins (UI reads once).
  bool lastChatBlockedByCoins = false;

  Future<void> notifyQuotaHitIfNeeded(String type) async {
    if (type == 'stories' && economy.storiesHit) {
      _markQuotaHit('stories');
      await persist();
    } else if (type == 'replies' && economy.repliesHit) {
      _markQuotaHit('replies');
      await persist();
    }
  }

  bool isLiked(String storyId) => likedStoryIds.contains(storyId);

  Future<void> toggleLike(String storyId) async {
    if (likedStoryIds.contains(storyId)) {
      likedStoryIds.remove(storyId);
    } else {
      likedStoryIds.add(storyId);
    }
    await persist();
  }

  /// Visual feed list: real non-onboarding stories + optional demo fill.
  /// When [feedNoFakePlaceholderPosts], only pet-subject media posts (宁空勿假帖).
  List<Story> visualFeedStories() {
    var real = stories.where((s) => !s.isOnboarding).toList();
    if (feedNoFakePlaceholderPosts) {
      real = real
          .where((s) => PetSubjectMedia.isPetSubject(s.imageUrl))
          .toList();
    }
    // Classic layout: no demo fill large-image stream.
    if (!insFeedLayoutEnabled || !feedDemoFillEnabled) return real;
    final name = pet?.name ?? 'Little Paw';
    final merged = FeedFill.merge(real, name);
    if (!feedNoFakePlaceholderPosts) return merged;
    return merged
        .where((s) => PetSubjectMedia.isPetSubject(s.imageUrl))
        .toList();
  }

  bool get feedNeedsPhotoEmpty =>
      feedNoFakePlaceholderPosts && visualFeedStories().isEmpty;

  void setProfileDebugToolsVisible(bool enabled) {
    if (profileDebugToolsVisible == enabled) return;
    profileDebugToolsVisible = enabled;
    notifyListeners();
  }

  Future<void> setInsFeedLayoutEnabled(bool enabled) async {
    insFeedLayoutEnabled = enabled;
    await persist();
  }

  Future<void> setFeedDemoFillEnabled(bool enabled) async {
    feedDemoFillEnabled = enabled;
    await persist();
  }

  void acknowledgeLoadCorrupt() {
    loadCorruptAcknowledged = true;
    notifyListeners();
  }

  Future<void> setIntentEntryEnabled(bool enabled) async {
    intentEntryEnabled = enabled;
    await persist();
  }

  int get activeUtcDayCount => eventLog.activeAppOpenUtcDayCount;

  bool get s1StrongIntentOk => intentEntryEnabled && activeUtcDayCount >= 3;

  void requestFocusStory(String storyId) {
    focusStoryId = storyId;
    notifyListeners();
  }

  void clearFocusStory() {
    if (focusStoryId == null) return;
    focusStoryId = null;
    notifyListeners();
  }

  /// Bounded follow-up after first reply — appends one script story; logs event.
  Future<void> chooseFollowUp({
    required String parentStoryId,
    required String choiceZh,
    required String choiceEn,
  }) async {
    if (pet == null) return;
    final story = LifeScripts.followUpStory(
      petName: pet!.name,
      choiceLabelZh: choiceZh,
      choiceLabelEn: choiceEn,
      parentStoryId: parentStoryId,
    );
    stories = [story, ...stories];
    eventLog.log(
      'comment_followup_chosen',
      props: {
        'storyId': parentStoryId,
        'followStoryId': story.id,
        'choice_zh': choiceZh,
        'choice_en': choiceEn,
      },
    );
    await persist();
  }

  Future<void> setFeedNoFakePlaceholderPosts(bool enabled) async {
    feedNoFakePlaceholderPosts = enabled;
    await persist();
  }

  Future<void> setStoryCloseDismisses(bool enabled) async {
    storyCloseDismisses = enabled;
    await persist();
  }

  Future<void> setQuotaWallAfterFirstSessionCore(bool enabled) async {
    quotaWallAfterFirstSessionCore = enabled;
    await persist();
  }

  Future<void> setProfileMyPostsReadonlyEnabled(bool enabled) async {
    profileMyPostsReadonlyEnabled = enabled;
    await persist();
  }

  /// Boundary: incomplete core progress resets on UTC day change; latch persists.
  void _refreshCoreDayBoundary() {
    economy.ensureUtcDay();
    final day = economy.utcDay;
    if (coreProgressUtcDay == null) {
      coreProgressUtcDay = day;
      return;
    }
    if (coreProgressUtcDay != day && !firstSessionCoreLatched) {
      coreDismissedRingIds = {};
      coreOpeningCompleted = false;
      coreCustomPosted = false;
      coreProgressUtcDay = day;
    }
  }

  static const _coreRingIds = {'opening', 'friend', 'adventure'};

  bool get firstSessionCoreComplete {
    _refreshCoreDayBoundary();
    if (firstSessionCoreLatched) return true;
    final ringsOk = _coreRingIds.every(coreDismissedRingIds.contains);
    final contentOk = coreOpeningCompleted || coreCustomPosted;
    return ringsOk && contentOk;
  }

  QuotaPresentation get quotaPresentation {
    if (!quotaWallAfterFirstSessionCore) return QuotaPresentation.ready;
    return firstSessionCoreComplete
        ? QuotaPresentation.ready
        : QuotaPresentation.defer;
  }

  bool get mayAutoShowFormalQuotaWall => QuotaUi.mayAutoPresentFormalQuotaSheet(
    flagOn: quotaWallAfterFirstSessionCore,
    firstSessionCoreComplete: firstSessionCoreComplete,
  );

  Future<void> _latchCoreIfReady() async {
    if (firstSessionCoreLatched) return;
    if (!firstSessionCoreComplete) return;
    firstSessionCoreLatched = true;
    await persist();
  }

  Future<void> recordRingDismissed(String ringId) async {
    _refreshCoreDayBoundary();
    coreDismissedRingIds.add(ringId);
    await persist();
    await _latchCoreIfReady();
  }

  Future<void> recordOpeningStoryCompleted() async {
    _refreshCoreDayBoundary();
    coreOpeningCompleted = true;
    await persist();
    await _latchCoreIfReady();
  }

  Future<void> recordSuccessfulCustomPost() async {
    _refreshCoreDayBoundary();
    coreCustomPosted = true;
    await persist();
    await _latchCoreIfReady();
  }

  Future<void> setStoriesRingPlayerEnabled(bool enabled) async {
    storiesRingPlayerEnabled = enabled;
    await persist();
  }

  Future<void> setFeedPetSubjectMediaOnly(bool enabled) async {
    feedPetSubjectMediaOnly = enabled;
    await persist();
  }

  Future<void> setActivityChatPrimaryEnabled(bool enabled) async {
    activityChatPrimaryEnabled = enabled;
    await persist();
  }

  Future<void> setCustomMediaToFeedEnabled(bool enabled) async {
    customMediaToFeedEnabled = enabled;
    await persist();
  }

  Future<void> setInteractiveBoxCardLegacyEnabled(bool enabled) async {
    interactiveBoxCardLegacyEnabled = enabled;
    await persist();
  }

  /// Guest-safe: prepend a user-confirmed local-media Feed story under current pet.
  Future<Story?> addCustomMediaStory({
    required String imageUrl,
    String caption = '',
  }) async {
    if (pet == null) return null;
    if (!customMediaToFeedEnabled) return null;
    final now = DateTime.now().toUtc();
    final id = 'custom_${now.millisecondsSinceEpoch}';
    final body = caption.trim();
    final story = Story(
      id: id,
      bodyZh: body,
      bodyEn: body,
      createdAt: now,
      isOnboarding: false,
      isUnread: true,
      imageUrl: imageUrl,
      aspect: StoryAspect.ratio43,
      isDemoFill: false,
    );
    stories = [story, ...stories];
    eventLog.log('custom_media_posted', props: {'storyId': id});
    coreCustomPosted = true;
    // D-20 F2: free「动态发帖」quota consumed only on successful post.
    economy.ensureUtcDay();
    final consumed = economy.consumeStory();
    if (!consumed) {
      _markQuotaHit('stories');
    }
    if (economy.storiesHit) {
      pendingPostQuotaWall = true;
      _markQuotaHit('stories');
    }
    await _tryClaimTaskCustomMedia();
    await persist();
    await _latchCoreIfReady();
    return story;
  }

  Future<void> markRingSeen(String ringId) async {
    seenRingIds.add(ringId);
    await persist();
  }

  /// Ensure a welcome pet line exists so conversation row is meaningful.
  Future<void> ensureChatSeeded() async {
    if (pet == null) return;
    if (chatMessages.isNotEmpty) return;
    final name = pet!.name;
    chatMessages = [
      ChatMessage(
        id: 'chat_seed_1',
        sender: ChatSender.pet,
        textZh: '嗨，我是$name。今天想聊点什么？',
        textEn: 'Hi—I am $name. Want to chat a bit today?',
        createdAt: DateTime.now().toUtc(),
      ),
    ];
    await persist();
  }

  bool hasEligibleFirstDailyContent() {
    if (visualFeedStories().any((s) => !s.isDemoFill)) return true;
    // Fallback: onboarding pet-subject stories (still no fake posts).
    return stories.any(
      (s) => !s.isDemoFill && PetSubjectMedia.isPetSubject(s.imageUrl),
    );
  }

  /// Prefer visual feed non-demo; else onboarding pet-subject story.
  Story? firstDailyPinStory() {
    for (final s in visualFeedStories()) {
      if (!s.isDemoFill) return s;
    }
    for (final s in stories) {
      if (!s.isDemoFill && PetSubjectMedia.isPetSubject(s.imageUrl)) {
        return s;
      }
    }
    return null;
  }

  Future<void> markFirstDailyCoachShown() async {
    if (firstDailyCoachShown) return;
    firstDailyCoachShown = true;
    await persist();
  }

  /// Mark pin visible. Does **not** consume in the same call stack (LP-DEV-19c).
  Future<void> noteFirstDailyPinPresented() async {
    if (firstDailyPinPresented) return;
    firstDailyPinPresented = true;
    await persist();
  }

  /// Soft-dismiss when pin presented + exposure done (caller ensures dwell/order).
  Future<void> maybeConsumeFirstDailyPin() async {
    if (firstDailyPinConsumed) return;
    if (!firstDailyPinPresented) return;
    if (!dailyExposureCompleted) return;
    _pinSoftDismissTimer?.cancel();
    _pinSoftDismissTimer = null;
    firstDailyPinConsumed = true;
    await persist();
    notifyListeners();
  }

  /// User tap / open story — consume without dwell wait.
  Future<void> consumeFirstDailyPin({String reason = 'user_tap'}) async {
    if (firstDailyPinConsumed) return;
    if (!firstDailyPinPresented) {
      firstDailyPinPresented = true;
    }
    _pinSoftDismissTimer?.cancel();
    _pinSoftDismissTimer = null;
    firstDailyPinConsumed = true;
    eventLog.log('first_daily_pin_consumed', props: {'reason': reason});
    await persist();
    notifyListeners();
  }

  /// Optional helper only — NOT the default dismiss path (DEF-QA19-03 / LP-DEV-19c).
  /// Pin soft-dismiss requires explicit user interaction via [consumeFirstDailyPin].
  void scheduleFirstDailyPinSoftDismiss({
    Duration delay = const Duration(milliseconds: 2500),
  }) {
    if (firstDailyPinConsumed) return;
    if (!firstDailyPinPresented) return;
    if (!dailyExposureCompleted) return;
    _pinSoftDismissTimer?.cancel();
    _pinSoftDismissTimer = Timer(delay, () {
      maybeConsumeFirstDailyPin();
    });
  }

  void cancelFirstDailyPinSoftDismiss() {
    _pinSoftDismissTimer?.cancel();
    _pinSoftDismissTimer = null;
  }

  Future<void> _maybeCompleteFirstDailyFromImpress(
    String storyId, {
    String? source,
  }) async {
    if (!SeoWebGate.firstDailyExperimentEnabled) return;
    if (dailyExposureCompleted) return;
    dailyExposureCompleted = true;
    eventLog.log(
      'first_daily_forced_impression',
      props: {
        'storyId': storyId,
        'source': source ?? 'impress',
        'channel': 'story_or_feed',
      },
    );
    // DEF-QA19-03: exposure must NOT auto-consume pin.
  }

  /// Coach「先聊聊」/ barrier: ensure ≥1 complete exposure then unlock chat.
  /// Does **not** set [firstDailyCoachShown] — caller must mark after Sheet visible.
  Future<void> forceFirstDailyImpression({String reason = 'chat_first'}) async {
    if (!SeoWebGate.firstDailyExperimentEnabled) {
      dailyExposureCompleted = true;
      await persist();
      return;
    }
    if (dailyExposureCompleted) {
      await persist();
      return;
    }
    final eligible = visualFeedStories().where((s) => !s.isDemoFill).toList();
    if (eligible.isEmpty) {
      eventLog.log('first_daily_skipped', props: {'reason': reason});
      dailyExposureCompleted = true;
      await persist();
      return;
    }
    final st = eligible.first;
    if (!impressedStoryIds.contains(st.id)) {
      await markStoryImpressed(st.id, source: 'first_daily_forced');
    }
    if (!dailyExposureCompleted) {
      dailyExposureCompleted = true;
      eventLog.log(
        'first_daily_forced_impression',
        props: {'storyId': st.id, 'reason': reason},
      );
    } else {
      eventLog.log(
        'first_daily_forced_impression',
        props: {'storyId': st.id, 'reason': reason},
      );
    }
    await persist();
  }

  /// Feed ≥50%×1s path (counts exposure; does not swallow coach/pin by itself).
  Future<void> completeFirstDailyFromFeedView(String storyId) async {
    if (!SeoWebGate.firstDailyExperimentEnabled) return;
    if (dailyExposureCompleted) return;
    dailyExposureCompleted = true;
    eventLog.log(
      'first_daily_forced_impression',
      props: {'storyId': storyId, 'channel': 'feed_50pct_1s'},
    );
    eventLog.log(
      'feed_view',
      props: {'source': 'first_daily_complete', 'storyId': storyId},
    );
    // DEF-QA19-03: exposure must NOT auto-consume pin.
    await persist();
  }

  /// Local scripted chat send. Debits chat coins (P-14); reply quota still tracked.
  /// Returns null on coin/quota block; failed message kept on forced fail path.
  Future<ChatMessage?> sendChatMessage(
    String text, {
    bool forceFail = false,
  }) async {
    if (pet == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    economy.ensureUtcDay();
    economy.ensureMemberDailyGrant();
    lastChatBlockedByCoins = false;
    lastChatBlockedByFirstDaily = false;
    // First-daily chat gate only after entering main shell (onboarding done).
    if (SeoWebGate.firstDailyExperimentEnabled &&
        onboardingComplete &&
        !dailyExposureCompleted) {
      if (hasEligibleFirstDailyContent()) {
        lastChatBlockedByFirstDaily = true;
        eventLog.log('first_daily_chat_blocked');
        await persist();
        return null;
      }
      // Empty honest exception: allow chat + skip event.
      eventLog.log('first_daily_skipped', props: {'reason': 'empty'});
      dailyExposureCompleted = true;
    }
    if (!economy.canAffordChat) {
      lastChatBlockedByCoins = true;
      eventLog.log(
        'coin_insufficient',
        props: {'reason': 'chat', 'balance': economy.coinBalance},
      );
      await persist();
      return null;
    }
    if (economy.repliesHit) {
      _markQuotaHit('replies');
      await persist();
      return null;
    }
    final userMsg = ChatMessage(
      id: 'chat_u_${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.user,
      textZh: trimmed,
      textEn: trimmed,
      createdAt: DateTime.now().toUtc(),
      failed: forceFail,
    );
    chatMessages = [...chatMessages, userMsg];
    if (forceFail) {
      await persist();
      return userMsg;
    }
    if (!economy.tryDebitChat()) {
      lastChatBlockedByCoins = true;
      eventLog.log(
        'coin_insufficient',
        props: {'reason': 'chat', 'balance': economy.coinBalance},
      );
      chatMessages = chatMessages.where((m) => m.id != userMsg.id).toList();
      await persist();
      return null;
    }
    eventLog.log(
      'coin_debit',
      props: {'amount': Economy.coinCostChat, 'reason': 'chat'},
    );
    final ok = economy.consumeReply();
    if (!ok) {
      // Refund coin if reply quota unexpectedly blocked after debit.
      economy.credit(Economy.coinCostChat, 'chat_refund');
      _markQuotaHit('replies');
      chatMessages = [
        ...chatMessages.where((m) => m.id != userMsg.id),
        userMsg.copyWith(failed: true),
      ];
      await persist();
      return null;
    }
    final name = pet!.name;
    final reply = ChatMessage(
      id: 'chat_p_${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.pet,
      textZh: '嗯，$name 听到了：「$trimmed」。我把尾巴轻轻晃了一下。',
      textEn: 'Mm, $name heard you: "$trimmed". Tail gave a little wag.',
      createdAt: DateTime.now().toUtc().add(const Duration(milliseconds: 30)),
    );
    chatMessages = [...chatMessages, reply];
    economy.markTaskChatProgress();
    eventLog.log('chat_message_sent', props: {'messageId': userMsg.id});
    final chatReward = economy.claimTaskChat();
    if (chatReward != null) {
      eventLog.log(
        'task_claim',
        props: {'task_id': 'chat', 'amount': chatReward},
      );
      eventLog.log(
        'coin_credit',
        props: {'amount': chatReward, 'reason': 'task_chat'},
      );
      pendingCoinToastAmount = chatReward;
    }
    await persist();
    return reply;
  }

  Future<ChatMessage?> retryChatMessage(String messageId) async {
    final idx = chatMessages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return null;
    final old = chatMessages[idx];
    if (!old.failed || old.sender != ChatSender.user) return null;
    // Drop failed bubble then resend.
    chatMessages = [
      for (var i = 0; i < chatMessages.length; i++)
        if (i != idx) chatMessages[i],
    ];
    await persist();
    return sendChatMessage(old.textZh);
  }

  String chatPreview(bool zh) {
    if (chatMessages.isEmpty) {
      return zh ? '去和它聊一句吧' : 'Say hi to it';
    }
    final last = chatMessages.last;
    final prefix = last.sender == ChatSender.user
        ? (zh ? '我：' : 'You: ')
        : (zh ? '它：' : 'It: ');
    final body = last.text(zh);
    final short = body.length > 28 ? '${body.substring(0, 28)}…' : body;
    return '$prefix$short';
  }

  Future<void> resetSpace() async {
    pet = null;
    stories = [];
    comments = [];
    economy = Economy();
    eventLog.loadFromJsonList([]);
    welcomeSeen = false;
    onboardingComplete = false;
    commentGuideDone = false;
    commentGuideSkipped = false;
    hadQuotaHit = false;
    lastQuotaHitUtcDay = null;
    lastIntentChoice = null;
    intentNote = null;
    impressedStoryIds = {};
    focusStoryId = null;
    likedStoryIds = {};
    chatMessages = [];
    seenRingIds = {};
    loadCorrupt = false;
    loadCorruptAcknowledged = false;
    dailyExposureCompleted = false;
    firstDailyCoachShown = false;
    firstDailyPinConsumed = false;
    firstDailyPinPresented = false;
    lastChatBlockedByFirstDaily = false;
    // intentEntryEnabled + P-07 flags preserved across reset
    await persist();
  }
}

class CreateCustomCharacterResult {
  final bool ok;
  final bool blockedInsufficient;
  final bool validationFailed;
  final bool persistFailed;
  final bool unavailable;
  final CustomCharacter? character;

  const CreateCustomCharacterResult({
    required this.ok,
    this.blockedInsufficient = false,
    this.validationFailed = false,
    this.persistFailed = false,
    this.unavailable = false,
    this.character,
  });
}

class GenerateImageStoreResult {
  final bool ok;
  final bool unavailable;
  final bool blockedInsufficient;
  final String? errorMessage;
  final String? imageBytesOrPath;

  const GenerateImageStoreResult({
    required this.ok,
    this.unavailable = false,
    this.blockedInsufficient = false,
    this.errorMessage,
    this.imageBytesOrPath,
  });
}
