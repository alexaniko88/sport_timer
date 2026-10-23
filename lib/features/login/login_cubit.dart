part of 'login.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._userRepository) : super(const LoginState(status: LoginStatus.initial));

  final UserRepository _userRepository;

  Future<void> checkAuthenticationStatus() async {
    if (_userRepository.isUserLoggedIn()) {
      emit(state.copyWith(status: LoginStatus.success));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _userRepository.signIn(email: email, password: password);
    switch (result) {
      case Success():
        emit(state.copyWith(status: LoginStatus.success));
      case Failure(:final error):
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.toString(),
        ));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _userRepository.signUp(email: email, password: password);
    switch (result) {
      case Success():
        emit(state.copyWith(status: LoginStatus.success));
      case Failure(:final error):
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: error.toString(),
        ));
    }
  }
}
