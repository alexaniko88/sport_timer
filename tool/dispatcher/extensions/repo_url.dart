/// Reads a GitHub remote URL.
extension RepoUrl on String {
  /// `owner/name` for an `https://github.com/owner/name(.git)` or
  /// `git@github.com:owner/name(.git)` URL, or null for any other URL.
  String? get githubSlug {
    final match = RegExp(r'github\.com[:/]([^/\s]+/[^/\s]+?)(?:\.git)?/?$').firstMatch(trim());
    return match?.group(1);
  }
}
