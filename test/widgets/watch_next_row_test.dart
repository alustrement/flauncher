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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/watch_next_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  testWidgets("shows nothing without programs", (tester) async {
    final watchNextService = MockWatchNextService();
    when(watchNextService.permissionGranted).thenReturn(true);
    when(watchNextService.programs).thenReturn([]);

    await _pumpWidgetWithProviders(tester, watchNextService, MockAppsService());

    expect(find.text("Continue watching"), findsNothing);
  });

  testWidgets("permission hint requests permission", (tester) async {
    final watchNextService = MockWatchNextService();
    when(watchNextService.permissionGranted).thenReturn(false);
    when(watchNextService.programs).thenReturn([]);

    await _pumpWidgetWithProviders(tester, watchNextService, MockAppsService());
    await tester.tap(find.text("Grant access"));

    verify(watchNextService.requestPermission());
  });

  testWidgets("shows programs", (tester) async {
    final watchNextService = MockWatchNextService();
    final appsService = MockAppsService();
    when(watchNextService.permissionGranted).thenReturn(true);
    when(watchNextService.programs).thenReturn([
      WatchNextProgram(
        id: 1,
        packageName: "com.disney.disneyplus",
        title: "Malcolm",
        seasonNumber: "1",
        episodeNumber: "4",
        episodeTitle: "Caméra cachée",
        imageUri: "https://example.com/malcolm.jpg",
        position: Duration(minutes: 5),
        duration: Duration(minutes: 20),
      ),
      WatchNextProgram(id: 2, packageName: "tv.arte.plus7", title: "L'amanite tue-mouche"),
    ]);
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.disney.disneyplus", name: "Disney+")]);

    await mockNetworkImagesFor(() => _pumpWidgetWithProviders(tester, watchNextService, appsService));

    expect(find.text("Continue watching"), findsOneWidget);
    expect(find.text("Malcolm"), findsOneWidget);
    expect(find.text("S1 E4 · Caméra cachée"), findsOneWidget);
    expect(find.text("L'amanite tue-mouche"), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.25);
  });

  testWidgets("selecting a program opens it", (tester) async {
    final watchNextService = MockWatchNextService();
    final appsService = MockAppsService();
    final program = WatchNextProgram(id: 1, packageName: "tv.arte.plus7", title: "L'amanite tue-mouche");
    when(watchNextService.permissionGranted).thenReturn(true);
    when(watchNextService.programs).thenReturn([program]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, watchNextService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(watchNextService.open(program));
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  WatchNextService watchNextService,
  AppsService appsService,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WatchNextService>.value(value: watchNextService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, __) => MaterialApp(
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        home: Scaffold(body: SingleChildScrollView(child: WatchNextRow())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
