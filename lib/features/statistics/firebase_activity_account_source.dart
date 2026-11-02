import 'package:firebase_auth/firebase_auth.dart';
import 'package:sport_timer/features/statistics/activity_account_source.dart';

class FirebaseActivityAccountSource implements ActivityAccountSource {
  final FirebaseAuth _auth;

  FirebaseActivityAccountSource(this._auth);

  @override
  String? get currentAccountId => _auth.currentUser?.uid;

  @override
  Stream<void> get changes => _auth.authStateChanges().skip(1).map((_) {});
}
