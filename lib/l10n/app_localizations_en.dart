// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sport Timer';

  @override
  String get authErrorAccountExists => 'An account already exists with a different sign-in method.';

  @override
  String get authErrorNetwork => 'Network error. Check your connection and try again.';

  @override
  String get authErrorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authErrorUnknown => 'Login failed with an unknown error.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get commonOpensSelectorHint => 'Opens a selector';

  @override
  String get commonPreparationTime => 'Preparation time';

  @override
  String get commonRestTime => 'Rest time';

  @override
  String get commonRoundTime => 'Round time';

  @override
  String get commonRounds => 'Rounds';

  @override
  String durationHoursMinutesSeconds(int h, int m, int s) {
    return '${h}h ${m}m ${s}s';
  }

  @override
  String durationMinutesSeconds(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String durationSeconds(int s) {
    return '${s}s';
  }

  @override
  String get homeStartButton => 'Start';

  @override
  String get homeTabHome => 'Home';

  @override
  String get homeTabHomeTooltip => 'Home';

  @override
  String get homeTabStatistics => 'Statistics';

  @override
  String get homeTabStatisticsTooltip => 'Statistics';

  @override
  String get homeTabTemplates => 'Templates';

  @override
  String get homeTabTemplatesTooltip => 'Workout Templates';

  @override
  String get loginGoogleButton => 'Continue with Google';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginWelcome => 'Welcome to Sport Timer';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerSeconds => 'Seconds';

  @override
  String get statisticsDefaultUserName => 'User';

  @override
  String statisticsGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get statisticsSectionTitle => 'Here are your training statistics';

  @override
  String get statisticsTitle => 'Your statistics';

  @override
  String get templateAbsDescription => 'Intense abdominal workout with short rounds';

  @override
  String get templateAbsName => 'Full Abs';

  @override
  String get templateCrossFitDescription => 'High-intensity functional fitness training';

  @override
  String get templateCrossFitName => 'CrossFit';

  @override
  String get templateDefaultDescription => 'Default workout with standard settings';

  @override
  String get templateDefaultName => 'Default';

  @override
  String get templatesApplied => 'APPLIED';

  @override
  String get templatesPreparation => 'Preparation';

  @override
  String get templatesRestTime => 'Rest Time';

  @override
  String get templatesRoundTime => 'Round Time';

  @override
  String get templatesSubtitle => 'Select a pre-configured workout to get started quickly.';

  @override
  String get templatesTitle => 'Choose your template';

  @override
  String get templatesTotalWorkoutTime => 'Total Workout Time';

  @override
  String get templatesUseButton => 'Use Template';

  @override
  String get timerSetupTitle => 'Prepared for the new challenge?';
}
