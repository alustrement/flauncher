import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// No description provided for @goodDay.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get goodDay;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @allApplications.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get allApplications;

  /// No description provided for @tvApplications.
  ///
  /// In en, this message translates to:
  /// **'TV apps'**
  String get tvApplications;

  /// No description provided for @nonTvApplications.
  ///
  /// In en, this message translates to:
  /// **'Non-TV apps'**
  String get nonTvApplications;

  /// No description provided for @hiddenApplications.
  ///
  /// In en, this message translates to:
  /// **'Hidden apps'**
  String get hiddenApplications;

  /// No description provided for @emptyCategory.
  ///
  /// In en, this message translates to:
  /// **'This category is empty.'**
  String get emptyCategory;

  /// No description provided for @addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to…'**
  String get addTo;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @mustNotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Must not be empty'**
  String get mustNotBeEmpty;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @removeFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove from {category}'**
  String removeFrom(String category);

  /// No description provided for @applicationInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get applicationInfo;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @resumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get resumePlayback;

  /// No description provided for @onAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'On another device'**
  String get onAnotherDevice;

  /// No description provided for @notificationAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Notification access is needed to show what is playing.'**
  String get notificationAccessNeeded;

  /// No description provided for @notificationAccessGrantHint.
  ///
  /// In en, this message translates to:
  /// **'Grant it in Settings > Permissions and default launcher.'**
  String get notificationAccessGrantHint;

  /// No description provided for @recentPlays.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get recentPlays;

  /// No description provided for @tvProgramsAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Access to TV programs is needed to show what you can keep watching.'**
  String get tvProgramsAccessNeeded;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get applications;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @accessesAndDefaultLauncher.
  ///
  /// In en, this message translates to:
  /// **'Permissions and default launcher'**
  String get accessesAndDefaultLauncher;

  /// No description provided for @use24HourTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'24-hour format'**
  String get use24HourTimeFormat;

  /// No description provided for @showAllApplications.
  ///
  /// In en, this message translates to:
  /// **'Show all apps'**
  String get showAllApplications;

  /// No description provided for @showRecentPlays.
  ///
  /// In en, this message translates to:
  /// **'Show recently played'**
  String get showRecentPlays;

  /// No description provided for @deviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device settings'**
  String get deviceSettings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Waves Launcher TV'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Waves Launcher TV is an alternative, open-source launcher for Android TV, based on FLauncher and released under the GPLv3 license.\nSource code available at '**
  String get aboutDescription;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @row.
  ///
  /// In en, this message translates to:
  /// **'Row'**
  String get row;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @columnCount.
  ///
  /// In en, this message translates to:
  /// **'Number of columns'**
  String get columnCount;

  /// No description provided for @rowHeight.
  ///
  /// In en, this message translates to:
  /// **'Row height'**
  String get rowHeight;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @defaultLauncher.
  ///
  /// In en, this message translates to:
  /// **'Default launcher'**
  String get defaultLauncher;

  /// No description provided for @defaultLauncherFeature.
  ///
  /// In en, this message translates to:
  /// **'Opened by the Home button'**
  String get defaultLauncherFeature;

  /// No description provided for @defaultLauncherHint.
  ///
  /// In en, this message translates to:
  /// **'If no window opened, press Home and choose Waves Launcher TV, then “Always”.'**
  String get defaultLauncherHint;

  /// No description provided for @tvPrograms.
  ///
  /// In en, this message translates to:
  /// **'TV programs'**
  String get tvPrograms;

  /// No description provided for @tvProgramsHint.
  ///
  /// In en, this message translates to:
  /// **'If no window opened, allow “Read all TV sources” in Settings > Apps > Waves Launcher TV > Permissions.'**
  String get tvProgramsHint;

  /// No description provided for @notificationAccess.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get notificationAccess;

  /// No description provided for @notificationAccessHint.
  ///
  /// In en, this message translates to:
  /// **'If no screen opened, the settings of this device don\'t allow granting it: see the README of Waves Launcher TV.'**
  String get notificationAccessHint;

  /// No description provided for @nowPlayingFeature.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlayingFeature;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @accessibilityFeature.
  ///
  /// In en, this message translates to:
  /// **'Recent apps by pressing Home twice'**
  String get accessibilityFeature;

  /// No description provided for @accessibilityHint.
  ///
  /// In en, this message translates to:
  /// **'If no screen opened, turn on Waves Launcher TV in Settings > Device Preferences > Accessibility.'**
  String get accessibilityHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
