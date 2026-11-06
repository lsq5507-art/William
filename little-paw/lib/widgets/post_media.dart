import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/story.dart';
import '../services/local_media_store.dart';
import '../services/pet_subject_media.dart';
import '../services/space_store.dart';

/// Card-inset media — default 4:3 with radius 12 (LP-D-04).
/// Pet-subject rule: no picsum landscape fillers (LP-P-07).
class PostMedia extends StatelessWidget {
  final Story story;
  final VoidCallback? onDoubleTap;
  final Widget? overlay;
  final BorderRadius borderRadius;
  final String? petName;

  const PostMedia({
    super.key,
    required this.story,
    this.onDoubleTap,
    this.overlay,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.petName,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SpaceStore>();
    final s = S(store.localeZh);
    final resolved = PetSubjectMedia.resolveForFeed(
      story.imageUrl,
      petOnly: store.feedPetSubjectMediaOnly,
    );
    final name = petName ?? store.pet?.name ?? 'Little Paw';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: story.aspectRatio,
          child: GestureDetector(
            onDoubleTap: onDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _imageOrMissing(s, name, resolved),
                ?overlay,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageOrMissing(S s, String name, String? url) {
    if (url == null || url.isEmpty) {
      return _MissingPetPhoto(s: s, name: name);
    }
    if (LocalMediaStore.isLocalMediaUrl(url)) {
      final bytes = LocalMediaStore.instance.bytesFor(url);
      if (bytes == null || bytes.isEmpty) {
        return _MissingPetPhoto(s: s, name: name);
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _MissingPetPhoto(s: s, name: name),
        semanticLabel: s.fmt('feed.media.a11y_pet', {'name': name}),
      );
    }
    if (PetSubjectMedia.isAssetPath(url)) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _MissingPetPhoto(s: s, name: name),
        semanticLabel: s.fmt('feed.media.a11y_pet', {'name': name}),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _MissingPetPhoto(s: s, name: name),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _Placeholder(showProgress: true);
      },
      semanticLabel: s.fmt('feed.media.a11y_pet', {'name': name}),
    );
  }
}

class _MissingPetPhoto extends StatelessWidget {
  final S s;
  final String name;
  const _MissingPetPhoto({required this.s, required this.name});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: s.get('feed.media.a11y_missing'),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 48, color: Colors.brown.withValues(alpha: 0.35)),
                const SizedBox(height: 8),
                Text(
                  s.get('feed.media.missing_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.get('feed.media.missing_body'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool showProgress;
  const _Placeholder({this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5E6D8), Color(0xFFE8D5C4)],
        ),
      ),
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.pets, size: 48, color: Color(0xFFC45C26)),
      ),
    );
  }
}
