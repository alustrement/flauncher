// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get goodDay => 'Buongiorno';

  @override
  String get goodEvening => 'Buonasera';

  @override
  String get allApplications => 'Tutte le app';

  @override
  String get tvApplications => 'App TV';

  @override
  String get nonTvApplications => 'App non TV';

  @override
  String get hiddenApplications => 'App nascoste';

  @override
  String get emptyCategory => 'Questa categoria è vuota.';

  @override
  String get addTo => 'Aggiungi a…';

  @override
  String get addCategory => 'Aggiungi una categoria';

  @override
  String get renameCategory => 'Rinomina la categoria';

  @override
  String get name => 'Nome';

  @override
  String get mustNotBeEmpty => 'Non può essere vuoto';

  @override
  String get open => 'Apri';

  @override
  String get move => 'Sposta';

  @override
  String get show => 'Mostra';

  @override
  String get hide => 'Nascondi';

  @override
  String removeFrom(String category) {
    return 'Rimuovi da $category';
  }

  @override
  String get applicationInfo => 'Info sull\'app';

  @override
  String get uninstall => 'Disinstalla';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get resumePlayback => 'Riprendi la riproduzione';

  @override
  String get onAnotherDevice => 'Su un altro dispositivo';

  @override
  String get notificationAccessNeeded =>
      'L\'accesso alle notifiche è necessario per mostrare la riproduzione in corso.';

  @override
  String get notificationAccessGrantHint => 'Concedilo in Impostazioni > Autorizzazioni e launcher predefinito.';

  @override
  String get recentPlays => 'Riprodotti di recente';

  @override
  String get tvProgramsAccessNeeded =>
      'L\'accesso ai programmi TV è necessario per mostrare cosa puoi continuare a guardare.';

  @override
  String get allow => 'Consenti';

  @override
  String get settings => 'Impostazioni';

  @override
  String get applications => 'App';

  @override
  String get categories => 'Categorie';

  @override
  String get accessesAndDefaultLauncher => 'Autorizzazioni e launcher predefinito';

  @override
  String get use24HourTimeFormat => 'Formato 24 ore';

  @override
  String get showAllApplications => 'Mostra tutte le app';

  @override
  String get showRecentPlays => 'Mostra i riprodotti di recente';

  @override
  String get deviceSettings => 'Impostazioni del dispositivo';

  @override
  String get about => 'Informazioni su Waves Launcher TV';

  @override
  String get aboutDescription =>
      'Waves Launcher TV è un launcher alternativo e open source per Android TV, basato su FLauncher e distribuito con licenza GPLv3.\nCodice sorgente disponibile su ';

  @override
  String get sort => 'Ordine';

  @override
  String get alphabetical => 'Alfabetico';

  @override
  String get manual => 'Manuale';

  @override
  String get type => 'Tipo';

  @override
  String get row => 'Riga';

  @override
  String get grid => 'Griglia';

  @override
  String get columnCount => 'Numero di colonne';

  @override
  String get rowHeight => 'Altezza della riga';

  @override
  String get delete => 'Elimina';

  @override
  String get defaultLauncher => 'Launcher predefinito';

  @override
  String get defaultLauncherFeature => 'Aperto dal tasto Home';

  @override
  String get defaultLauncherHint =>
      'Se non si è aperta nessuna finestra, è perché il launcher originale del dispositivo non può essere sostituito qui, va disattivato con lo strumento adb (vedi il README di Waves Launcher TV).';

  @override
  String get tvPrograms => 'Programmi TV';

  @override
  String get tvProgramsHint =>
      'Se non si è aperta nessuna finestra, consenti «Leggere tutte le sorgenti TV» in Impostazioni > App > Waves Launcher TV > Autorizzazioni.';

  @override
  String get notificationAccess => 'Accesso alle notifiche';

  @override
  String get notificationAccessHint =>
      'Attiva Waves Launcher TV in Impostazioni > App > Accesso speciale alle app > Accesso alle notifiche.';

  @override
  String get nowPlayingFeature => 'Riproduzione in corso';

  @override
  String get accessibility => 'Accessibilità';

  @override
  String get accessibilityFeature => 'App recenti premendo due volte Home';

  @override
  String get accessibilityHint => 'Attiva Waves Launcher TV in Impostazioni > Preferenze dispositivo > Accessibilità.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get cancel => 'Annulla';
}
