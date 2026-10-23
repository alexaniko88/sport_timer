import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/user/auth_error.dart';

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
      debugPrint('signIn failed: ${e.code}');
      return Failure(AuthException(_mapAuthError(e.code)));
    } catch (e) {
      debugPrint('signIn failed: $e');
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
      debugPrint('signUp failed: ${e.code}');
      return Failure(AuthException(_mapAuthError(e.code)));
    } catch (e) {
      debugPrint('signUp failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  AuthError _mapAuthError(String code) {
    return switch (code) {
      'invalid-email' => AuthError.invalidEmail,
      'invalid-credential' || 'wrong-password' || 'user-not-found' => AuthError.invalidCredential,
      'user-disabled' => AuthError.userDisabled,
      'email-already-in-use' => AuthError.emailInUse,
      'weak-password' => AuthError.weakPassword,
      'network-request-failed' => AuthError.network,
      'too-many-requests' => AuthError.tooManyRequests,
      _ => AuthError.unknown,
    };
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
