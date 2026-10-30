import 'package:unifye/features/auth/models/auth_state.dart';

extension AuthStateX on AuthState {
  String? get token => maybeWhen(
        authenticated: (_, token) => token,
        orElse: () => null,
      );

  bool get hasValidSession {
    final t = token;
    return t != null && t.trim().isNotEmpty;
  }
}
