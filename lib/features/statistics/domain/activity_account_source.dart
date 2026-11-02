abstract class ActivityAccountSource {
  String? get currentAccountId;

  // Emits changes after subscription, not the initial account snapshot.
  Stream<void> get changes;
}
