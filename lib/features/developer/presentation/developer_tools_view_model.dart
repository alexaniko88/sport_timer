import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_state.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';

class DeveloperToolsViewModel {
  final ActivityRepository _activityRepository;
  final ValueNotifier<DeveloperToolsState> _state = ValueNotifier(const DeveloperToolsState());
  bool _disposed = false;

  DeveloperToolsViewModel(this._activityRepository);

  ValueListenable<DeveloperToolsState> get state => _state;

  Future<bool> purge() async {
    if (_state.value.isPurging) return false;
    _state.value = const DeveloperToolsState(isPurging: true);
    final result = await _activityRepository.deleteAllActivity();
    // The page can be gone by the time the purge finishes.
    if (_disposed) return false;
    return result.fold(
      onSuccess: (_) {
        _state.value = const DeveloperToolsState();
        return true;
      },
      onFailure: (error) {
        _state.value = DeveloperToolsState(errorMessage: error.toString());
        return false;
      },
    );
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
