import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/economy.dart';

void main() {
  test('free quota truth matches handoff', () {
    expect(Economy.freeStoriesPerUtcDay, 2);
    expect(Economy.freeRepliesPerUtcDay, 10);
    expect(Economy.freeLifetimeLifetimeImagesLifetime, 3);
    expect(Economy.memberStoriesPerUtcDay, 4);
    expect(Economy.memberRepliesPerUtcDay, 40);
    expect(Economy.memberImagesPer30Days, 30);
    expect(Economy.priceMonthly, 9.90);
    expect(Economy.priceYearly, 59.0);
    expect(Economy.priceCard, 9.90);
    expect(Economy.priceBook, 19.90);
  });

  test('consume respects free caps and resets on utc day change', () {
    final e = Economy(utcDay: '2026-11-01');
    expect(e.consumeStory(), true);
    expect(e.consumeStory(), true);
    expect(e.consumeStory(), false);
    expect(e.storiesHit, true);

    for (var i = 0; i < 10; i++) {
      expect(e.consumeReply(), true);
    }
    expect(e.consumeReply(), false);

    e.ensureUtcDay('2026-11-02');
    expect(e.storiesUsedToday, 0);
    expect(e.repliesUsedToday, 0);
    expect(e.consumeStory(), true);
  });

  test('member limits apply when simulated', () {
    final e = Economy(isMemberSimulated: true, utcDay: '2026-11-01');
    expect(e.storiesLimit, 4);
    expect(e.repliesLimit, 40);
  });
}
