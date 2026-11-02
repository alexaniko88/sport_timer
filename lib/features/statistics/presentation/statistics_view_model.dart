import 'package:sport_timer/features/user/domain/user_repository.dart';

class StatisticsViewModel {
  final UserRepository _userRepository;

  StatisticsViewModel(this._userRepository);

  String? get userName => _userRepository.getCurrentUser()?.email?.split('@').first;
}
