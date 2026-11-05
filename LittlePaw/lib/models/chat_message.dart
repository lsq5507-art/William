/// Local chat bubble (SCR-06-CHAT). Scripted; no cloud LLM required.
enum ChatSender { user, pet, system }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String textZh;
  final String textEn;
  final DateTime createdAt;
  final bool failed;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.textZh,
    required this.textEn,
    required this.createdAt,
    this.failed = false,
  });

  String text(bool zh) => zh ? textZh : textEn;

  ChatMessage copyWith({bool? failed, String? textZh, String? textEn}) =>
      ChatMessage(
        id: id,
        sender: sender,
        textZh: textZh ?? this.textZh,
        textEn: textEn ?? this.textEn,
        createdAt: createdAt,
        failed: failed ?? this.failed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'textZh': textZh,
        'textEn': textEn,
        'createdAt': createdAt.toIso8601String(),
        'failed': failed,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        sender: ChatSender.values.firstWhere(
          (e) => e.name == (j['sender'] as String? ?? 'pet'),
          orElse: () => ChatSender.pet,
        ),
        textZh: j['textZh'] as String? ?? '',
        textEn: j['textEn'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        failed: j['failed'] as bool? ?? false,
      );
}
