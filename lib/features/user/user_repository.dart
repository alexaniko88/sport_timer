import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/user/auth_error.dart';

abstract class UserRepository {
  Future<Result<void>> signInWithGoogle();
  Future<Result<void>> signOut();
  User? getCurrentUser();
  bool isUserLoggedIn();
}

class FirebaseUserRepository extends UserRepository {
  Future<void>? _googleInitialization;

  FirebaseUserRepository();

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      if (account.authentication.idToken case final idToken?) {
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
        return const Success(null);
      }
      debugPrint('signInWithGoogle failed: missing id token');
      return const Failure(AuthException(AuthError.unknown));
    } on GoogleSignInException catch (e) {
      debugPrint('signInWithGoogle failed: ${e.code}');
      if (e.code case GoogleSignInExceptionCode.canceled || GoogleSignInExceptionCode.interrupted) {
        return const Failure(SignInCancelledException());
      }
      return Failure(e);
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle failed: ${e.code}');
      return Failure(AuthException(_mapAuthError(e.code)));
    } catch (e) {
      debugPrint('signInWithGoogle failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('signOut failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
    // App auth state is Firebase, so a Google sign out failure is not fatal.
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('signOut google failed: $e');
    }
    return const Success(null);
  }

  // google_sign_in 7 requires initialize() once before authenticate(). A failed
  // attempt is not cached, so the next sign in can try again.
  Future<void> _ensureInitialized() async {
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize());
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  AuthError _mapAuthError(String code) {
    return switch (code) {
      'user-disabled' => AuthError.userDisabled,
      'account-exists-with-different-credential' => AuthError.accountExistsWithDifferentCredential,
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
