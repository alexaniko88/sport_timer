class AccountState {
  final String displayName;
  final String? email;
  final String? photoUrl;
  final bool isSigningOut;

  const AccountState({
    required this.displayName,
    this.email,
    this.photoUrl,
    this.isSigningOut = false,
  });

  String get initial => displayName.isEmpty ? '?' : String.fromCharCode(displayName.runes.first).toUpperCase();

  AccountState copyWith({bool? isSigningOut}) {
    return AccountState(
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      isSigningOut: isSigningOut ?? this.isSigningOut,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountState &&
          other.displayName == displayName &&
          other.email == email &&
          other.photoUrl == photoUrl &&
          other.isSigningOut == isSigningOut;

  @override
  int get hashCode => Object.hash(displayName, email, photoUrl, isSigningOut);
}
