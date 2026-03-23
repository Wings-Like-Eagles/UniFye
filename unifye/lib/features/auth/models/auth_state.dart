// lib/features/auth/models/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:unifye/features/auth/models/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.authenticated({
    required User user,
    required String token,
  }) = Authenticated;
  const factory AuthState.loading() = Loading;
}