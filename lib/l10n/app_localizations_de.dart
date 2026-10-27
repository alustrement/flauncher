// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get goodDay => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get allApplications => 'Alle Apps';

  @override
  String get tvApplications => 'TV-Apps';

  @override
  String get nonTvApplications => 'Andere Apps';

  @override
  String get hiddenApplications => 'Ausgeblendete Apps';

  @override
  String get emptyCategory => 'Diese Kategorie ist leer.';

  @override
  String get addTo => 'Hinzufügen zu…';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get renameCategory => 'Kategorie umbenennen';

  @override
  String get name => 'Name';

  @override
  String get mustNotBeEmpty => 'Darf nicht leer sein';

  @override
  String get open => 'Öffnen';

  @override
  String get move => 'Verschieben';

  @override
  String get show => 'Einblenden';

  @override
  String get hide => 'Ausblenden';

  @override
  String removeFrom(String category) {
    return 'Aus $category entfernen';
  }

  @override
  String get applicationInfo => 'App-Info';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get nowPlaying => 'Wird gerade wiedergegeben';

  @override
  String get resumePlayback => 'Wiedergabe fortsetzen';

  @override
  String get onAnotherDevice => 'Auf einem anderen Gerät';

  @override
  String get notificationAccessNeeded =>
      'Der Zugriff auf Benachrichtigungen wird benötigt, um die aktuelle Wiedergabe anzuzeigen.';

  @override
  String get notificationAccessGrantHint => 'Erteile ihn unter Einstellungen > Berechtigungen und Standard-Launcher.';

  @override
  String get recentPlays => 'Zuletzt wiedergegeben';

  @override
  String get tvProgramsAccessNeeded =>
      'Der Zugriff auf TV-Programme wird benötigt, um anzuzeigen, was du weiterschauen kannst.';

  @override
  String get allow => 'Erlauben';

  @override
  String get settings => 'Einstellungen';

  @override
  String get applications => 'Apps';

  @override
  String get categories => 'Kategorien';

  @override
  String get accessesAndDefaultLauncher => 'Berechtigungen und Standard-Launcher';

  @override
  String get use24HourTimeFormat => '24-Stunden-Format';

  @override
  String get showAllApplications => 'Alle Apps anzeigen';

  @override
  String get showRecentPlays => 'Zuletzt wiedergegebene anzeigen';

  @override
  String get deviceSettings => 'Geräteeinstellungen';

  @override
  String get about => 'Über Waves Launcher TV';

  @override
  String get aboutDescription =>
      'Waves Launcher TV ist ein alternativer Open-Source-Launcher für Android TV, der auf FLauncher basiert und unter der GPLv3-Lizenz veröffentlicht wird.\nQuellcode verfügbar unter ';

  @override
  String get sort => 'Sortierung';

  @override
  String get alphabetical => 'Alphabetisch';

  @override
  String get manual => 'Manuell';

  @override
  String get type => 'Typ';

  @override
  String get row => 'Zeile';

  @override
  String get grid => 'Raster';

  @override
  String get columnCount => 'Anzahl der Spalten';

  @override
  String get rowHeight => 'Zeilenhöhe';

  @override
  String get delete => 'Löschen';

  @override
  String get defaultLauncher => 'Standard-Launcher';

  @override
  String get defaultLauncherFeature => 'Wird mit der Home-Taste geöffnet';

  @override
  String get defaultLauncherHint =>
      'Wenn sich kein Fenster geöffnet hat, kann der vorinstallierte Launcher des Geräts hier nicht ersetzt werden, er muss mit dem Tool adb deaktiviert werden (siehe die README von Waves Launcher TV).';

  @override
  String get tvPrograms => 'TV-Programme';

  @override
  String get tvProgramsHint =>
      'Wenn sich kein Fenster geöffnet hat, erlaube „Alle TV-Quellen lesen“ unter Einstellungen > Apps > Waves Launcher TV > Berechtigungen.';

  @override
  String get notificationAccess => 'Zugriff auf Benachrichtigungen';

  @override
  String get notificationAccessHint =>
      'Aktiviere Waves Launcher TV unter Einstellungen > Apps > Spezieller App-Zugriff > Benachrichtigungszugriff.';

  @override
  String get nowPlayingFeature => 'Aktuelle Wiedergabe';

  @override
  String get accessibility => 'Bedienungshilfen';

  @override
  String get accessibilityFeature => 'Letzte Apps durch zweimaliges Drücken der Home-Taste';

  @override
  String get accessibilityHint =>
      'Aktiviere Waves Launcher TV unter Einstellungen > Geräteeinstellungen > Bedienungshilfen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get cancel => 'Abbrechen';
}
