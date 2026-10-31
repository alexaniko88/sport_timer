import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es')];

  /// Tooltip of the account avatar button in the app bar, with the user name.
  ///
  /// In en, this message translates to:
  /// **'Account, {name}'**
  String accountAvatarTooltip(String name);

  /// Label of the sign out row in the account sheet and of the confirm button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Message of the dialog that asks to confirm the sign out.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out of your account?'**
  String get accountSignOutConfirmMessage;

  /// Title of the dialog that asks to confirm the sign out.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutConfirmTitle;

  /// Snackbar shown when the sign out fails.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Try again.'**
  String get accountSignOutError;

  /// App title shown by the system, for example in the app switcher.
  ///
  /// In en, this message translates to:
  /// **'Sport Timer'**
  String get appTitle;

  /// Login error when the account email is already linked to another sign-in method.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with a different sign-in method.'**
  String get authErrorAccountExists;

  /// Login error when the request fails because of the network.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get authErrorNetwork;

  /// Login error when the server blocks the user for too many requests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authErrorTooManyRequests;

  /// Login error shown when the cause is not known.
  ///
  /// In en, this message translates to:
  /// **'Login failed with an unknown error.'**
  String get authErrorUnknown;

  /// Login error when the account is disabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// Label of a button that dismisses a dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Accessibility hint for the option tiles that open a value selector.
  ///
  /// In en, this message translates to:
  /// **'Opens a selector'**
  String get commonOpensSelectorHint;

  /// Label of the preparation time option.
  ///
  /// In en, this message translates to:
  /// **'Preparation time'**
  String get commonPreparationTime;

  /// Label of the rest time option.
  ///
  /// In en, this message translates to:
  /// **'Rest time'**
  String get commonRestTime;

  /// Label of the round time option.
  ///
  /// In en, this message translates to:
  /// **'Round time'**
  String get commonRoundTime;

  /// Label of the number of rounds option.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get commonRounds;

  /// Total time with hours, minutes and seconds.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m {s}s'**
  String durationHoursMinutesSeconds(int h, int m, int s);

  /// Time with minutes and seconds.
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String durationMinutesSeconds(int m, int s);

  /// Time with seconds only.
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String durationSeconds(int s);

  /// Label of the side drawer item that opens the timer styles page.
  ///
  /// In en, this message translates to:
  /// **'Timer styles'**
  String get homeDrawerTimerStyles;

  /// Tooltip of the menu button in the app bars that opens the side drawer.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get homeMenuTooltip;

  /// Label of the button on the home page that starts the timer.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeStartButton;

  /// Label of the home tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabHome;

  /// Tooltip of the home tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabHomeTooltip;

  /// Label of the statistics tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get homeTabStatistics;

  /// Tooltip of the statistics tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get homeTabStatisticsTooltip;

  /// Label of the templates tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get homeTabTemplates;

  /// Tooltip of the templates tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Workout Templates'**
  String get homeTabTemplatesTooltip;

  /// Label of the Google sign in button on the login page.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogleButton;

  /// Title of the login page app bar.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Welcome headline on the login page.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sport Timer'**
  String get loginWelcome;

  /// Column title above the minutes wheel in the time picker.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get pickerMinutes;

  /// Column title above the seconds wheel in the time picker.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get pickerSeconds;

  /// Name used in the greeting when the user has no email.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get statisticsDefaultUserName;

  /// Greeting in the statistics app bar.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String statisticsGreeting(String name);

  /// Title of the statistics section.
  ///
  /// In en, this message translates to:
  /// **'Here are your training statistics'**
  String get statisticsSectionTitle;

  /// Title of the statistics page app bar.
  ///
  /// In en, this message translates to:
  /// **'Your statistics'**
  String get statisticsTitle;

  /// Name of the Full Abs workout template.
  ///
  /// In en, this message translates to:
  /// **'Full Abs'**
  String get templateAbsName;

  /// Name of the default workout template.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get templateDefaultName;

  /// Name of the Hyrox workout template.
  ///
  /// In en, this message translates to:
  /// **'Hyrox'**
  String get templateHyroxName;

  /// Name of the stretching workout template.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get templateStretchingName;

  /// Name of the strength workout template.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get templateStrengthName;

  /// Screen reader label of a template tile with its name and values.
  ///
  /// In en, this message translates to:
  /// **'{name}. Round time {round}, rest time {rest}, {rounds, plural, =1{1 round} other{{rounds} rounds}}, total time {total}'**
  String templateTileSemantics(String name, String round, String rest, int rounds, String total);

  /// Summary line of a template tile with the round time, rest time and number of rounds.
  ///
  /// In en, this message translates to:
  /// **'{work} work · {rest} rest · {rounds, plural, =1{1 round} other{{rounds} rounds}}'**
  String templateTileSummary(String work, String rest, int rounds);

  /// Title of the templates page app bar.
  ///
  /// In en, this message translates to:
  /// **'Choose your template'**
  String get templatesTitle;

  /// Tooltip of the button that pauses the timer.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPause;

  /// Title of the media notification shown while a workout runs in the background.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get timerNotificationTitle;

  /// Hint on the full color timer shown while the timer is paused.
  ///
  /// In en, this message translates to:
  /// **'Paused · tap to resume'**
  String get timerPausedHint;

  /// Label of the phase pill when the workout is finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get timerPhaseFinished;

  /// Label of the phase pill during the preparation time.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get timerPhasePreparation;

  /// Label of the phase pill during the rest time.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get timerPhaseRest;

  /// Label of the phase pill during a round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get timerPhaseRound;

  /// Tooltip of the button that resumes the paused timer.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get timerResume;

  /// Round number under the phase label on the timer page, with the current round and the number of rounds.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String timerRoundNumberOf(int current, int total);

  /// Line on the finished timer with the number of rounds done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round done} other{{count} rounds done}}'**
  String timerRoundsDone(int count);

  /// Title of the timer setup page app bar.
  ///
  /// In en, this message translates to:
  /// **'Are you prepared?'**
  String get timerSetupTitle;

  /// Name of the full color timer style.
  ///
  /// In en, this message translates to:
  /// **'Full color'**
  String get timerStyleFullColor;

  /// Name of the progress ring timer style.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get timerStyleRing;

  /// Name of the rounds strip timer style.
  ///
  /// In en, this message translates to:
  /// **'Rounds strip'**
  String get timerStyleRoundsStrip;

  /// Title of the timer styles page app bar.
  ///
  /// In en, this message translates to:
  /// **'Timer styles'**
  String get timerStylesTitle;

  /// Info line on the rounds strip timer with the total time left.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timerTimeLeft(String time);

  /// Info line on the timer page with the total time left.
  ///
  /// In en, this message translates to:
  /// **'Total {time}'**
  String timerTotal(String time);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
