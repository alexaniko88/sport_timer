enum AuthError {
  invalidEmail,
  invalidCredential,
  userDisabled,
  emailInUse,
  weakPassword,
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
