// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String accountAvatarTooltip(String name) {
    return 'Cuenta, $name';
  }

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSignOutConfirmMessage => '¿Quieres cerrar sesión en tu cuenta?';

  @override
  String get accountSignOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get accountSignOutError => 'No se pudo cerrar sesión. Inténtalo de nuevo.';

  @override
  String get appTitle => 'Sport Timer';

  @override
  String get authErrorAccountExists => 'Ya existe una cuenta con otro método de inicio de sesión.';

  @override
  String get authErrorNetwork => 'Error de red. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authErrorTooManyRequests => 'Demasiados intentos. Inténtalo de nuevo más tarde.';

  @override
  String get authErrorUnknown => 'El inicio de sesión falló por un error desconocido.';

  @override
  String get authErrorUserDisabled => 'Esta cuenta ha sido deshabilitada.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOpensSelectorHint => 'Abre un selector';

  @override
  String get commonPreparationTime => 'Tiempo de preparación';

  @override
  String get commonRestTime => 'Tiempo de descanso';

  @override
  String get commonRoundTime => 'Tiempo de ronda';

  @override
  String get commonRounds => 'Rondas';

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
  String get homeDrawerTimerStyles => 'Estilos del temporizador';

  @override
  String get homeMenuTooltip => 'Abrir menú';

  @override
  String get homeStartButton => 'Iniciar';

  @override
  String get homeTabHome => 'Inicio';

  @override
  String get homeTabHomeTooltip => 'Inicio';

  @override
  String get homeTabStatistics => 'Estadísticas';

  @override
  String get homeTabStatisticsTooltip => 'Estadísticas';

  @override
  String get homeTabTemplates => 'Plantillas';

  @override
  String get homeTabTemplatesTooltip => 'Plantillas de entrenamiento';

  @override
  String get loginGoogleButton => 'Continuar con Google';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginWelcome => 'Bienvenido a Sport Timer';

  @override
  String get pickerMinutes => 'Minutos';

  @override
  String get pickerSeconds => 'Segundos';

  @override
  String get statisticsDefaultUserName => 'Usuario';

  @override
  String statisticsGreeting(String name) {
    return '¡Hola, $name!';
  }

  @override
  String get statisticsSectionTitle => 'Aquí están tus estadísticas de entrenamiento';

  @override
  String get statisticsTitle => 'Tus estadísticas';

  @override
  String get templateAbsName => 'Abdominales completos';

  @override
  String get templateDefaultName => 'Por defecto';

  @override
  String get templateHyroxName => 'Hyrox';

  @override
  String get templateStretchingName => 'Estiramientos';

  @override
  String get templateStrengthName => 'Fuerza';

  @override
  String get templatesApplied => 'APLICADA';

  @override
  String get templatesPreparation => 'Preparación';

  @override
  String get templatesRestTime => 'Descanso';

  @override
  String get templatesRoundTime => 'Ronda';

  @override
  String get templatesSubtitle => 'Elige un entrenamiento preconfigurado para empezar rápido.';

  @override
  String get templatesTitle => 'Elige tu plantilla';

  @override
  String get templatesTotalWorkoutTime => 'Tiempo total de entrenamiento';

  @override
  String get templatesUseButton => 'Usar plantilla';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerNotificationTitle => 'Entrenamiento en curso';

  @override
  String get timerPausedHint => 'En pausa · toca para reanudar';

  @override
  String get timerPhaseFinished => 'Listo';

  @override
  String get timerPhasePreparation => 'Preparar';

  @override
  String get timerPhaseRest => 'Descanso';

  @override
  String get timerPhaseRound => 'Ronda';

  @override
  String get timerResume => 'Reanudar';

  @override
  String timerRoundNumberOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String timerRoundsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas completadas',
      one: '1 ronda completada',
    );
    return '$_temp0';
  }

  @override
  String get timerSetupTitle => '¿Estás listo?';

  @override
  String get timerStyleFullColor => 'Color completo';

  @override
  String get timerStyleRing => 'Anillo';

  @override
  String get timerStyleRoundsStrip => 'Barra de rondas';

  @override
  String get timerStylesTitle => 'Estilos del temporizador';

  @override
  String timerTimeLeft(String time) {
    return 'quedan $time';
  }

  @override
  String timerTotal(String time) {
    return 'Total $time';
  }
}
