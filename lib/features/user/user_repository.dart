import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class UserRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  User? getCurrentUser();
  bool isUserLoggedIn();
}

@LazySingleton(as: UserRepository)
class FirebaseUserRepository extends UserRepository {
  FirebaseUserRepository();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
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
