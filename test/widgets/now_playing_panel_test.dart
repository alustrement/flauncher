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

import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
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

final _video = NowPlaying(packageName: "app.smarttube.fdroid", title: "Une vidéo");
final _song = NowPlaying(packageName: "com.spotify.tv.android", title: "Bittersweet", background: true);
final _songPlaying = NowPlaying(
  packageName: "com.spotify.tv.android",
  title: "Bittersweet",
  background: true,
  playing: true,
);

void main() {
  testWidgets("shows nothing without media", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, []);
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.spotify.tv.android", name: "Spotify")]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("En cours de lecture"), findsNothing);
    expect(find.text("Reprendre la lecture"), findsNothing);
  });

  testWidgets("shows permission hint when access is missing", (tester) async {
    final mediaService = MockMediaService();
    when(mediaService.permissionGranted).thenReturn(false);

    await _pumpWidgetWithProviders(tester, mediaService, MockAppsService());

    expect(find.textContaining("L'accès aux notifications est nécessaire"), findsOneWidget);
  });

  testWidgets("shows media session info", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [
      NowPlaying(
        packageName: "com.spotify.tv.android",
        title: "Bittersweet",
        artist: "Lianne La Havas",
        album: "Bittersweet (Radio Edit)",
        duration: Duration(minutes: 3, seconds: 56),
        position: Duration(minutes: 1, seconds: 5),
        background: true,
      ),
    ]);
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.spotify.tv.android", name: "Spotify")]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("Reprendre la lecture"), findsOneWidget);
    expect(find.text("Spotify"), findsOneWidget);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(find.text("Lianne La Havas · Bittersweet (Radio Edit)"), findsOneWidget);
    expect(find.text("1:05"), findsOneWidget);
    expect(find.text("3:56"), findsOneWidget);
  });

  testWidgets("the progress bar keeps its size while the position moves", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn([]);
    NowPlaying at(Duration position) => NowPlaying(
      packageName: "com.spotify.tv.android",
      title: "Bittersweet",
      duration: Duration(minutes: 12, seconds: 34),
      position: position,
    );

    _stubMedias(mediaService, [at(Duration(seconds: 1))]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    expect(find.text("0:01"), findsOneWidget);
    final width = tester.getSize(find.byType(LinearProgressIndicator)).width;

    _stubMedias(mediaService, [at(Duration(minutes: 11, seconds: 11))]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    expect(find.text("11:11"), findsOneWidget);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).width, width);
  });

  testWidgets("does not repeat the title as subtitle", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [
      NowPlaying(packageName: "fr.francetv.pluzz", title: "C dans l'air", artist: "C dans l'air"),
    ]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("C dans l'air"), findsOneWidget);
  });

  testWidgets("selecting the panel opens its media", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_songPlaying]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.open(_songPlaying));
  });

  testWidgets("offers to resume the last video next to the last media of an app which plays in the background", (
    tester,
  ) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    final song = NowPlaying(
      packageName: "com.spotify.tv.android",
      title: "Bittersweet",
      artist: "Lianne La Havas",
      duration: Duration(minutes: 4),
      position: Duration(minutes: 1),
      background: true,
    );
    _stubMedias(mediaService, [_video, song]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("Reprendre la lecture"), findsOneWidget);
    expect(find.text("En cours de lecture"), findsNothing);
    expect(find.text("Une vidéo"), findsOneWidget);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(tester.getCenter(find.text("Une vidéo")).dx, lessThan(tester.getCenter(find.text("Bittersweet")).dx));
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.25);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    verify(mediaService.open(_video));

    verify(mediaService.setMediaFocused("app.smarttube.fdroid", true));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    verify(mediaService.open(song));
    verify(mediaService.setMediaFocused("app.smarttube.fdroid", false));
    verify(mediaService.setMediaFocused("com.spotify.tv.android", true));
  });

  testWidgets("a panel keeps the focus once its media is resumed", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_video, _song]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    _stubMedias(mediaService, [_songPlaying]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    expect(find.text("En cours de lecture"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.open(_songPlaying));
    verifyNever(mediaService.setMediaFocused("com.spotify.tv.android", false));
  });

  testWidgets("a panel which goes hands the focus over to the one which stays", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_video, _song]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    verify(mediaService.setMediaFocused("app.smarttube.fdroid", true));

    _stubMedias(mediaService, [_song]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    verify(mediaService.setMediaFocused("com.spotify.tv.android", true));
    verify(mediaService.open(_song));
  });

  testWidgets("a media alone is shown full width, playing or offered to be resumed", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_song]);
    when(appsService.applications).thenReturn([fakeApp(packageName: "com.spotify.tv.android", name: "Spotify")]);

    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(find.text("Reprendre la lecture"), findsOneWidget);
    expect(find.text("En cours de lecture"), findsNothing);
    expect(find.text("Bittersweet"), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    final width = tester.getSize(find.byKey(ValueKey("com.spotify.tv.android"))).width;
    expect(width, greaterThan(tester.getSize(find.byType(NowPlayingPanel)).width / 2));

    _stubMedias(mediaService, [_songPlaying]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    await tester.pump(Duration(seconds: 1));

    expect(find.text("En cours de lecture"), findsOneWidget);
    expect(find.text("Reprendre la lecture"), findsNothing);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets("a panel grows to the whole width while the other one goes", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_video, _song]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);
    final halfWidth = tester.getSize(find.byKey(ValueKey("com.spotify.tv.android"))).width;

    _stubMedias(mediaService, [_song]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    await tester.pump(Duration(milliseconds: 200));

    final width = tester.getSize(find.byKey(ValueKey("com.spotify.tv.android"))).width;
    expect(width, greaterThan(halfWidth));
    expect(find.text("Une vidéo"), findsOneWidget);
    expect(tester.getSize(find.byKey(ValueKey("app.smarttube.fdroid"))).width, lessThan(halfWidth));

    await tester.pumpAndSettle();
    expect(find.text("Une vidéo"), findsNothing);
    expect(tester.getSize(find.byKey(ValueKey("com.spotify.tv.android"))).width, greaterThan(halfWidth * 2));
  });

  testWidgets("a panel which goes is removed once, whatever the updates while it shrinks", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    _stubMedias(mediaService, [_video, _song]);
    when(appsService.applications).thenReturn([]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    _stubMedias(mediaService, [_song]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    await tester.pump(Duration(milliseconds: 100));
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    await tester.pump(Duration(milliseconds: 100));
    await _pumpWidgetWithProviders(tester, mediaService, appsService);

    expect(tester.takeException(), isNull);
    expect(find.text("Une vidéo"), findsNothing);
  });

  testWidgets("artwork keeps its aspect ratio", (tester) async {
    final mediaService = MockMediaService();
    final appsService = MockAppsService();
    final art = base64Decode(_png16x9);
    _stubMedias(mediaService, [NowPlaying(packageName: "fr.francetv.pluzz", title: "C dans l'air", art: art)]);
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
    when(appsService.applications).thenReturn([]);

    _stubMedias(mediaService, [NowPlaying(packageName: "com.spotify.tv.android", art: art, playing: true)]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    expect(tester.hasRunningAnimations, isTrue);

    _stubMedias(mediaService, [NowPlaying(packageName: "com.spotify.tv.android", art: art)]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    // the title fades to "Reprendre la lecture" meanwhile
    await tester.pump(Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);

    tester.binding.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    _stubMedias(mediaService, [NowPlaying(packageName: "com.spotify.tv.android", art: art, playing: true)]);
    await _pumpWidgetWithProviders(tester, mediaService, appsService, settle: false);
    // the title fading out began before animations were disabled
    await tester.pump(Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// 16x9 transparent PNG
const _png16x9 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAJCAYAAAA7KqwyAAAAD0lEQVR4nGNgGAWjgAoAAAJJAAHZX3+dAAAAAElFTkSuQmCC";

void _stubMedias(MockMediaService mediaService, List<NowPlaying> medias) {
  when(mediaService.permissionGranted).thenReturn(true);
  when(mediaService.medias).thenReturn(medias);
  when(mediaService.playing).thenReturn(medias.any((media) => media.playing));
}

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
        locale: Locale("fr"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
