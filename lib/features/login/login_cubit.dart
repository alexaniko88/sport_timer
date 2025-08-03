part of 'login.dart';

@injectable
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
    try {
      await _userRepository.signIn(email: email, password: password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _userRepository.signUp(email: email, password: password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
