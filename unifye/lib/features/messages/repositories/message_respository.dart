import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_model.dart';
import 'i_message_repository.dart';

class MessageRepository implements IMessageRepository {
  final http.Client _client;
  final String baseUrl;

  MessageRepository({
    required http.Client client,
    required this.baseUrl,
  }) : _client = client;

  @override
  Future<List<ChatMessage>> getMessages({
    required String otherUserId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/messages/$otherUserId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages');
    }

    final List<dynamic> data =
    jsonDecode(response.body) as List<dynamic>;

    return data
        .map(
          (json) => ChatMessage.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'receiverId': receiverId,
        // Fix: was 'message' — backend SendMessageRequest expects 'content'
        'content': message,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message');
    }

    return ChatMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
