import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/profile/models/profile_state.dart';
import 'package:unifye/features/profile/models/user_response.dart';

import '../respositories/profile_respository.dart';

final profileProvider =
AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async => ProfileState.initial();

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    final token = _token;
    if (token == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref
          .read(profileRepositoryProvider)
          .getProfile(token);
      return ProfileState.fromResponse(response);
    });
  }

  // ─── Update fields ─────────────────────────────────────────────────────────

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    List<String>? interests,
  }) async {
    final token = _token;
    if (token == null) return;

    final previous = state;

    // Optimistic update
    state = AsyncData(
      state.value!.copyWith(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        interests: interests,
      ),
    );

    try {
      final response = await ref.read(profileRepositoryProvider).updateProfile(
        token,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth != null
            ? '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}'
            : null,
        interests: interests?.join(','),
      );
      state = AsyncData(ProfileState.fromResponse(response));
    } catch (e, st) {
      // Roll back on failure
      state = previous;
      state = AsyncError(e, st);
    }
  }

  // ─── Update image ──────────────────────────────────────────────────────────

  Future<void> updateProfileImage(File image) async {
    final token = _token;
    if (token == null) return;

    final previous = state;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await ref
          .read(profileRepositoryProvider)
          .updateProfileImage(token, image);
      return ProfileState.fromResponse(response);
    });

    if (state.hasError) state = previous;
  }

  // ─── Delete image ──────────────────────────────────────────────────────────

  Future<void> deleteProfileImage() async {
    final token = _token;
    if (token == null) return;

    final previous = state;

    // Optimistic update
    state = AsyncData(state.value!.copyWith(clearImage: true));

    try {
      final response = await ref
          .read(profileRepositoryProvider)
          .deleteProfileImage(token);
      state = AsyncData(ProfileState.fromResponse(response));
    } catch (e, st) {
      state = previous;
      state = AsyncError(e, st);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String? get _token => ref.read(authProvider).whenOrNull(
    authenticated: (_, token) => token,
  );
}