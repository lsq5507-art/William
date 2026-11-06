/// Feed / onboarding story. Media fields for PostCard (D-03/D-04).
enum StoryAspect { square, portrait45, ratio43, landscape1610 }

class Story {
  final String id;
  final String bodyZh;
  final String bodyEn;
  final DateTime createdAt;
  final bool isOnboarding;
  final bool isUnread;
  final String? imageUrl;
  final StoryAspect aspect;
  final bool isDemoFill;
  final String? locationLabel;

  const Story({
    required this.id,
    required this.bodyZh,
    required this.bodyEn,
    required this.createdAt,
    this.isOnboarding = false,
    this.isUnread = true,
    this.imageUrl,
    this.aspect = StoryAspect.ratio43,
    this.isDemoFill = false,
    this.locationLabel,
  });

  Story copyWith({
    bool? isUnread,
    String? imageUrl,
    StoryAspect? aspect,
    bool? isDemoFill,
    String? locationLabel,
  }) =>
      Story(
        id: id,
        bodyZh: bodyZh,
        bodyEn: bodyEn,
        createdAt: createdAt,
        isOnboarding: isOnboarding,
        isUnread: isUnread ?? this.isUnread,
        imageUrl: imageUrl ?? this.imageUrl,
        aspect: aspect ?? this.aspect,
        isDemoFill: isDemoFill ?? this.isDemoFill,
        locationLabel: locationLabel ?? this.locationLabel,
      );

  /// Default post media is 4:3 (D-04); portrait45 keeps 4:5; square kept for legacy.
  double get aspectRatio {
    switch (aspect) {
      case StoryAspect.portrait45:
        return 4 / 5;
      case StoryAspect.landscape1610:
        return 16 / 10;
      case StoryAspect.ratio43:
        return 4 / 3;
      case StoryAspect.square:
        return 1.0;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bodyZh': bodyZh,
        'bodyEn': bodyEn,
        'createdAt': createdAt.toIso8601String(),
        'isOnboarding': isOnboarding,
        'isUnread': isUnread,
        'imageUrl': imageUrl,
        'aspect': aspect.name,
        'isDemoFill': isDemoFill,
        'locationLabel': locationLabel,
      };

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        bodyZh: j['bodyZh'] as String,
        bodyEn: j['bodyEn'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isOnboarding: j['isOnboarding'] as bool? ?? false,
        isUnread: j['isUnread'] as bool? ?? true,
        imageUrl: j['imageUrl'] as String?,
        aspect: StoryAspect.values.firstWhere(
          (e) => e.name == (j['aspect'] as String? ?? 'ratio43'),
          orElse: () => StoryAspect.ratio43,
        ),
        isDemoFill: j['isDemoFill'] as bool? ?? false,
        locationLabel: j['locationLabel'] as String?,
      );

  String body(bool zh) => zh ? bodyZh : bodyEn;
}
