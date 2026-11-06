import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_paw/models/pet.dart';
import 'package:little_paw/services/economy.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/seo_web_gate.dart';
import 'package:little_paw/services/space_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
  });

  tearDown(() {
    SeoWebGate.hostnameOverride = null;
  });

  group('G1 predicates: exposure must not swallow coach/pin', () {
    test('exposure done + coachShown=false → shouldShowCoach true', () {
      expect(
        FirstDailyGate.shouldShowCoach(
          experimentEnabled: true,
          onboardingComplete: true,
          coachShown: false,
          // exposure ignored by design
        ),
        isTrue,
      );
      expect(
        FirstDailyGate.shouldShowCoach(
          experimentEnabled: true,
          onboardingComplete: true,
          coachShown: true,
        ),
        isFalse,
      );
    });

    test('exposure done + pinConsumed=false + content → shouldShowPin true', () {
      expect(
        FirstDailyGate.shouldShowPin(
          experimentEnabled: true,
          hasEligibleContent: true,
          pinConsumed: false,
        ),
        isTrue,
      );
      expect(
        FirstDailyGate.shouldShowPin(
          experimentEnabled: true,
          hasEligibleContent: true,
          pinConsumed: true,
        ),
        isFalse,
      );
      expect(
        FirstDailyGate.shouldShowPin(
          experimentEnabled: true,
          hasEligibleContent: false,
          pinConsumed: false,
        ),
        isFalse,
      );
    });
  });

  group('G4/G2 store: 3/3 exposure does not set coach/pin consumed', () {
    Future<SpaceStore> primed() async {
      final store = SpaceStore();
      await store.load();
      await store.createPet(Pet(
        id: 'p19b',
        name: '豆豆',
        species: 'cat',
        type: PetType.real,
        createdAt: DateTime.utc(2026, 11, 4),
      ));
      await store.completeOnboarding();
      store.economy.credit(Economy.coinCostChat * 5, 'checkin');
      await store.persist();
      return store;
    }

    test('story impress sets dailyExposureCompleted only', () async {
      final store = await primed();
      expect(store.dailyExposureCompleted, isFalse);
      expect(store.firstDailyCoachShown, isFalse);
      expect(store.firstDailyPinConsumed, isFalse);

      final id = store.visualFeedStories().firstWhere((s) => !s.isDemoFill).id;
      await store.markStoryImpressed(id, source: 'onboarding_3of3');

      expect(store.dailyExposureCompleted, isTrue);
      expect(store.firstDailyCoachShown, isFalse);
      expect(store.firstDailyPinConsumed, isFalse);
      expect(FirstDailyGate.shouldShowCoach(
        experimentEnabled: true,
        onboardingComplete: true,
        coachShown: store.firstDailyCoachShown,
      ), isTrue);
      expect(FirstDailyGate.shouldShowPin(
        experimentEnabled: true,
        hasEligibleContent: store.hasEligibleFirstDailyContent(),
        pinConsumed: store.firstDailyPinConsumed,
      ), isTrue);
    });

    test('never-pin exposure must not consume pin', () async {
      final store = await primed();
      final id = store.visualFeedStories().firstWhere((s) => !s.isDemoFill).id;
      await store.markStoryImpressed(id, source: 'feed');
      expect(store.dailyExposureCompleted, isTrue);
      expect(store.firstDailyPinConsumed, isFalse);

      // Soft-dismiss only after pin presented + exposure.
      await store.maybeConsumeFirstDailyPin();
      expect(store.firstDailyPinConsumed, isFalse);

      await store.noteFirstDailyPinPresented();
      await store.maybeConsumeFirstDailyPin();
      expect(store.firstDailyPinConsumed, isTrue);
    });

    test('forceFirstDailyImpression does not set coachShown', () async {
      final store = await primed();
      await store.forceFirstDailyImpression(reason: 'chat_first');
      expect(store.dailyExposureCompleted, isTrue);
      expect(store.firstDailyCoachShown, isFalse);
    });

    test('chat gate uses dailyExposureCompleted', () async {
      final store = await primed();
      expect(await store.sendChatMessage('blocked'), isNull);
      store.dailyExposureCompleted = true;
      await store.persist();
      expect(await store.sendChatMessage('ok'), isNotNull);
    });
  });

  group('migration', () {
    test('old firstDailyCompleted maps to dailyExposureCompleted', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SpaceStore();
      await store.load();
      await store.importStateJson({
        'economy': {},
        'events': [],
        'firstDailyCompleted': true,
        'firstDailyCoachShown': false,
        'onboardingComplete': true,
        'welcomeSeen': true,
      });
      expect(store.dailyExposureCompleted, isTrue);
      // legacy alias stays in sync for read
      expect(store.firstDailyCompleted, isTrue);
      expect(store.firstDailyCoachShown, isFalse);
      expect(store.firstDailyPinConsumed, isFalse);
    });
  });

  group('G3 coach shown timing helper', () {
    test('markShown is explicit and independent of exposure', () async {
      final store = SpaceStore();
      await store.load();
      store.dailyExposureCompleted = true;
      expect(store.firstDailyCoachShown, isFalse);
      await store.markFirstDailyCoachShown();
      expect(store.firstDailyCoachShown, isTrue);
    });
  });
}
