part of 'login.dart';

enum LoginStatus { initial, loading, success, failure }

@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    required LoginStatus status,
    String? errorMessage,
  }) = _LoginState;
}
