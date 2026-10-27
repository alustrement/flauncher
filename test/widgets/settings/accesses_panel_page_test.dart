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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/settings/accesses_panel_page.dart';
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

  late MockAppsService appsService;
  late MockMediaService mediaService;
  late MockWatchNextService watchNextService;

  setUp(() {
    appsService = MockAppsService();
    mediaService = MockMediaService();
    watchNextService = MockWatchNextService();
    when(appsService.isDefaultLauncher()).thenAnswer((_) async => true);
    when(appsService.isAccessibilityServiceEnabled()).thenAnswer((_) async => false);
    when(appsService.requestDefaultLauncher()).thenAnswer((_) async {});
    when(appsService.openAccessibilitySettings()).thenAnswer((_) async {});
    when(mediaService.permissionGranted).thenReturn(false);
    when(mediaService.openPermissionSettings()).thenAnswer((_) async {});
    when(watchNextService.permissionGranted).thenReturn(true);
    when(watchNextService.requestPermission()).thenAnswer((_) async {});
  });

  testWidgets("shows which accesses are granted", (tester) async {
    await _pumpWidgetWithProviders(tester, appsService, mediaService, watchNextService);

    expect(find.byKey(Key("Launcher par défaut-granted")), findsOneWidget);
    expect(find.byKey(Key("Programmes TV-granted")), findsOneWidget);
    expect(find.byKey(Key("Accès aux notifications-missing")), findsOneWidget);
    expect(find.byKey(Key("Accessibilité-missing")), findsOneWidget);
  });

  testWidgets("pressing a missing access asks for it, and tells how to grant it otherwise", (tester) async {
    await _pumpWidgetWithProviders(tester, appsService, mediaService, watchNextService);
    expect(find.textContaining("README"), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.openPermissionSettings());
    expect(find.textContaining("README"), findsOneWidget);
  });

  testWidgets("pressing a granted access does nothing", (tester) async {
    await _pumpWidgetWithProviders(tester, appsService, mediaService, watchNextService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verifyNever(appsService.requestDefaultLauncher());
    expect(find.textContaining("appuyez sur Accueil"), findsNothing);
  });

  testWidgets("reads the accesses again when coming back to the launcher", (tester) async {
    await _pumpWidgetWithProviders(tester, appsService, mediaService, watchNextService);
    when(appsService.isAccessibilityServiceEnabled()).thenAnswer((_) async => true);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(Key("Accessibilité-granted")), findsOneWidget);
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  AppsService appsService,
  MediaService mediaService,
  WatchNextService watchNextService,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        ChangeNotifierProvider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider<WatchNextService>.value(value: watchNextService),
      ],
      builder: (_, _) => MaterialApp(home: Material(child: AccessesPanelPage())),
    ),
  );
  await tester.pumpAndSettle();
}
