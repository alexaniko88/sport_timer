import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/account/account_state.dart';
import 'package:sport_timer/features/user/user_repository.dart';

class AccountViewModel {
  final UserRepository _userRepository;
  final ValueNotifier<AccountState> _state;
  bool _disposed = false;

  AccountViewModel(this._userRepository) : _state = ValueNotifier(_buildState(_userRepository));

  ValueListenable<AccountState> get state => _state;

  static AccountState _buildState(UserRepository repository) {
    final user = repository.getCurrentUser();
    final email = user?.email;
    final displayName = user?.displayName;
    return AccountState(
      displayName: displayName != null && displayName.isNotEmpty ? displayName : email?.split('@').first ?? '',
      email: email,
      photoUrl: user?.photoURL,
    );
  }

  Future<bool> signOut() async {
    _state.value = _state.value.copyWith(isSigningOut: true);
    final result = await _userRepository.signOut();
    // The page can be gone by the time the request finishes.
    if (!_disposed) _state.value = _state.value.copyWith(isSigningOut: false);
    return result.fold(
      onSuccess: (_) => true,
      onFailure: (_) => false,
    );
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
