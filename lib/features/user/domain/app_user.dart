class AppUser {
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    this.email,
    this.displayName,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && other.email == email && other.displayName == displayName && other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(email, displayName, photoUrl);
}
