/*
 * Waves Launcher TV
 * Copyright (C) 2026  Aurélien Lustrement
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

import 'package:flauncher/flauncher_app.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/categories_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = Size(1280, 720);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("keeps the night background while changing page", (tester) async {
    final settingsService = MockSettingsService();
    final appsService = MockAppsService();
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    when(settingsService.showAllApplications).thenReturn(true);
    when(settingsService.showRecentPlays).thenReturn(true);
    when(appsService.categoriesWithApps).thenReturn([]);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
          ChangeNotifierProvider<AppsService>.value(value: appsService),
        ],
        builder: (_, _) => MaterialApp(
          theme: FLauncherApp.theme,
          locale: Locale("fr"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPanel(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(Duration(milliseconds: 100));

    // the page being left is painted on a background of its own while the transition lasts
    final backgrounds = find.descendant(
      of: find.byType(SettingsPanel),
      matching: find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color.a > 0 && widget.color != ZenPalette.night,
      ),
    );
    expect(backgrounds, findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPanelPage), findsOneWidget);
  });
}
