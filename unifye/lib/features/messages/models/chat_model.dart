class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String content;
  final DateTime sentAtUtc;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.content,
    required this.sentAtUtc,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderImageUrl: json['senderImageUrl'] as String?,
      content: json['content'] as String,
      sentAtUtc: DateTime.parse(json['sentAtUtc'] as String),
    );
  }
}
