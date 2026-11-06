import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/l10n/strings.dart';
import 'package:little_paw/world/mock/world_mock_data.dart';
import 'package:little_paw/world/models/world_models.dart';
import 'package:little_paw/world/world_store.dart';

void main() {
  test('world mock has 8 story posts and market items', () {
    final posts = WorldMockData.posts();
    expect(posts.length, greaterThanOrEqualTo(8));
    expect(WorldMockData.pets().length, greaterThanOrEqualTo(8));
    expect(WorldMockData.market(), isNotEmpty);
    expect(posts.every((p) => p.imageAsset.startsWith('assets/world_feed/')), true);
  });

  test('world store like and comment and acquire', () {
    final store = WorldStore();
    final id = store.posts.first.id;
    final before = store.posts.first.likeCount;
    store.toggleLike(id);
    expect(store.posts.first.liked, true);
    expect(store.posts.first.likeCount, before + 1);
    store.addComment(id, zh: true, text: '加油');
    expect(store.posts.first.comments.last.textZh, '加油');
    final mkt = store.market.firstWhere((e) => e.status == MarketAcquireStatus.locked);
    store.startTrial(mkt.id);
    expect(
      store.market.firstWhere((e) => e.id == mkt.id).status,
      MarketAcquireStatus.trial,
    );
    store.demoAcquire(mkt.id);
    expect(
      store.market.firstWhere((e) => e.id == mkt.id).status,
      MarketAcquireStatus.owned,
    );
  });

  test('world l10n keys EN/ZH product tone (no demo labels)', () {
    final zh = S(true);
    final en = S(false);
    expect(zh.get('world.seg.feed'), '朋友圈');
    expect(en.get('world.seg.feed'), 'Moments');
    expect(zh.get('world.cta.demo_acquire').contains('演示'), false);
    expect(zh.get('world.cta.demo_acquire'), '获取');
    expect(en.get('world.cta.demo_acquire').toLowerCase().contains('demo'), false);
    expect(en.get('world.cta.demo_acquire'), 'Acquire');
    expect(zh.get('world.demo.title').contains('演示'), false);
    expect(zh.get('world.market.blurb').contains('演示'), false);
    expect(en.get('world.market.blurb').toLowerCase().contains('demo'), false);
    expect(zh.get('world.top.add_toast').contains('演示'), false);
    expect(zh.get('world.top.messages_toast').contains('占位'), false);
  });

  test('market taglines have no demo acquire labels', () {
    for (final item in WorldMockData.market()) {
      expect(item.taglineZh.contains('演示'), false);
      expect(item.taglineEn.toLowerCase().contains('demo'), false);
    }
  });
}
