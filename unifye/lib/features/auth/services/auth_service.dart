import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unifye/features/auth/models/user.dart';
import 'package:unifye/features/auth/services/auth_token_storage.dart';
import 'package:unifye/main.dart';
import 'package:http_parser/http_parser.dart'; // Add this import

/// Authentication result model
class AuthResult {
  final User user;
  final String token;

  AuthResult({required this.user, required this.token});
}

/// Auth Service - handles authentication API calls
class AuthService {
  AuthService({AuthTokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? AuthTokenStorage();

  final AuthTokenStorage _tokenStorage;
  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = _tryDecodeJson(response.body);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData;
        String token = '';

        if (responseData is! Map<String, dynamic> ||
            responseData['success'] != true) {
          throw Exception(
            _extractErrorMessage(responseData, 'Invalid login response'),
          );
        }

        final data = responseData['data'] as Map<String, dynamic>? ?? {};
        userData = data['user'] as Map<String, dynamic>? ?? {};
        token = (data['token'] ?? data['Token'] ?? '').toString().trim();

        if (token.isEmpty) {
          throw Exception('Login succeeded but the server did not return a token.');
        }

        final fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        final user = User(
          id: (userData['id'] ?? userData['_id'] ?? '').toString(),
          email: (userData['email'] ?? email).toString(),
          name: (userData['name'] ?? fullName).toString().trim().isEmpty
              ? 'User'
              : (userData['name'] ?? fullName).toString().trim(),
          photoUrl: userData['photoUrl']?.toString() ??
              userData['imageUrl']?.toString() ??
              userData['avatar']?.toString(),
        );

        if (user.id.isEmpty) {
          throw Exception('Login response did not include a user id.');
        }

        await _tokenStorage.saveSession(token: token, userId: user.id);

        return AuthResult(user: user, token: token);
      } else {
        throw Exception(
          _extractErrorMessage(
            responseData,
            'Login failed (HTTP ${response.statusCode})',
          ),
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? university,
    DateTime? dateOfBirth,
    String? gender,
    String? bio,
    List<String>? interests,
    String? profileImagePath,
  }) async {
    try {
      // Backend expects firstName/lastName and multipart form-data.
      final splitName = name.trim().split(RegExp(r'\s+'));
      final firstName = splitName.isNotEmpty ? splitName.first : '';
      final lastName = splitName.length > 1 ? splitName.sublist(1).join(' ') : firstName;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/auth/register'),
      );

      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['email'] = email;
      request.fields['password'] = password;

      if (dateOfBirth != null) {
        final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
        request.fields['dateOfBirth'] = dob.toIso8601String().split('T').first;
      }

      if (gender != null && gender.trim().isNotEmpty) {
        request.fields['gender'] = gender.trim();
      }

      if (interests != null && interests.isNotEmpty) {
        request.fields['interests'] = interests.join(',');
      }

      if (profileImagePath != null && profileImagePath.trim().isNotEmpty) {
        final file = File(profileImagePath);
        if (await file.exists()) {
          // Get extension (e.g., .jpg, .png)
          final extension = path.extension(profileImagePath).toLowerCase();

          // Map extension to correct subtype
          String subType = 'jpeg'; // default
          if (extension == '.png') subType = 'png';
          if (extension == '.webp') subType = 'webp';
          if (extension == '.jpg' || extension == '.jpeg') subType = 'jpeg';

          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              profileImagePath,
              // Manually set the MediaType here
              contentType: MediaType('image', subType),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = _tryDecodeJson(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData is! Map<String, dynamic>) {
          throw Exception('Invalid registration response');
        }
        final userData = responseData;
        final fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        final user = User(
          id: userData['id'] ?? userData['_id'] ?? '',
          email: userData['email'] ?? email,
          name: fullName.isNotEmpty ? fullName : name,
          photoUrl: userData['imageUrl'] ?? userData['photoUrl'] ?? userData['avatar'],
        );
        // Registration endpoint currently returns user profile, not JWT.
        const token = '';

        return AuthResult(user: user, token: token);
      } else {
        throw Exception(
          _extractErrorMessage(
            responseData,
            'Registration failed (HTTP ${response.statusCode})',
          ),
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get stored authentication token
  Future<String?> getStoredToken() => _tokenStorage.getToken();

  /// Validates token by loading the current user's profile (requires auth).
  Future<User> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = _tryDecodeJson(response.body);

      if (response.statusCode == 200 && responseData is Map<String, dynamic>) {
        final userData = responseData;
        final fullName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        return User(
          id: userData['id'].toString(),
          email: (userData['email'] ?? '').toString(),
          name: fullName.isEmpty ? 'User' : fullName,
          photoUrl: userData['imageUrl']?.toString(),
        );
      } else {
        throw Exception(
          _extractErrorMessage(responseData, 'Failed to restore session'),
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Logout - clear stored token
  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  dynamic _tryDecodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(dynamic responseData, String fallback) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
