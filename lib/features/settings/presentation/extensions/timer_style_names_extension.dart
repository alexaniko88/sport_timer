import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

extension TimerStyleNames on AppLocalizations {
  String timerStyleName(TimerStyle style) => switch (style) {
        TimerStyle.ring => timerStyleRing,
        TimerStyle.fullColor => timerStyleFullColor,
        TimerStyle.roundsStrip => timerStyleRoundsStrip,
      };
}
