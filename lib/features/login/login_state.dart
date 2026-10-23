import 'package:sport_timer/features/user/auth_error.dart';

class LoginState {
  final bool isLoading;
  final AuthError? error;

  const LoginState({this.isLoading = false, this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LoginState && other.isLoading == isLoading && other.error == error;

  @override
  int get hashCode => Object.hash(isLoading, error);
}
