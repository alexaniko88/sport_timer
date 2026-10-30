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

  /// Tooltip of the button on the home page that starts the timer.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get homeStartTimerTooltip;

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

  /// Description of the Full Abs workout template.
  ///
  /// In en, this message translates to:
  /// **'Intense abdominal workout with short rounds'**
  String get templateAbsDescription;

  /// Name of the Full Abs workout template.
  ///
  /// In en, this message translates to:
  /// **'Full Abs'**
  String get templateAbsName;

  /// Description of the CrossFit workout template.
  ///
  /// In en, this message translates to:
  /// **'High-intensity functional fitness training'**
  String get templateCrossFitDescription;

  /// Name of the CrossFit workout template.
  ///
  /// In en, this message translates to:
  /// **'CrossFit'**
  String get templateCrossFitName;

  /// Description of the default workout template.
  ///
  /// In en, this message translates to:
  /// **'Default workout with standard settings'**
  String get templateDefaultDescription;

  /// Name of the default workout template.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get templateDefaultName;

  /// Badge shown on the template that is currently applied.
  ///
  /// In en, this message translates to:
  /// **'APPLIED'**
  String get templatesApplied;

  /// Detail label for the preparation time on a template card.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get templatesPreparation;

  /// Detail label for the rest time on a template card.
  ///
  /// In en, this message translates to:
  /// **'Rest Time'**
  String get templatesRestTime;

  /// Detail label for the round time on a template card.
  ///
  /// In en, this message translates to:
  /// **'Round Time'**
  String get templatesRoundTime;

  /// Subtitle on the templates page.
  ///
  /// In en, this message translates to:
  /// **'Select a pre-configured workout to get started quickly.'**
  String get templatesSubtitle;

  /// Title of the templates page app bar.
  ///
  /// In en, this message translates to:
  /// **'Choose a Workout Template'**
  String get templatesTitle;

  /// Label above the total time on a template card.
  ///
  /// In en, this message translates to:
  /// **'Total Workout Time'**
  String get templatesTotalWorkoutTime;

  /// Label of the button that applies a template.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get templatesUseButton;

  /// Title of the timer setup page app bar.
  ///
  /// In en, this message translates to:
  /// **'Prepared for the new challenge?'**
  String get timerSetupTitle;
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
