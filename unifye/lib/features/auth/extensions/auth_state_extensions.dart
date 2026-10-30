import 'package:unifye/features/auth/models/auth_state.dart';

extension AuthStateX on AuthState {
  String? get token => maybeWhen(
        authenticated: (_, token) => token,
        orElse: () => null,
      );
}
