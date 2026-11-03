import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/comment.dart';
import '../models/pet.dart';
import '../models/story.dart';
import 'economy.dart';
import 'event_log.dart';
import 'life_scripts.dart';

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
      if (j['pet'] != null) {
        pet = Pet.fromJson(Map<String, dynamic>.from(j['pet'] as Map));
      }
      stories = (j['stories'] as List? ?? [])
          .map((e) => Story.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      comments = (j['comments'] as List? ?? [])
          .map((e) => CommentThread.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      economy = Economy.fromJson(
          Map<String, dynamic>.from(j['economy'] as Map? ?? {}));
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
      impressedStoryIds =
          Set<String>.from((j['impressedStoryIds'] as List? ?? []).cast<String>());
    } catch (_) {
      // Keep defaults on corrupt payload.
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final j = {
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
    };
    await prefs.setString(_key, jsonEncode(j));
  }

  Future<void> persist() async {
    await save();
    notifyListeners();
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
    onboardingComplete = false;
    commentGuideDone = false;
    commentGuideSkipped = false;
    impressedStoryIds = {};
    economy = Economy();
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
    final afterQuota = hadQuotaHit &&
        prevHitDay != null &&
        prevHitDay != today;
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
    impressedStoryIds.add(storyId);
    eventLog.storyImpressionComplete(storyId, source: source);

    final idx = stories.indexWhere((s) => s.id == storyId);
    if (idx >= 0 && stories[idx].isUnread) {
      // Consume quota only for non-onboarding feed stories when marking read.
      if (!stories[idx].isOnboarding) {
        final ok = economy.consumeStory();
        if (!ok) {
          _markQuotaHit('stories');
        }
      }
      stories[idx] = stories[idx].copyWith(isUnread: false);
    }
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
    if (sku == 'monthly' || sku == 'yearly' || sku == 'member') {
      economy.isMemberSimulated = true;
    }
    await persist();
  }

  Future<void> notifyQuotaHitIfNeeded(String type) async {
    if (type == 'stories' && economy.storiesHit) {
      _markQuotaHit('stories');
      await persist();
    } else if (type == 'replies' && economy.repliesHit) {
      _markQuotaHit('replies');
      await persist();
    }
  }


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
    eventLog.log('comment_followup_chosen', props: {
      'storyId': parentStoryId,
      'followStoryId': story.id,
      'choice_zh': choiceZh,
      'choice_en': choiceEn,
    });
    await persist();
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
    await persist();
  }
}
