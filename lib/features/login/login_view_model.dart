import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/user/user_repository.dart';

typedef AuthAction = Future<Result<void>> Function();
typedef AuthCall = Future<bool> Function({
  required String email,
  required String password,
});

class LoginViewModel {
  final UserRepository _userRepository;
  final ValueNotifier<LoginState> _state = ValueNotifier(const LoginState());
  bool _disposed = false;

  LoginViewModel(this._userRepository);

  ValueListenable<LoginState> get state => _state;

  bool isUserLoggedIn() => _userRepository.isUserLoggedIn();

  Future<bool> signIn({required String email, required String password}) => _authenticate(
        () => _userRepository.signIn(email: email, password: password),
      );

  Future<bool> signUp({required String email, required String password}) => _authenticate(
        () => _userRepository.signUp(email: email, password: password),
      );

  Future<bool> _authenticate(AuthAction action) async {
    _state.value = const LoginState(isLoading: true);
    final result = await action();
    // The page can be gone by the time the request finishes.
    if (_disposed) return false;
    return result.fold(
      onSuccess: (_) {
        _state.value = const LoginState();
        return true;
      },
      onFailure: (error) {
        _state.value = LoginState(
          error: error is AuthException ? error.error : AuthError.unknown,
        );
        return false;
      },
    );
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
