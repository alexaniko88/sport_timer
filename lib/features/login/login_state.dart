class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginState &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, errorMessage);
}
