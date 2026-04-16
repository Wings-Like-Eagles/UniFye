import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unifye/features/auth/models/user.dart';
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

        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
          userData = data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
          token = (data['token'] ?? '').toString();
        } else if (responseData is Map<String, dynamic>) {
          // Support plain user response shape from backend.
          userData = responseData;
        } else {
          throw Exception('Invalid login response');
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

        // Store token (you can use shared_preferences or secure_storage)
        await _storeToken(token);

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

        if (token.isNotEmpty) {
          await _storeToken(token);
        }

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
  Future<String?> getStoredToken() async {
    // TODO: Implement token storage using shared_preferences or secure_storage
    // For now, return null
    return null;
  }

  /// Get current user with token
  Future<User> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = _tryDecodeJson(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        final userData = data['user'];
        return User(
          id: userData['id'] ?? userData['_id']?.toString() ?? '',
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          photoUrl: userData['photoUrl'] ?? userData['avatar'],
        );
      } else {
        throw Exception(_extractErrorMessage(responseData, 'Failed to get user'));
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Logout - clear stored token
  Future<void> logout() async {
    // TODO: Implement token removal
    // Also call logout endpoint if needed
    try {
      final token = await getStoredToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // Ignore logout errors
    }
    // Clear token storage
  }

  /// Store authentication token
  Future<void> _storeToken(String token) async {
    // TODO: Implement token storage using shared_preferences or secure_storage
    // Example with shared_preferences:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('auth_token', token);
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
