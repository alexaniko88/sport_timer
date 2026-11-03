// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get setupSessionLength => 'Session length';

  @override
  String get setupPreparation => 'Preparation';

  @override
  String get setupWork => 'Work';

  @override
  String get setupRest => 'Rest';

  @override
  String setupTemplateLabel(String name) {
    return 'Template: $name';
  }

  @override
  String accountAvatarTooltip(String name) {
    return 'Account, $name';
  }

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutConfirmMessage => 'Do you want to sign out of your account?';

  @override
  String get accountSignOutConfirmTitle => 'Sign out?';

  @override
  String get accountSignOutError => 'Could not sign out. Try again.';

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
  String get commonCancel => 'Cancel';

  @override
  String get commonOpensSelectorHint => 'Opens a selector';

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
  String get homeDrawerTemplates => 'Templates';

  @override
  String get homeDrawerTimerStyles => 'Timer styles';

  @override
  String get homeMenuTooltip => 'Open menu';

  @override
  String get homeStartButton => 'Start';

  @override
  String get homeTabTimer => 'Timer';

  @override
  String get homeTabTimerTooltip => 'Timer';

  @override
  String get homeTabStatistics => 'Statistics';

  @override
  String get homeTabStatisticsTooltip => 'Statistics';

  @override
  String get loginGoogleButton => 'Continue with Google';

  @override
  String get loginWelcome => 'Welcome to Sport Timer';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerSeconds => 'Seconds';

  @override
  String get statisticsRetryButton => 'Retry';

  @override
  String get statisticsSectionTitle => 'Here are your training statistics';

  @override
  String get statisticsTitle => 'Your statistics';

  @override
  String get templateAbsName => 'Full Abs';

  @override
  String get templateCustomName => 'Custom';

  @override
  String templateCustomTileSemantics(String preparation, String round, String rest, int rounds, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    return 'Custom settings. Preparation time $preparation, round time $round, rest time $rest, $_temp0, total time $total';
  }

  @override
  String templateCustomTileSummary(String preparation, String work, String rest, int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    return '$preparation prep · $work work · $rest rest · $_temp0';
  }

  @override
  String get templateDefaultName => 'Default';

  @override
  String get templateHyroxName => 'Hyrox';

  @override
  String get templateStretchingName => 'Stretching';

  @override
  String get templateStrengthName => 'Strength';

  @override
  String templateTileSemantics(String name, String round, String rest, int rounds, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    return '$name. Round time $round, rest time $rest, $_temp0, total time $total';
  }

  @override
  String templateTileSummary(String work, String rest, int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rounds',
      one: '1 round',
    );
    return '$work work · $rest rest · $_temp0';
  }

  @override
  String get templatesTitle => 'Choose your template';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerNotificationTitle => 'Workout in progress';

  @override
  String get timerPausedHint => 'Paused · tap to resume';

  @override
  String get timerPhaseFinished => 'Done';

  @override
  String get timerPhasePreparation => 'Prepare';

  @override
  String get timerPhaseRest => 'Rest';

  @override
  String get timerPhaseRound => 'Round';

  @override
  String get timerResume => 'Resume';

  @override
  String timerRoundNumberOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String timerRoundsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds done',
      one: '1 round done',
    );
    return '$_temp0';
  }

  @override
  String get timerSetupTitle => 'Are you prepared?';

  @override
  String get timerStyleFullColor => 'Full color';

  @override
  String get timerStyleRing => 'Ring';

  @override
  String get timerStyleRoundsStrip => 'Rounds strip';

  @override
  String get timerStylesTitle => 'Timer styles';

  @override
  String timerTimeLeft(String time) {
    return '$time left';
  }

  @override
  String timerTotal(String time) {
    return 'Total $time';
  }

  @override
  String get statisticsEmpty => 'No completed activity yet.';

  @override
  String get statisticsError => 'Could not load your statistics.';

  @override
  String get dayDetailsTitle => 'Day details';

  @override
  String get dayDetailsEmpty => 'No completed activity for this day.';

  @override
  String get dayDetailsError => 'Could not load this day.';

  @override
  String get dayDetailsSummary => 'Daily total';

  @override
  String get dayDetailsActivity => 'Activity on this day';

  @override
  String get dayDetailsConfiguration => 'Original configuration';

  @override
  String statisticsRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String statisticsHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String statisticsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String statisticsSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String statisticsWorkValue(String value) {
    return 'Work: $value';
  }

  @override
  String statisticsRestValue(String value) {
    return 'Rest: $value';
  }

  @override
  String statisticsTotalValue(String value) {
    return 'Total: $value';
  }

  @override
  String statisticsTileSemantics(String date, String rounds, String work, String rest, String total) {
    return '$date, $rounds, work $work, rest $rest, total $total';
  }
}
