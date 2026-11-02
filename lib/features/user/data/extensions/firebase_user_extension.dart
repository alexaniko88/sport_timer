import 'package:firebase_auth/firebase_auth.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';

extension FirebaseUserMapper on User? {
  /// Maps the Firebase user to the app's own user, so Firebase types stay in the data layer.
  AppUser? toAppUser() {
    final user = this;
    if (user == null) return null;
    return AppUser(
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
