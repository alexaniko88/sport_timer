import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/login/login_view_model.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/user/user_repository.dart';

class _FakeUserRepository extends UserRepository {
  Result<void> signInResult = const Success(null);
  Result<void> signUpResult = const Success(null);

  @override
  Future<Result<void>> signIn({required String email, required String password}) async => signInResult;

  @override
  Future<Result<void>> signUp({required String email, required String password}) async => signUpResult;

  @override
  User? getCurrentUser() => null;

  @override
  bool isUserLoggedIn() => false;
}

void main() {
  late _FakeUserRepository repository;
  late LoginViewModel viewModel;

  setUp(() {
    repository = _FakeUserRepository();
    viewModel = LoginViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  group('LoginViewModel.signIn', () {
    test('sets the AuthError of an AuthException', () async {
      repository.signInResult = const Failure(AuthException(AuthError.invalidCredential));

      final success = await viewModel.signIn(email: 'a@b.com', password: 'x');

      expect(success, isFalse);
      expect(viewModel.state.value, const LoginState(error: AuthError.invalidCredential));
    });

    test('falls back to unknown for a failure that is not an AuthException', () async {
      repository.signInResult = Failure(Exception('boom'));

      final success = await viewModel.signIn(email: 'a@b.com', password: 'x');

      expect(success, isFalse);
      expect(viewModel.state.value.error, AuthError.unknown);
      expect(viewModel.state.value.isLoading, isFalse);
    });

    test('clears a previous error on success', () async {
      repository.signInResult = const Failure(AuthException(AuthError.network));
      await viewModel.signIn(email: 'a@b.com', password: 'x');
      expect(viewModel.state.value.error, AuthError.network);

      repository.signInResult = const Success(null);
      final success = await viewModel.signIn(email: 'a@b.com', password: 'x');

      expect(success, isTrue);
      expect(viewModel.state.value, const LoginState());
    });
  });

  group('LoginViewModel.signUp', () {
    test('sets the AuthError of an AuthException', () async {
      repository.signUpResult = const Failure(AuthException(AuthError.emailInUse));

      final success = await viewModel.signUp(email: 'a@b.com', password: 'x');

      expect(success, isFalse);
      expect(viewModel.state.value.error, AuthError.emailInUse);
    });
  });
}
