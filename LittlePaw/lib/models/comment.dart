class CommentThread {
  final String id;
  final String storyId;
  final String userText;
  final String replyZh;
  final String replyEn;
  final DateTime createdAt;
  final bool replyUnread;

  const CommentThread({
    required this.id,
    required this.storyId,
    required this.userText,
    required this.replyZh,
    required this.replyEn,
    required this.createdAt,
    this.replyUnread = true,
  });

  CommentThread copyWith({bool? replyUnread}) => CommentThread(
        id: id,
        storyId: storyId,
        userText: userText,
        replyZh: replyZh,
        replyEn: replyEn,
        createdAt: createdAt,
        replyUnread: replyUnread ?? this.replyUnread,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'storyId': storyId,
        'userText': userText,
        'replyZh': replyZh,
        'replyEn': replyEn,
        'createdAt': createdAt.toIso8601String(),
        'replyUnread': replyUnread,
      };

  factory CommentThread.fromJson(Map<String, dynamic> j) => CommentThread(
        id: j['id'] as String,
        storyId: j['storyId'] as String,
        userText: j['userText'] as String,
        replyZh: j['replyZh'] as String,
        replyEn: j['replyEn'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        replyUnread: j['replyUnread'] as bool? ?? true,
      );

  String reply(bool zh) => zh ? replyZh : replyEn;
}
