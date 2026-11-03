class Story {
  final String id;
  final String bodyZh;
  final String bodyEn;
  final DateTime createdAt;
  final bool isOnboarding;
  final bool isUnread;

  const Story({
    required this.id,
    required this.bodyZh,
    required this.bodyEn,
    required this.createdAt,
    this.isOnboarding = false,
    this.isUnread = true,
  });

  Story copyWith({bool? isUnread}) => Story(
        id: id,
        bodyZh: bodyZh,
        bodyEn: bodyEn,
        createdAt: createdAt,
        isOnboarding: isOnboarding,
        isUnread: isUnread ?? this.isUnread,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bodyZh': bodyZh,
        'bodyEn': bodyEn,
        'createdAt': createdAt.toIso8601String(),
        'isOnboarding': isOnboarding,
        'isUnread': isUnread,
      };

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        bodyZh: j['bodyZh'] as String,
        bodyEn: j['bodyEn'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isOnboarding: j['isOnboarding'] as bool? ?? false,
        isUnread: j['isUnread'] as bool? ?? true,
      );

  String body(bool zh) => zh ? bodyZh : bodyEn;
}
