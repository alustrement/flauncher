// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get goodDay => 'Bonjour';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get allApplications => 'Toutes les applications';

  @override
  String get tvApplications => 'Applis TV';

  @override
  String get nonTvApplications => 'Applis non TV';

  @override
  String get hiddenApplications => 'Applis masquées';

  @override
  String get emptyCategory => 'Cette catégorie est vide.';

  @override
  String get addTo => 'Ajouter à…';

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get renameCategory => 'Renommer la catégorie';

  @override
  String get name => 'Nom';

  @override
  String get mustNotBeEmpty => 'Ne doit pas être vide';

  @override
  String get open => 'Ouvrir';

  @override
  String get move => 'Déplacer';

  @override
  String get show => 'Afficher';

  @override
  String get hide => 'Masquer';

  @override
  String removeFrom(String category) {
    return 'Retirer de $category';
  }

  @override
  String get applicationInfo => 'Infos sur l\'appli';

  @override
  String get uninstall => 'Désinstaller';

  @override
  String get nowPlaying => 'En cours de lecture';

  @override
  String get resumePlayback => 'Reprendre la lecture';

  @override
  String get onAnotherDevice => 'Sur un autre appareil';

  @override
  String get notificationAccessNeeded => 'L\'accès aux notifications est nécessaire pour afficher la lecture en cours.';

  @override
  String get notificationAccessGrantHint => 'Accordez-le dans Paramètres > Autorisations et launcher par défaut.';

  @override
  String get recentPlays => 'Lectures récentes';

  @override
  String get tvProgramsAccessNeeded =>
      'L\'accès aux programmes TV est nécessaire pour afficher ce que vous pouvez continuer à regarder.';

  @override
  String get allow => 'Autoriser';

  @override
  String get settings => 'Paramètres';

  @override
  String get applications => 'Applications';

  @override
  String get categories => 'Catégories';

  @override
  String get accessesAndDefaultLauncher => 'Autorisations et launcher par défaut';

  @override
  String get use24HourTimeFormat => 'Format 24 heures';

  @override
  String get showAllApplications => 'Afficher toutes les applications';

  @override
  String get showRecentPlays => 'Afficher les lectures récentes';

  @override
  String get deviceSettings => 'Paramètres de l\'appareil';

  @override
  String get about => 'À propos de Waves Launcher TV';

  @override
  String get aboutDescription =>
      'Waves Launcher TV est un launcher alternatif et open source pour Android TV, basé sur FLauncher et distribué sous licence GPLv3.\nCode source disponible sur ';

  @override
  String get sort => 'Tri';

  @override
  String get alphabetical => 'Alphabétique';

  @override
  String get manual => 'Manuel';

  @override
  String get type => 'Type';

  @override
  String get row => 'Ligne';

  @override
  String get grid => 'Grille';

  @override
  String get columnCount => 'Nombre de colonnes';

  @override
  String get rowHeight => 'Hauteur de ligne';

  @override
  String get delete => 'Supprimer';

  @override
  String get defaultLauncher => 'Launcher par défaut';

  @override
  String get defaultLauncherFeature => 'Ouvert par le bouton Accueil';

  @override
  String get defaultLauncherHint =>
      'Si aucune fenêtre ne s\'est ouverte, appuyez sur Accueil et choisissez Waves Launcher TV, puis « Toujours ».';

  @override
  String get tvPrograms => 'Programmes TV';

  @override
  String get tvProgramsHint =>
      'Si aucune fenêtre ne s\'est ouverte, autorisez « Lire toutes les sources TV » dans Paramètres > Applications > Waves Launcher TV > Autorisations.';

  @override
  String get notificationAccess => 'Accès aux notifications';

  @override
  String get notificationAccessHint =>
      'Si aucun écran ne s\'est ouvert, les paramètres de cet appareil ne permettent pas de l\'accorder : voir le README de Waves Launcher TV.';

  @override
  String get nowPlayingFeature => 'Lecture en cours';

  @override
  String get accessibility => 'Accessibilité';

  @override
  String get accessibilityFeature => 'Applis récentes en appuyant deux fois sur Accueil';

  @override
  String get accessibilityHint =>
      'Si aucun écran ne s\'est ouvert, activez Waves Launcher TV dans Paramètres > Préférences de l\'appareil > Accessibilité.';
}
