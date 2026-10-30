enum AuthError {
  userDisabled,
  accountExistsWithDifferentCredential,
  network,
  tooManyRequests,
  unknown,
}

class AuthException implements Exception {
  final AuthError error;

  const AuthException(this.error);

  @override
  String toString() => 'AuthException($error)';
}

class SignInCancelledException implements Exception {
  const SignInCancelledException();

  @override
  String toString() => 'SignInCancelledException()';
}
