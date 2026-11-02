import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';

abstract class UserRepository {
  Future<Result<void>> signInWithGoogle();
  Future<Result<void>> signOut();
  AppUser? getCurrentUser();
  bool isUserLoggedIn();
}
