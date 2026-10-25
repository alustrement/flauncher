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
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/widgets/now_playing_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  testWidgets("shows nothing without media session", (tester) async {
    final mediaService = MockMediaService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(null);

    await _pumpWidgetWithProviders(tester, mediaService, MockAppsService());

    expect(find.text("Now playing"), findsNothing);
  });

  testWidgets("shows permission hint when access is missing", (tester) async {
    final mediaService = MockMediaService();
    when(mediaService.permissionGranted).thenReturn(false);
    when(mediaService.nowPlaying).thenReturn(null);

    await _pumpWidgetWithProviders(tester, mediaService, MockAppsService());

    expect(find.textContaining("Notification access is required"), findsOneWidget);
  });

  testWidgets("shows media session info", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(
      packageName: "com.spotify.tv.android",
      title: "Bittersweet",
      artist: "Lianne La Havas",
      album: "Bittersweet (Radio Edit)",
      duration: Duration(minutes: 3, seconds: 56),
      position: Duration(minutes: 1, seconds: 5),
    ));
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.spotify.tv.android", name: "Spotify")]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("Now playing"), findsOneWidget);
    expect(find.text("Spotify"), findsOneWidget);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(find.text("Lianne La Havas · Bittersweet (Radio Edit)"), findsOneWidget);
    expect(find.text("1:05"), findsOneWidget);
    expect(find.text("3:56"), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets("does not repeat the title as subtitle", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(
      packageName: "fr.francetv.pluzz",
      title: "C dans l'air",
      artist: "C dans l'air",
    ));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("C dans l'air"), findsOneWidget);
  });

  testWidgets("controls call MediaService", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(
      packageName: "com.spotify.tv.android",
      title: "Bittersweet",
      playing: true,
      canSkipNext: true,
      canSkipPrevious: true,
    ));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.tap(find.byIcon(Icons.music_note));
    verify(mediaService.playPause());
    verify(mediaService.skipToNext());
    verify(mediaService.skipToPrevious());
    verify(mediaService.openPlayer());
  });

  testWidgets("skip buttons are disabled when unsupported", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(packageName: "com.netflix.ninja"));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.tap(find.byIcon(Icons.skip_previous));
    verifyNever(mediaService.skipToNext());
    verifyNever(mediaService.skipToPrevious());
  });

  testWidgets("controls are reachable with D-pad", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(packageName: "com.spotify.tv.android", playing: true));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    verify(mediaService.playPause());
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  MediaService mediaService,
  AppsService appsService,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, __) => MaterialApp(
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        home: Scaffold(body: SingleChildScrollView(child: NowPlayingPanel())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
