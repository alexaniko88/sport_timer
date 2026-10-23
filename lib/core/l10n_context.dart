import 'package:flutter/material.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
