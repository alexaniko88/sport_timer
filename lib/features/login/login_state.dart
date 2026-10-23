part of 'login.dart';

enum LoginStatus { initial, loading, success, failure }

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    required LoginStatus status,
    String? errorMessage,
  }) = _LoginState;
}
