import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/user/user_repository.dart';

typedef AuthAction = Future<Result<void>> Function();

class LoginViewModel {
  final UserRepository _userRepository;
  final ValueNotifier<LoginState> _state = ValueNotifier(const LoginState());
  bool _disposed = false;

  LoginViewModel(this._userRepository);

  ValueListenable<LoginState> get state => _state;

  bool isUserLoggedIn() => _userRepository.isUserLoggedIn();

  Future<bool> signInWithGoogle() => _authenticate(_userRepository.signInWithGoogle);

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
        // A cancelled sign in is not an error, so the page shows nothing.
        _state.value = switch (error) {
          SignInCancelledException() => const LoginState(),
          AuthException(error: final authError) => LoginState(error: authError),
          _ => const LoginState(error: AuthError.unknown),
        };
        return false;
      },
    );
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
