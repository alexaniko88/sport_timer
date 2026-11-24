class DeveloperToolsState {
  final bool isPurging;
  final String? errorMessage;

  const DeveloperToolsState({this.isPurging = false, this.errorMessage});

  DeveloperToolsState copyWith({bool? isPurging, String? errorMessage}) {
    return DeveloperToolsState(
      isPurging: isPurging ?? this.isPurging,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeveloperToolsState && other.isPurging == isPurging && other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isPurging, errorMessage);
}
