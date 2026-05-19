import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:unifye/main.dart' show baseUrl;

import '../../../pages/event_page.dart';
import '../../../pages/message_page.dart';
import '../../messages/models/chat_model.dart';
import '../models/event_detail.dart';
import '../models/event_summary_model.dart';
import '../providers/event_request.dart';

/// Wraps every API call result so providers never deal with raw exceptions.
class EventResult<T> {
  final T? data;
  final String? errorMessage;
  final int statusCode;

  const EventResult._({
    this.data,
    this.errorMessage,
    required this.statusCode,
  });

  factory EventResult.success(T data, [int statusCode = 200]) =>
      EventResult._(data: data, statusCode: statusCode);

  factory EventResult.failure(String message, [int statusCode = 400]) =>
      EventResult._(errorMessage: message, statusCode: statusCode);

  bool get isSuccess => errorMessage == null;
}

class EventRepository {
  EventRepository({required String token}) : _token = token;

  final String _token;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Events CRUD
  // ---------------------------------------------------------------------------

  /// GET /api/event — Paginated list of upcoming events.
  Future<EventResult<List<EventSummary>>> getEvents({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/event')
          .replace(queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      });

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        final events = json
            .map((e) => EventSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        return EventResult.success(events);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// GET /api/event/{id} — Full event detail with attendee list.
  Future<EventResult<EventDetail>> getEvent(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/event/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final detail = EventDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return EventResult.success(detail);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// POST /api/event — Create a new event.
  Future<EventResult<EventDetail>> createEvent(
      CreateEventRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/event'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final detail = EventDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return EventResult.success(detail, 201);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// PUT /api/event/{id} — Update event (organiser only).
  Future<EventResult<EventDetail>> updateEvent(
      String id,
      UpdateEventRequest request,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/event/$id'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final detail = EventDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return EventResult.success(detail);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// DELETE /api/event/{id} — Cancel event (organiser only).
  Future<EventResult<void>> deleteEvent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/event/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return EventResult.success(null, 204);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Attendee management
  // ---------------------------------------------------------------------------

  /// POST /api/event/{id}/join
  Future<EventResult<void>> joinEvent(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$id/join'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return EventResult.success(null);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// DELETE /api/event/{id}/leave
  Future<EventResult<void>> leaveEvent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/event/$id/leave'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return EventResult.success(null);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  /// GET /api/event/{id}/chat — Paginated chat history.
  Future<EventResult<List<ChatMessage>>> getChatMessages(
      String eventId, {
        int page = 1,
        int pageSize = 50,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/event/$eventId/chat')
          .replace(queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      });

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        final messages = json
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        return EventResult.success(messages);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  /// POST /api/event/{id}/chat — Send a chat message.
  Future<EventResult<ChatMessage>> sendChatMessage(
      String eventId,
      SendChatMessageRequest request,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$eventId/chat'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final message = ChatMessage.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return EventResult.success(message);
      }

      return EventResult.failure(_parseError(response), response.statusCode);
    } catch (e) {
      return EventResult.failure('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] as String? ?? 'Something went wrong.';
    } catch (_) {
      return 'Something went wrong (${response.statusCode}).';
    }
  }
}
