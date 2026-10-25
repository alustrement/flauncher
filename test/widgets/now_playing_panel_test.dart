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

import 'dart:convert';

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
    when(mediaService.lastSpotify).thenReturn(null);

    await _pumpWidgetWithProviders(tester, mediaService, MockAppsService());

    expect(find.text("En cours de lecture"), findsNothing);
  });

  testWidgets("shows permission hint when access is missing", (tester) async {
    final mediaService = MockMediaService();
    when(mediaService.permissionGranted).thenReturn(false);
    when(mediaService.nowPlaying).thenReturn(null);

    await _pumpWidgetWithProviders(tester, mediaService, MockAppsService());

    expect(find.textContaining("L'accès aux notifications est nécessaire"), findsOneWidget);
  });

  testWidgets("shows media session info", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(
      NowPlaying(
        packageName: "com.spotify.tv.android",
        title: "Bittersweet",
        artist: "Lianne La Havas",
        album: "Bittersweet (Radio Edit)",
        duration: Duration(minutes: 3, seconds: 56),
        position: Duration(minutes: 1, seconds: 5),
      ),
    );
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.spotify.tv.android", name: "Spotify")]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("En cours de lecture"), findsOneWidget);
    expect(find.text("Spotify"), findsOneWidget);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(find.text("Lianne La Havas · Bittersweet (Radio Edit)"), findsOneWidget);
    expect(find.text("1:05"), findsOneWidget);
    expect(find.text("3:56"), findsOneWidget);
  });

  testWidgets("the progress bar keeps its size while the position moves", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(appsService.applications).thenReturn([]);
    NowPlaying at(Duration position) => NowPlaying(
      packageName: "com.spotify.tv.android",
      title: "Bittersweet",
      duration: Duration(minutes: 12, seconds: 34),
      position: position,
    );

    when(mediaService.nowPlaying).thenReturn(at(Duration(seconds: 1)));
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    expect(find.text("0:01"), findsOneWidget);
    final width = tester.getSize(find.byType(LinearProgressIndicator)).width;

    when(mediaService.nowPlaying).thenReturn(at(Duration(minutes: 11, seconds: 11)));
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    expect(find.text("11:11"), findsOneWidget);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).width, width);
  });

  testWidgets("does not repeat the title as subtitle", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying)
        .thenReturn(NowPlaying(packageName: "fr.francetv.pluzz", title: "C dans l'air", artist: "C dans l'air"));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("C dans l'air"), findsOneWidget);
  });

  testWidgets("selecting the panel opens the player", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(packageName: "com.spotify.tv.android", playing: true));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.openPlayer());
  });

  testWidgets("offers to resume the last Spotify media while nothing plays", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(null);
    when(mediaService.lastSpotify).thenReturn(
      NowPlaying(
        packageName: "com.spotify.tv.android",
        title: "Bittersweet",
        artist: "Lianne La Havas",
        duration: Duration(minutes: 4),
        position: Duration(minutes: 1),
      ),
    );
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("Reprendre la lecture sur Spotify"), findsOneWidget);
    expect(find.text("En cours de lecture"), findsNothing);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.25);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.resumeSpotify());
    verifyNever(mediaService.openPlayer());
  });

  testWidgets("the media playing comes before the last Spotify media", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying).thenReturn(NowPlaying(packageName: "fr.francetv.pluzz", title: "Dans l'air"));
    when(mediaService.lastSpotify).thenReturn(NowPlaying(packageName: "com.spotify.tv.android", title: "Bittersweet"));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("En cours de lecture"), findsOneWidget);
    expect(find.text("Dans l'air"), findsOneWidget);
    expect(find.text("Reprendre la lecture sur Spotify"), findsNothing);
    expect(find.text("Bittersweet"), findsNothing);
  });

  testWidgets("artwork keeps its aspect ratio", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    final art = base64Decode(_png16x9);
    when(mediaService.permissionGranted).thenReturn(true);
    when(mediaService.nowPlaying)
        .thenReturn(NowPlaying(packageName: "fr.francetv.pluzz", title: "C dans l'air", art: art));
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    // images are decoded asynchronously, outside of the fake test zone
    await tester.runAsync(() => precacheImage(MemoryImage(art), tester.element(find.byType(NowPlayingPanel))));
    await tester.pumpAndSettle();

    final artSize = tester.getSize(find.byType(ClipRRect).first);
    expect(artSize.width / artSize.height, closeTo(16 / 9, 0.05));
  });

  testWidgets("waves swell only while playing, when animations are enabled", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    final art = base64Decode(_png16x9);
    when(mediaService.permissionGranted).thenReturn(true);
    when(appsService.applications).thenReturn([]);

    when(mediaService.nowPlaying)
        .thenReturn(NowPlaying(packageName: "com.spotify.tv.android", art: art, playing: true));
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    expect(tester.hasRunningAnimations, isTrue);

    when(mediaService.nowPlaying).thenReturn(NowPlaying(packageName: "com.spotify.tv.android", art: art));
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    expect(tester.hasRunningAnimations, isFalse);

    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    when(mediaService.nowPlaying)
        .thenReturn(NowPlaying(packageName: "com.spotify.tv.android", art: art, playing: true));
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// 16x9 transparent PNG
const _png16x9 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAJCAYAAAA7KqwyAAAAD0lEQVR4nGNgGAWjgAoAAAJJAAHZX3+dAAAAAElFTkSuQmCC";

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  MediaService mediaService,
  AppsService appsService, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, _) => MaterialApp(
        shortcuts: {...WidgetsApp.defaultShortcuts, SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
        home: Scaffold(body: SingleChildScrollView(child: NowPlayingPanel())),
      ),
    ),
  );
  // the waves never settle while the media plays
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
