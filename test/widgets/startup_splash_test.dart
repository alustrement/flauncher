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

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  final greeting = find.textContaining(RegExp(r"^Bon(jour|soir)$"));

  testWidgets("Covers the page and ignores the keys until it is refreshed and the frames are smooth", (tester) async {
    final appsService = MockAppsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.refreshed).thenReturn(false);
    final keys = <LogicalKeyboardKey>[];
    await _pumpSplash(tester, appsService, keys);

    await _pumpFrames(tester, 30);
    expect(greeting, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(keys, isEmpty);

    when(appsService.refreshed).thenReturn(true);
    // a slow frame starts the count again
    await _pumpFrames(tester, 10);
    await tester.pump(Duration(milliseconds: 300));
    await _pumpFrames(tester, 10);
    expect(greeting, findsOneWidget);
    await _pumpFrames(tester, 10);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(keys, [LogicalKeyboardKey.arrowRight]);

    await _pumpFadeOut(tester);
    expect(greeting, findsNothing);
  });

  testWidgets("Fades out at the latest some time after the applications are shown", (tester) async {
    final appsService = MockAppsService();
    when(appsService.initialized).thenReturn(false);
    when(appsService.refreshed).thenReturn(false);
    await _pumpSplash(tester, appsService, []);

    await tester.pump(StartupSplash.maxWait);
    await _pumpFrames(tester, 2);
    expect(greeting, findsOneWidget);

    when(appsService.initialized).thenReturn(true);
    await _pumpFrames(tester, 2);
    await tester.pump(StartupSplash.maxWait);
    await _pumpFadeOut(tester);
    expect(greeting, findsNothing);
  });
}

/// The fade starts with the frame after the splash is ready, and ends with the frame after its duration.
Future<void> _pumpFadeOut(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(StartupSplash.fadeDuration + Duration(milliseconds: 16));
  await tester.pump();
}

Future<void> _pumpSplash(WidgetTester tester, AppsService appsService, List<LogicalKeyboardKey> keys) =>
    tester.pumpWidget(
      ChangeNotifierProvider<AppsService>.value(
        value: appsService,
        child: MaterialApp(
          locale: Locale("fr"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StartupSplash(
            child: Focus(
              autofocus: true,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) {
                  keys.add(event.logicalKey);
                }
                return KeyEventResult.handled;
              },
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

/// Frames at 60Hz.
Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; ++i) {
    await tester.pump(Duration(milliseconds: 16));
  }
}
