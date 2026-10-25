/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/actions.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/home_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'flauncher.dart';
import 'flauncher_channel.dart';

class FLauncherApp extends StatelessWidget {
  final SharedPreferences _sharedPreferences;
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _fLauncherDatabase;

  static const MaterialColor _swatch = MaterialColor(0xFF6F5DF1, <int, Color>{
    50: Color(0xFFEEEBFF),
    100: Color(0xFFD6CFFF),
    200: Color(0xFFB9AEFF),
    300: Color(0xFF8E7CFF),
    400: Color(0xFF7A69F3),
    500: Color(0xFF6F5DF1),
    600: Color(0xFF6840F9),
    700: Color(0xFF652BFB),
    800: Color(0xFF6500FE),
    900: Color(0xFF4A00BA),
  });

  FLauncherApp(this._sharedPreferences, this._fLauncherChannel, this._fLauncherDatabase);

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsService(_sharedPreferences), lazy: false),
      ChangeNotifierProvider(create: (_) => AppsService(_fLauncherChannel, _fLauncherDatabase)),
      // listening right away, so that the media playing and the programs are known by the time the apps are shown
      ChangeNotifierProvider(create: (_) => MediaService(_fLauncherChannel), lazy: false),
      ChangeNotifierProvider(create: (_) => WatchNextService(_fLauncherChannel), lazy: false),
      ChangeNotifierProvider(create: (_) => HomeService(_fLauncherChannel), lazy: false),
    ],
    child: MaterialApp(
      locale: Locale("fr"),
      supportedLocales: [Locale("fr")],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonB): PrioritizedIntents(
          orderedIntents: [DismissIntent(), BackIntent()],
        ),
      },
      actions: {...WidgetsApp.defaultActions, DirectionalFocusIntent: SoundFeedbackDirectionalFocusAction(context)},
      title: 'FLauncher',
      theme: ThemeData(
        // the Zen look is drawn on Material 2
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: _swatch,
          accentColor: _swatch[200],
          cardColor: ZenPalette.surface,
          brightness: Brightness.dark,
        ),
        // what a dark theme made from a swatch had, before its color scheme was given
        primaryColor: Colors.grey[900],
        cardColor: ZenPalette.surface,
        canvasColor: ZenPalette.surface,
        scaffoldBackgroundColor: ZenPalette.night,
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.white)),
        appBarTheme: AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
        typography: Typography.material2018(),
        fontFamily: "Outfit",
        textTheme: TextTheme(titleLarge: TextStyle(fontWeight: FontWeight.w400)),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          labelStyle: Typography.material2018().white.bodyMedium,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: _swatch[300],
          selectionHandleColor: _swatch[200],
        ),
        dialogTheme: DialogThemeData(backgroundColor: ZenPalette.night),
      ),
      home: Builder(
        builder: (context) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (await shouldPopScope(context)) {
              SystemNavigator.pop();
            } else if (context.mounted) {
              context.read<AppsService>().startAmbientMode();
            }
          },
          child: StartupSplash(
            child: Actions(actions: {BackIntent: BackAction(context, systemNavigator: true)}, child: FLauncher()),
          ),
        ),
      ),
    ),
  );
}
