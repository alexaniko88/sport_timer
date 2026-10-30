import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/account/account_state.dart';
import 'package:sport_timer/features/account/account_view_model.dart';
import 'package:sport_timer/features/user/user_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockUserRepository repository;
  late AccountViewModel viewModel;

  User buildUser({String? displayName, String? email, String? photoUrl}) {
    final user = MockUser();
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.email).thenReturn(email);
    when(() => user.photoURL).thenReturn(photoUrl);
    return user;
  }

  void stubUser(User user) {
    when(() => repository.getCurrentUser()).thenReturn(user);
  }

  setUp(() {
    repository = MockUserRepository();
    stubUser(buildUser(displayName: 'Ana Gomez', email: 'ana@mail.com'));
    viewModel = AccountViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  void stubSignOut(Result<void> result) {
    when(() => repository.signOut()).thenAnswer((_) async => result);
  }

  group('AccountViewModel initial state', () {
    test('uses the display name, email and photo of the user', () {
      stubUser(buildUser(displayName: 'ana gomez', email: 'ana@mail.com', photoUrl: 'https://photo'));
      final model = AccountViewModel(repository);
      addTearDown(model.dispose);

      expect(
        model.state.value,
        const AccountState(displayName: 'ana gomez', email: 'ana@mail.com', photoUrl: 'https://photo'),
      );
      expect(model.state.value.initial, 'A');
    });

    test('falls back to the email prefix when there is no display name', () {
      stubUser(buildUser(email: 'bob@mail.com'));
      final model = AccountViewModel(repository);
      addTearDown(model.dispose);

      expect(model.state.value.displayName, 'bob');
      expect(model.state.value.initial, 'B');
    });
  });

  group('AccountViewModel.signOut', () {
    test('returns true on success', () async {
      stubSignOut(const Success(null));

      final success = await viewModel.signOut();

      expect(success, isTrue);
      expect(viewModel.state.value.isSigningOut, isFalse);
    });

    test('returns false and stops signing out on failure', () async {
      stubSignOut(Failure(Exception('boom')));

      final success = await viewModel.signOut();

      expect(success, isFalse);
      expect(viewModel.state.value.isSigningOut, isFalse);
    });

    test('sets isSigningOut while the request runs', () async {
      stubSignOut(const Success(null));

      final future = viewModel.signOut();
      expect(viewModel.state.value.isSigningOut, isTrue);
      await future;
    });

    test('returns true when the sign out succeeds after dispose', () async {
      stubSignOut(const Success(null));

      final model = AccountViewModel(repository);
      final future = model.signOut();
      model.dispose();

      expect(await future, isTrue);
    });

    test('changes no state after dispose', () async {
      stubSignOut(const Success(null));

      // A separate model, because tearDown disposes the shared one.
      final model = AccountViewModel(repository);
      final future = model.signOut();
      model.dispose();

      expect(await future, isTrue);
    });
  });
}
