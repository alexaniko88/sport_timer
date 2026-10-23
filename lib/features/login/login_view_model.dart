import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/user/user_repository.dart';

class LoginViewModel {
  LoginViewModel(this._userRepository);

  final UserRepository _userRepository;
  final ValueNotifier<LoginState> _state = ValueNotifier(const LoginState());
  bool _disposed = false;

  ValueListenable<LoginState> get state => _state;

  bool isUserLoggedIn() => _userRepository.isUserLoggedIn();

  Future<bool> signIn({required String email, required String password}) =>
      _authenticate(
          () => _userRepository.signIn(email: email, password: password));

  Future<bool> signUp({required String email, required String password}) =>
      _authenticate(
          () => _userRepository.signUp(email: email, password: password));

  Future<bool> _authenticate(Future<Result<void>> Function() action) async {
    _state.value = const LoginState(isLoading: true);
    final result = await action();
    // The page can be gone by the time the request finishes.
    if (_disposed) return false;
    switch (result) {
      case Success():
        _state.value = const LoginState();
        return true;
      case Failure(:final error):
        _state.value = LoginState(errorMessage: error.toString());
        return false;
    }
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
