import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unifye/features/swipe/models/swipe_candidate.dart';
import 'package:unifye/main.dart';

class SwipeResponse {
  final bool isMatch;
  final String message;
  final String? matchedUserId;

  SwipeResponse({
    required this.isMatch,
    required this.message,
    this.matchedUserId,
  });
}

class SwipeService {
  Future<List<SwipeCandidate>> getCandidates({
    required String userId,
    int take = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/swipe/candidates')
        .replace(queryParameters: {'userId': userId, 'take': '$take'});

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to load candidates'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid candidates response.');
    }

    return decoded.whereType<Map<String, dynamic>>().map((item) {
      final normalized = Map<String, dynamic>.from(item);
      final imageUrl = normalized['imageUrl']?.toString();
      if (imageUrl != null && imageUrl.startsWith('/')) {
        normalized['imageUrl'] = '$baseUrl$imageUrl';
      }
      return SwipeCandidate.fromJson(normalized);
    }).toList();
  }

  Future<SwipeResponse> swipe({
    required String userId,
    required String targetUserId,
    required bool isLiked,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/swipe/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'targetUserId': targetUserId,
        'isLiked': isLiked,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final fallback = isLiked ? 'Failed to like user.' : 'Failed to pass user.';
      throw Exception(_extractError(response.body, fallback));
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid swipe response.');
    }

    return SwipeResponse(
      isMatch: decoded['isMatch'] == true,
      message: (decoded['message'] ?? '').toString(),
      matchedUserId: decoded['matchedUserId']?.toString(),
    );
  }

  String _extractError(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Keep fallback if response is not JSON.
    }
    return fallback;
  }
}

final swipeServiceProvider = Provider<SwipeService>((ref) => SwipeService());
