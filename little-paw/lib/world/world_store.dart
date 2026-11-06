// World Tab · local store (likes/comments/market) · v0.5
import 'package:flutter/foundation.dart';

import 'mock/world_mock_data.dart';
import 'models/world_models.dart';

/// In-memory World repository. Swap for API later; UI reads only this store.
class WorldStore extends ChangeNotifier {
  WorldStore() {
    _pets = List<WorldPet>.from(WorldMockData.pets());
    _posts = List<WorldPost>.from(WorldMockData.posts());
    _market = List<WorldMarketItem>.from(WorldMockData.market());
  }

  late List<WorldPet> _pets;
  late List<WorldPost> _posts;
  late List<WorldMarketItem> _market;
  final Set<String> _following = {};

  List<WorldPet> get pets => List.unmodifiable(_pets);
  List<WorldPost> get posts => List.unmodifiable(_posts);
  List<WorldMarketItem> get market => List.unmodifiable(_market);
  Set<String> get following => Set.unmodifiable(_following);

  WorldPet? petById(String id) {
    for (final p in _pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  WorldPost? postById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  void toggleLike(String postId) {
    final i = _posts.indexWhere((e) => e.id == postId);
    if (i < 0) return;
    final p = _posts[i];
    final liked = !p.liked;
    _posts[i] = p.copyWith(
      liked: liked,
      likeCount: liked ? p.likeCount + 1 : (p.likeCount > 0 ? p.likeCount - 1 : 0),
    );
    notifyListeners();
  }

  void addComment(String postId, {required bool zh, required String text}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final i = _posts.indexWhere((e) => e.id == postId);
    if (i < 0) return;
    final p = _posts[i];
    final c = WorldComment(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      authorZh: '我',
      authorEn: 'Me',
      textZh: trimmed,
      textEn: trimmed,
      at: DateTime.now(),
    );
    _posts[i] = p.copyWith(comments: [...p.comments, c]);
    notifyListeners();
  }

  void startTrial(String marketId) {
    _setMarketStatus(marketId, MarketAcquireStatus.trial);
  }

  void demoAcquire(String marketId) {
    _setMarketStatus(marketId, MarketAcquireStatus.owned);
  }

  void _setMarketStatus(String marketId, MarketAcquireStatus status) {
    final i = _market.indexWhere((e) => e.id == marketId);
    if (i < 0) return;
    _market[i] = _market[i].copyWith(status: status);
    final petId = _market[i].petId;
    if (status == MarketAcquireStatus.owned ||
        status == MarketAcquireStatus.trial) {
      _following.add(petId);
    }
    notifyListeners();
  }

  void toggleFollow(String petId) {
    if (_following.contains(petId)) {
      _following.remove(petId);
    } else {
      _following.add(petId);
    }
    notifyListeners();
  }

  bool isFollowing(String petId) => _following.contains(petId);
}
