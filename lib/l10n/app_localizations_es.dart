// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get setupSessionLength => 'Duración de la sesión';

  @override
  String get setupPreparation => 'Preparación';

  @override
  String get setupWork => 'Trabajo';

  @override
  String get setupRest => 'Descanso';

  @override
  String setupTemplateLabel(String name) {
    return 'Plantilla: $name';
  }

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
  String get homeDrawerTemplates => 'Plantillas';

  @override
  String get homeDrawerTimerStyles => 'Estilos del temporizador';

  @override
  String get homeMenuTooltip => 'Abrir menú';

  @override
  String get homeStartButton => 'Iniciar';

  @override
  String get homeTabTimer => 'Temporizador';

  @override
  String get homeTabTimerTooltip => 'Temporizador';

  @override
  String get homeTabStatistics => 'Estadísticas';

  @override
  String get homeTabStatisticsTooltip => 'Estadísticas';

  @override
  String get loginGoogleButton => 'Continuar con Google';

  @override
  String get loginWelcome => 'Bienvenido a Sport Timer';

  @override
  String get pickerMinutes => 'Minutos';

  @override
  String get pickerSeconds => 'Segundos';

  @override
  String get statisticsRetryButton => 'Reintentar';

  @override
  String get statisticsSectionTitle => 'Aquí están tus estadísticas de entrenamiento';

  @override
  String get statisticsTitle => 'Tus estadísticas';

  @override
  String get templateAbsName => 'Abdominales completos';

  @override
  String get templateCustomName => 'Personalizado';

  @override
  String templateCustomTileSemantics(String preparation, String round, String rest, int rounds, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rondas',
      one: '1 ronda',
    );
    return 'Ajustes personalizados. Tiempo de preparación $preparation, tiempo de ronda $round, tiempo de descanso $rest, $_temp0, tiempo total $total';
  }

  @override
  String templateCustomTileSummary(String preparation, String work, String rest, int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rondas',
      one: '1 ronda',
    );
    return '$preparation preparación · $work trabajo · $rest descanso · $_temp0';
  }

  @override
  String get templateDefaultName => 'Por defecto';

  @override
  String get templateHyroxName => 'Hyrox';

  @override
  String get templateStretchingName => 'Estiramientos';

  @override
  String get templateStrengthName => 'Fuerza';

  @override
  String templateTileSemantics(String name, String round, String rest, int rounds, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rondas',
      one: '1 ronda',
    );
    return '$name. Tiempo de ronda $round, tiempo de descanso $rest, $_temp0, tiempo total $total';
  }

  @override
  String templateTileSummary(String work, String rest, int rounds) {
    String _temp0 = intl.Intl.pluralLogic(
      rounds,
      locale: localeName,
      other: '$rounds rondas',
      one: '1 ronda',
    );
    return '$work trabajo · $rest descanso · $_temp0';
  }

  @override
  String get templatesTitle => 'Elige tu plantilla';

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

  @override
  String get statisticsEmpty => 'Aún no hay actividad completada.';

  @override
  String get statisticsError => 'No se pudieron cargar tus estadísticas.';

  @override
  String get dayDetailsTitle => 'Detalles del día';

  @override
  String get dayDetailsEmpty => 'No hay actividad completada para este día.';

  @override
  String get dayDetailsError => 'No se pudo cargar este día.';

  @override
  String get dayDetailsSummary => 'Total del día';

  @override
  String get dayDetailsActivity => 'Actividad de este día';

  @override
  String get dayDetailsConfiguration => 'Configuración original';

  @override
  String statisticsRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas',
      one: '1 ronda',
    );
    return '$_temp0';
  }

  @override
  String statisticsHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String statisticsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String statisticsSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String statisticsWorkValue(String value) {
    return 'Trabajo: $value';
  }

  @override
  String statisticsRestValue(String value) {
    return 'Descanso: $value';
  }

  @override
  String statisticsTotalValue(String value) {
    return 'Total: $value';
  }

  @override
  String statisticsTileSemantics(String date, String rounds, String work, String rest, String total) {
    return '$date, $rounds, trabajo $work, descanso $rest, total $total';
  }

  @override
  String get statisticsViewList => 'Lista';

  @override
  String get statisticsViewCharts => 'Gráficos';

  @override
  String get statisticsPerspective => 'Perspectiva';

  @override
  String get statisticsWorkTime => 'Tiempo de trabajo';

  @override
  String get statisticsWeek => 'Semana';

  @override
  String get statisticsMonth => 'Mes';

  @override
  String get statisticsYear => 'Año';

  @override
  String get statisticsPreviousPeriod => 'Periodo anterior';

  @override
  String get statisticsNextPeriod => 'Periodo siguiente';

  @override
  String get statisticsChartEmpty => 'No hay actividad registrada en este periodo.';

  @override
  String get statisticsFuture => 'Futuro';

  @override
  String get statisticsPeriodTotal => 'Total del periodo';

  @override
  String statisticsChartBucket(String date, String value) {
    return '$date, $value';
  }

  @override
  String statisticsChartScale(String value) {
    return 'Escala: $value';
  }
}
