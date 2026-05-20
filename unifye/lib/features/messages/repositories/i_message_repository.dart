import '../models/chat_model.dart';

abstract class IMessageRepository {
  Future<List<ChatMessage>> getMessages({
    required String otherUserId,
  });

  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
  });
}