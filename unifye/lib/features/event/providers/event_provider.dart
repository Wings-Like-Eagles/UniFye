import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image_picker/image_picker.dart';

import '../../../main.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../messages/models/chat_model.dart';
import '../models/event_summary_model.dart';

final eventsProvider =
StateNotifierProvider<EventsNotifier, AsyncValue<List<EventSummary>>>(
        (ref) => EventsNotifier(ref));

class EventsNotifier extends StateNotifier<AsyncValue<List<EventSummary>>> {
  EventsNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  String? get _token => _ref.read(authProvider).token;

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchEvents() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/event'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        state = AsyncValue.data(
            json.map((e) => EventSummary.fromJson(e)).toList());
      } else {
        state = AsyncValue.error(
            'Failed to load events', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Create (with optional poster) ─────────────────────────────────────────

  /// Step 1: POST JSON to create the event.
  /// Step 2: If [posterFile] is provided, multipart-upload it to
  ///         /api/event/{id}/poster.
  Future<bool> createEvent(
      Map<String, dynamic> payload) async {
    try {
      // ── 1. Create event ────────────────────────────────────────────────────
      debugPrint('Create Event is triggered');
      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/event'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (createResponse.statusCode != 201) return false;

      // ── 2. Upload poster if provided ───────────────────────────────────────
      // if (posterFile != null) {
      //   final body = jsonDecode(createResponse.body) as Map<String, dynamic>;
      //   // Your EventDetailResponse should contain an "id" field
      //   final eventId = body['id'] as String?;
      //
      //   if (eventId != null) {
      //     await _uploadPoster(eventId, posterFile);
      //   }
      // }

      await fetchEvents();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Multipart upload to POST /api/event/{id}/poster
  Future<void> _uploadPoster(String eventId, XFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/event/$eventId/poster'),
      )
        ..headers['Authorization'] = 'Bearer $_token'
        ..files.add(await http.MultipartFile.fromPath(
          'poster', // must match the IFormFile parameter name in the controller
          file.path,
          contentType: _mediaTypeFromPath(file.path),
        ));

      final streamed = await request.send();

      if (streamed.statusCode != 200) {
        // Poster upload failed — event was still created, just log it
        final body = await streamed.stream.bytesToString();
        print('Poster upload failed ${streamed.statusCode}: $body');
      }
    } catch (e) {
      print('Poster upload error: $e');
    }
  }

  /// Infers the MIME type from the file extension for the multipart upload.
  http_parser.MediaType _mediaTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png'  => http_parser.MediaType('image', 'png'),
      'webp' => http_parser.MediaType('image', 'webp'),
      _      => http_parser.MediaType('image', 'jpeg'),
    };
  }

  // ── Join / Leave ───────────────────────────────────────────────────────────

  Future<bool> joinEvent(String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$eventId/join'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await fetchEvents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leaveEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/event/$eventId/leave'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        await fetchEvents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

// =============================================================================
// Chat
// =============================================================================

final chatProvider = StateNotifierProvider.family<ChatNotifier,
    AsyncValue<List<ChatMessage>>, String>(
      (ref, eventId) => ChatNotifier(ref, eventId),
);

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier(this._ref, this._eventId) : super(const AsyncValue.loading());

  final Ref _ref;
  final String _eventId;

  String? get _token => _ref.read(authProvider).token;

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/event/$_eventId/chat'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        state = AsyncValue.data(
            json.map((e) => ChatMessage.fromJson(e)).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$_eventId/chat'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 200) await fetchMessages();
    } catch (_) {}
  }
}

// Extension to safely read token from auth state
extension AuthStateX on AuthState {
  String? get token =>
      maybeWhen(authenticated: (_, t) => t, orElse: () => null);
}
