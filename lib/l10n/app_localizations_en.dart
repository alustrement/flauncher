// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get goodDay => 'Hello';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get allApplications => 'All apps';

  @override
  String get tvApplications => 'TV apps';

  @override
  String get nonTvApplications => 'Non-TV apps';

  @override
  String get hiddenApplications => 'Hidden apps';

  @override
  String get emptyCategory => 'This category is empty.';

  @override
  String get addTo => 'Add to…';

  @override
  String get addCategory => 'Add category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get name => 'Name';

  @override
  String get mustNotBeEmpty => 'Must not be empty';

  @override
  String get open => 'Open';

  @override
  String get move => 'Move';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String removeFrom(String category) {
    return 'Remove from $category';
  }

  @override
  String get applicationInfo => 'App info';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get resumePlayback => 'Resume playback';

  @override
  String get onAnotherDevice => 'On another device';

  @override
  String get notificationAccessNeeded => 'Notification access is needed to show what is playing.';

  @override
  String get notificationAccessGrantHint => 'Grant it in Settings > Permissions and default launcher.';

  @override
  String get recentPlays => 'Recently played';

  @override
  String get tvProgramsAccessNeeded => 'Access to TV programs is needed to show what you can keep watching.';

  @override
  String get allow => 'Allow';

  @override
  String get settings => 'Settings';

  @override
  String get applications => 'Apps';

  @override
  String get categories => 'Categories';

  @override
  String get accessesAndDefaultLauncher => 'Permissions and default launcher';

  @override
  String get use24HourTimeFormat => '24-hour format';

  @override
  String get showAllApplications => 'Show all apps';

  @override
  String get showRecentPlays => 'Show recently played';

  @override
  String get deviceSettings => 'Device settings';

  @override
  String get about => 'About Waves Launcher TV';

  @override
  String get aboutDescription =>
      'Waves Launcher TV is an alternative, open-source launcher for Android TV, based on FLauncher and released under the GPLv3 license.\nSource code available at ';

  @override
  String get sort => 'Sort';

  @override
  String get alphabetical => 'Alphabetical';

  @override
  String get manual => 'Manual';

  @override
  String get type => 'Type';

  @override
  String get row => 'Row';

  @override
  String get grid => 'Grid';

  @override
  String get columnCount => 'Number of columns';

  @override
  String get rowHeight => 'Row height';

  @override
  String get delete => 'Delete';

  @override
  String get defaultLauncher => 'Default launcher';

  @override
  String get defaultLauncherFeature => 'Opened by the Home button';

  @override
  String get defaultLauncherHint =>
      'If no window opened, it\'s because the stock launcher of the device can\'t be replaced here, it has to be disabled with the adb tool (see the README of Waves Launcher TV).';

  @override
  String get tvPrograms => 'TV programs';

  @override
  String get tvProgramsHint =>
      'If no window opened, allow “Read all TV sources” in Settings > Apps > Waves Launcher TV > Permissions.';

  @override
  String get notificationAccess => 'Notification access';

  @override
  String get notificationAccessHint =>
      'Turn on Waves Launcher TV in Settings > Apps > Special app access > Notification access.';

  @override
  String get nowPlayingFeature => 'Now playing';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get accessibilityFeature => 'Recent apps by pressing Home twice';

  @override
  String get accessibilityHint => 'Turn on Waves Launcher TV in Settings > Device Preferences > Accessibility.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cancel => 'Cancel';
}
