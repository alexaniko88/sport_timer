import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/login/login_state.dart';
import 'package:sport_timer/features/login/login_view_model.dart';
import 'package:sport_timer/features/user/auth_error.dart';
import 'package:sport_timer/features/user/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late LoginViewModel viewModel;

  setUp(() {
    repository = MockUserRepository();
    viewModel = LoginViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  void stubSignInWithGoogle(Result<void> result) {
    when(() => repository.signInWithGoogle()).thenAnswer((_) async => result);
  }

  group('LoginViewModel.signInWithGoogle', () {
    test('returns true and keeps a clean state on success', () async {
      stubSignInWithGoogle(const Success(null));

      final success = await viewModel.signInWithGoogle();

      expect(success, isTrue);
      expect(viewModel.state.value, const LoginState());
    });

    test('sets the AuthError of an AuthException', () async {
      stubSignInWithGoogle(const Failure(AuthException(AuthError.accountExistsWithDifferentCredential)));

      final success = await viewModel.signInWithGoogle();

      expect(success, isFalse);
      expect(viewModel.state.value, const LoginState(error: AuthError.accountExistsWithDifferentCredential));
    });

    test('falls back to unknown for a failure that is not an AuthException', () async {
      stubSignInWithGoogle(Failure(Exception('boom')));

      final success = await viewModel.signInWithGoogle();

      expect(success, isFalse);
      expect(viewModel.state.value.error, AuthError.unknown);
      expect(viewModel.state.value.isLoading, isFalse);
    });

    test('sets no error and stops loading when the user cancels', () async {
      stubSignInWithGoogle(const Failure(SignInCancelledException()));

      final success = await viewModel.signInWithGoogle();

      expect(success, isFalse);
      expect(viewModel.state.value, const LoginState());
    });

    test('clears a previous error on retry', () async {
      stubSignInWithGoogle(const Failure(AuthException(AuthError.network)));
      await viewModel.signInWithGoogle();
      expect(viewModel.state.value.error, AuthError.network);

      stubSignInWithGoogle(const Success(null));
      final success = await viewModel.signInWithGoogle();

      expect(success, isTrue);
      expect(viewModel.state.value, const LoginState());
    });
  });
}
