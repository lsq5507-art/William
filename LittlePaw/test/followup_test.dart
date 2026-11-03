import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/life_scripts.dart';

void main() {
  test('DEF-02: follow-up choices are wired from LifeScripts pairs', () {
    final zh = LifeScripts.followUpPair(true);
    final en = LifeScripts.followUpPair(false);
    expect(zh.length, 2);
    expect(en.length, 2);
    expect(zh, LifeScripts.followUpChoicesZh.first);
    expect(en, LifeScripts.followUpChoicesEn.first);

    final story = LifeScripts.followUpStory(
      petName: 'Mochi',
      choiceLabelZh: zh[0],
      choiceLabelEn: en[0],
      parentStoryId: 'day_1',
    );
    expect(story.isOnboarding, false);
    expect(story.bodyZh.contains(zh[0]), true);
    expect(story.bodyEn.contains(en[0]), true);
  });
}
