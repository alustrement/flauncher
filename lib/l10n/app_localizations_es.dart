// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get goodDay => 'Hola';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get allApplications => 'Todas las aplicaciones';

  @override
  String get tvApplications => 'Apps de TV';

  @override
  String get nonTvApplications => 'Apps que no son de TV';

  @override
  String get hiddenApplications => 'Apps ocultas';

  @override
  String get emptyCategory => 'Esta categoría está vacía.';

  @override
  String get addTo => 'Añadir a…';

  @override
  String get addCategory => 'Añadir una categoría';

  @override
  String get renameCategory => 'Cambiar el nombre de la categoría';

  @override
  String get name => 'Nombre';

  @override
  String get mustNotBeEmpty => 'No puede estar vacío';

  @override
  String get open => 'Abrir';

  @override
  String get move => 'Mover';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String removeFrom(String category) {
    return 'Quitar de $category';
  }

  @override
  String get applicationInfo => 'Información de la app';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get resumePlayback => 'Reanudar la reproducción';

  @override
  String get onAnotherDevice => 'En otro dispositivo';

  @override
  String get notificationAccessNeeded =>
      'Se necesita el acceso a las notificaciones para mostrar lo que se está reproduciendo.';

  @override
  String get notificationAccessGrantHint => 'Concédelo en Ajustes > Permisos y launcher predeterminado.';

  @override
  String get recentPlays => 'Reproducciones recientes';

  @override
  String get tvProgramsAccessNeeded =>
      'Se necesita el acceso a los programas de TV para mostrar lo que puedes seguir viendo.';

  @override
  String get allow => 'Permitir';

  @override
  String get settings => 'Ajustes';

  @override
  String get applications => 'Aplicaciones';

  @override
  String get categories => 'Categorías';

  @override
  String get accessesAndDefaultLauncher => 'Permisos y launcher predeterminado';

  @override
  String get use24HourTimeFormat => 'Formato de 24 horas';

  @override
  String get showAllApplications => 'Mostrar todas las aplicaciones';

  @override
  String get showRecentPlays => 'Mostrar las reproducciones recientes';

  @override
  String get deviceSettings => 'Ajustes del dispositivo';

  @override
  String get about => 'Acerca de Waves Launcher TV';

  @override
  String get aboutDescription =>
      'Waves Launcher TV es un launcher alternativo y de código abierto para Android TV, basado en FLauncher y distribuido bajo la licencia GPLv3.\nCódigo fuente disponible en ';

  @override
  String get sort => 'Orden';

  @override
  String get alphabetical => 'Alfabético';

  @override
  String get manual => 'Manual';

  @override
  String get type => 'Tipo';

  @override
  String get row => 'Fila';

  @override
  String get grid => 'Cuadrícula';

  @override
  String get columnCount => 'Número de columnas';

  @override
  String get rowHeight => 'Altura de la fila';

  @override
  String get delete => 'Eliminar';

  @override
  String get defaultLauncher => 'Launcher predeterminado';

  @override
  String get defaultLauncherFeature => 'Abierto con el botón Inicio';

  @override
  String get defaultLauncherHint =>
      'Si no se ha abierto ninguna ventana, es porque el launcher original del dispositivo no se puede sustituir aquí, hay que desactivarlo con la herramienta adb (consulta el README de Waves Launcher TV).';

  @override
  String get tvPrograms => 'Programas de TV';

  @override
  String get tvProgramsHint =>
      'Si no se ha abierto ninguna ventana, permite «Leer todas las fuentes de TV» en Ajustes > Aplicaciones > Waves Launcher TV > Permisos.';

  @override
  String get notificationAccess => 'Acceso a las notificaciones';

  @override
  String get notificationAccessHint =>
      'Activa Waves Launcher TV en Ajustes > Aplicaciones > Acceso especial de aplicaciones > Acceso a notificaciones.';

  @override
  String get nowPlayingFeature => 'Reproducción en curso';

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get accessibilityFeature => 'Apps recientes al pulsar Inicio dos veces';

  @override
  String get accessibilityHint => 'Activa Waves Launcher TV en Ajustes > Preferencias del dispositivo > Accesibilidad.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get cancel => 'Cancelar';
}
