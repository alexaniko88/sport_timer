import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sport_timer/features/user/data/extensions/firebase_user_extension.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';

class MockUser extends Mock implements User {}

void main() {
  MockUser buildUser({String? displayName, String? email, String? photoUrl}) {
    final user = MockUser();
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.email).thenReturn(email);
    when(() => user.photoURL).thenReturn(photoUrl);
    return user;
  }

  group('FirebaseUserMapper.toAppUser', () {
    test('returns null when there is no Firebase user', () {
      expect(null.toAppUser(), isNull);
    });

    test('copies the email, display name and photo url', () {
      final user = buildUser(
        displayName: 'Ana Gomez',
        email: 'ana@mail.com',
        photoUrl: 'https://photo',
      );

      expect(
        user.toAppUser(),
        const AppUser(
          displayName: 'Ana Gomez',
          email: 'ana@mail.com',
          photoUrl: 'https://photo',
        ),
      );
    });

    test('keeps missing fields as null', () {
      final appUser = buildUser().toAppUser();

      expect(appUser, isNotNull);
      expect(appUser!.email, isNull);
      expect(appUser.displayName, isNull);
      expect(appUser.photoUrl, isNull);
    });
  });
}
