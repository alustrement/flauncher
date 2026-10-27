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

import 'dart:typed_data';

import 'package:flauncher/providers/media_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  group("MediaService", () {
    test("exposes the media to show", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "medias": [
          {
            "packageName": "com.spotify.tv.android",
            "title": "Bittersweet",
            "artist": "Lianne La Havas",
            "album": "Bittersweet (Radio Edit)",
            "duration": 236640,
            "art": Uint8List.fromList([1, 2, 3]),
            "playing": true,
            "position": 1000,
            "positionUpdatedAt": 1700000000000,
            "speed": 1.0,
            "background": true,
          },
        ],
      });

      final nowPlaying = mediaService.medias.single;
      expect(mediaService.permissionGranted, isTrue);
      expect(mediaService.playing, isTrue);
      expect(nowPlaying.packageName, "com.spotify.tv.android");
      expect(nowPlaying.title, "Bittersweet");
      expect(nowPlaying.artist, "Lianne La Havas");
      expect(nowPlaying.album, "Bittersweet (Radio Edit)");
      expect(nowPlaying.duration, Duration(milliseconds: 236640));
      expect(nowPlaying.art, [1, 2, 3]);
      expect(nowPlaying.playing, isTrue);
      expect(nowPlaying.position, Duration(seconds: 1));
      expect(nowPlaying.positionUpdatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(nowPlaying.background, isTrue);
    });

    test("exposes the last video next to the last media of an app which plays in the background", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "medias": [
          {"packageName": "app.smarttube.fdroid", "title": "Une vidéo"},
          {"packageName": "com.spotify.tv.android", "title": "Bittersweet", "background": true},
        ],
      });

      expect(mediaService.medias.map((media) => media.title), ["Une vidéo", "Bittersweet"]);
      expect(mediaService.medias.map((media) => media.background), [false, true]);
      expect(mediaService.playing, isFalse);

      listener({"permissionGranted": true, "medias": []});

      expect(mediaService.medias, isEmpty);
    });

    test("reuses unchanged artwork, also when the media moves beside the other one", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;
      Map<String, dynamic> song({bool playing = false}) => {
        "packageName": "com.spotify.tv.android",
        "art": Uint8List.fromList([1, 2, 3]),
        "playing": playing,
      };

      listener({
        "permissionGranted": true,
        "medias": [
          {"packageName": "app.smarttube.fdroid"},
          song(),
        ],
      });
      final art = mediaService.medias.last.art;
      listener({
        "permissionGranted": true,
        "medias": [song(playing: true)],
      });

      expect(identical(mediaService.medias.single.art, art), isTrue);
    });

    test("resumes a paused media of an app which plays in the background in place", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);

      await mediaService.open(NowPlaying(packageName: "com.spotify.tv.android", background: true));

      verify(channel.playMedia("com.spotify.tv.android"));
      verifyNever(channel.openMediaSession(any));
    });

    test("opens the player of a video, or of a media playing", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);

      await mediaService.open(NowPlaying(packageName: "app.smarttube.fdroid"));
      await mediaService.open(NowPlaying(packageName: "com.spotify.tv.android", background: true, playing: true));

      verify(channel.openMediaSession("app.smarttube.fdroid"));
      verify(channel.openMediaSession("com.spotify.tv.android"));
      verifyNever(channel.playMedia(any));
    });

    test("opens the player of a media playing on another device, which doesn't count as playing", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "medias": [
          {"packageName": "app.smarttube.fdroid", "title": "Une vidéo"},
          {"packageName": "com.spotify.tv.android", "background": true, "playing": true, "remote": true},
        ],
      });
      await mediaService.open(mediaService.medias.last);
      await mediaService.open(NowPlaying(packageName: "com.spotify.tv.android", background: true, remote: true));

      expect(mediaService.medias.last.remote, isTrue);
      expect(mediaService.playing, isFalse);
      verify(channel.openMediaSession("com.spotify.tv.android")).called(2);
      verifyNever(channel.playMedia(any));
    });

    test("tells the channel which media is focused, whatever the order of the focus changes", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);

      await mediaService.setMediaFocused("app.smarttube.fdroid", true);
      await mediaService.setMediaFocused("com.spotify.tv.android", true);
      await mediaService.setMediaFocused("app.smarttube.fdroid", false);
      await mediaService.setMediaFocused("com.spotify.tv.android", false);

      verifyInOrder([
        channel.setFocusedMedia("app.smarttube.fdroid"),
        channel.setFocusedMedia("com.spotify.tv.android"),
        channel.setFocusedMedia(null),
      ]);
      verifyNever(channel.setFocusedMedia(any));
    });

    test("reports missing permission", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({"permissionGranted": false});

      expect(mediaService.permissionGranted, isFalse);
      expect(mediaService.medias, isEmpty);
    });
  });

  group("NowPlaying.currentPosition", () {
    final updatedAt = DateTime(2026, 1, 1, 12);

    test("extrapolates while playing", () {
      final nowPlaying = NowPlaying(
        packageName: "app",
        playing: true,
        position: Duration(seconds: 10),
        positionUpdatedAt: updatedAt,
        duration: Duration(minutes: 3),
      );

      expect(nowPlaying.currentPosition(updatedAt.add(Duration(seconds: 5))), Duration(seconds: 15));
    });

    test("does not move while paused", () {
      final nowPlaying = NowPlaying(
        packageName: "app",
        playing: false,
        position: Duration(seconds: 10),
        positionUpdatedAt: updatedAt,
      );

      expect(nowPlaying.currentPosition(updatedAt.add(Duration(seconds: 5))), Duration(seconds: 10));
    });

    test("is capped to the duration", () {
      final nowPlaying = NowPlaying(
        packageName: "app",
        playing: true,
        position: Duration(seconds: 170),
        positionUpdatedAt: updatedAt,
        duration: Duration(minutes: 3),
      );

      expect(nowPlaying.currentPosition(updatedAt.add(Duration(seconds: 30))), Duration(minutes: 3));
    });
  });
}
