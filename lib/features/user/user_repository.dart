import 'package:firebase_auth/firebase_auth.dart';
import 'package:sport_timer/core/result.dart';

abstract class UserRepository {
  Future<Result<void>> signIn({required String email, required String password});
  Future<Result<void>> signUp({required String email, required String password});
  User? getCurrentUser();
  bool isUserLoggedIn();
}

class FirebaseUserRepository extends UserRepository {
  FirebaseUserRepository();

  @override
  Future<Result<void>> signIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(Exception(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> signUp({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(Exception(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
