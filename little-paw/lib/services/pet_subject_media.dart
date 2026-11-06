/// Pet-subject media rules for Feed (LP-P-07 / LP-D-07).
/// Whitelist local pet assets; reject picsum / landscape fillers.
class PetSubjectMedia {
  static const whitelistAssets = <String>[
    'assets/world_feed/post_01.jpg',
    'assets/world_feed/post_02.jpg',
    'assets/world_feed/post_03.jpg',
    'assets/world_feed/post_04.jpg',
    'assets/world_feed/post_05.jpg',
    'assets/world_feed/post_06.jpg',
    'assets/world_feed/post_07.jpg',
    'assets/world_feed/post_08.jpg',
    'assets/world_feed/av_01.jpg',
    'assets/world_feed/av_02.jpg',
    'assets/world_feed/av_03.jpg',
    'assets/world_feed/av_04.jpg',
  ];

  /// Asset path for seed index (stable, pet-first).
  static String assetForSeed(String seed) {
    final h = seed.hashCode.abs();
    return whitelistAssets[h % whitelistAssets.length];
  }

  static bool isAssetPath(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('assets/');
  }

  static bool isForbiddenLandscape(String? url) {
    if (url == null || url.isEmpty) return false;
    final u = url.toLowerCase();
    return u.contains('picsum.photos') ||
        u.contains('unsplash.com') ||
        u.contains('lorempixel') ||
        u.contains('placeholder.com');
  }

  /// Qualified pet-subject media for Feed main post.
  static bool isPetSubject(String? url) {
    if (url == null || url.isEmpty) return false;
    if (isForbiddenLandscape(url)) return false;
    // User-confirmed local media (weak confirm path, LP-P-08).
    if (url.startsWith('localmedia://')) return true;
    if (isAssetPath(url)) {
      return whitelistAssets.contains(url) ||
          url.startsWith('assets/world_feed/');
    }
    // Non-asset remote URLs are not trusted as pet-subject in this build.
    return false;
  }

  /// Resolve display URL under [feedPetSubjectMediaOnly].
  /// Returns null → UI must show missing state (never landscape filler).
  static String? resolveForFeed(String? url, {required bool petOnly}) {
    if (!petOnly) {
      // Even with flag off, known landscape fillers stay disqualified for acceptance.
      if (isForbiddenLandscape(url)) return null;
      return url;
    }
    return isPetSubject(url) ? url : null;
  }
}
