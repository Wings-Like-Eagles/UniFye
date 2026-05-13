import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:unifye/main.dart' show baseUrl;           // ← correct import
import 'package:unifye/features/profile/models/user_response.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
      (ref) => ProfileRepository(),
);

class ProfileRepository {
  // ─── GET api/profile ────────────────────────────────────────────────────────

  Future<UserResponse> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/profile'),                  // ← no prefix
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) return _parseResponse(response.body);
    throw _parseError(response);
  }

  // ─── PUT api/profile ────────────────────────────────────────────────────────

  Future<UserResponse> updateProfile(
      String token, {
        String? firstName,
        String? lastName,
        String? gender,
        String? dateOfBirth,
        String? interests,
      }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/api/profile'),
    )..headers.addAll(_authHeaders(token));

    if (firstName != null) request.fields['firstName'] = firstName;
    if (lastName != null) request.fields['lastName'] = lastName;
    if (gender != null) request.fields['gender'] = gender;
    if (dateOfBirth != null) request.fields['dateOfBirth'] = dateOfBirth;
    if (interests != null) request.fields['interests'] = interests;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) return _parseResponse(response.body);
    throw _parseError(response);
  }

  // ─── PUT api/profile/image ──────────────────────────────────────────────────

  Future<UserResponse> updateProfileImage(String token, File image) async {
    final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/api/profile/image'),
    )
      ..headers.addAll(_authHeaders(token))
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) return _parseResponse(response.body);
    throw _parseError(response);
  }

  // ─── DELETE api/profile/image ───────────────────────────────────────────────

  Future<UserResponse> deleteProfileImage(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/profile/image'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) return _parseResponse(response.body);
    throw _parseError(response);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  UserResponse _parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    final rawImageUrl = json['imageUrl'] as String?;
    if (rawImageUrl != null && !rawImageUrl.startsWith('http')) {
      json['imageUrl'] = '$baseUrl$rawImageUrl';
    }

    return UserResponse.fromJson(json);
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Exception _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final message =
      body is String ? body : body['message'] ?? 'Unknown error';
      return Exception(message);
    } catch (_) {
      return Exception('Request failed (${response.statusCode})');
    }
  }
}
