// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get templateAbsDescription => 'Entrenamiento abdominal intenso con rondas cortas';

  @override
  String get templateAbsName => 'Abdominales completos';

  @override
  String get templateCrossFitDescription => 'Entrenamiento funcional de alta intensidad';

  @override
  String get templateCrossFitName => 'CrossFit';

  @override
  String get templateDefaultDescription => 'Entrenamiento por defecto con ajustes estándar';

  @override
  String get templateDefaultName => 'Por defecto';

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
  String get templatesTitle => 'Elige una plantilla de entrenamiento';

  @override
  String get templatesTotalWorkoutTime => 'Tiempo total de entrenamiento';

  @override
  String get templatesUseButton => 'Usar plantilla';

  @override
  String get timerSetupTitle => '¿Listo para el nuevo reto?';
}
