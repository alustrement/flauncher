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

import 'dart:typed_data';

import 'package:flauncher/providers/media_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  group("MediaService", () {
    test("exposes the current media session", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "session": {
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
        },
      });

      final nowPlaying = mediaService.nowPlaying!;
      expect(mediaService.permissionGranted, isTrue);
      expect(nowPlaying.packageName, "com.spotify.tv.android");
      expect(nowPlaying.title, "Bittersweet");
      expect(nowPlaying.artist, "Lianne La Havas");
      expect(nowPlaying.album, "Bittersweet (Radio Edit)");
      expect(nowPlaying.duration, Duration(milliseconds: 236640));
      expect(nowPlaying.art, [1, 2, 3]);
      expect(nowPlaying.playing, isTrue);
      expect(nowPlaying.position, Duration(seconds: 1));
      expect(nowPlaying.positionUpdatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test("reuses unchanged artwork", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;
      final session = {
        "packageName": "com.spotify.tv.android",
        "art": Uint8List.fromList([1, 2, 3]),
      };

      listener({"permissionGranted": true, "session": session});
      final firstArt = mediaService.nowPlaying!.art;
      listener({
        "permissionGranted": true,
        "session": {
          ...session,
          "art": Uint8List.fromList([1, 2, 3]),
        },
      });

      expect(identical(mediaService.nowPlaying!.art, firstArt), isTrue);
    });

    test("clears the session when nothing is playing", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "session": {"packageName": "com.spotify.tv.android"},
      });
      listener({"permissionGranted": true, "session": null});

      expect(mediaService.nowPlaying, isNull);
    });

    test("exposes the last Spotify media while nothing plays", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "session": null,
        "lastSpotify": {
          "packageName": "com.spotify.tv.android",
          "title": "Bittersweet",
          "artist": "Lianne La Havas",
          "duration": 236640,
          "playing": false,
          "position": 120000,
        },
      });

      final lastSpotify = mediaService.lastSpotify!;
      expect(mediaService.nowPlaying, isNull);
      expect(lastSpotify.title, "Bittersweet");
      expect(lastSpotify.artist, "Lianne La Havas");
      expect(lastSpotify.playing, isFalse);
      expect(lastSpotify.currentPosition(DateTime.now()), Duration(minutes: 2));

      listener({
        "permissionGranted": true,
        "session": {"packageName": "fr.francetv.pluzz"},
      });

      expect(mediaService.lastSpotify, isNull);
    });

    test("keeps the artwork of the last Spotify media when it is resumed", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;
      final media = {"packageName": "com.spotify.tv.android", "title": "Bittersweet"};

      listener({
        "permissionGranted": true,
        "session": null,
        "lastSpotify": {
          ...media,
          "art": Uint8List.fromList([1, 2, 3]),
        },
      });
      final art = mediaService.lastSpotify!.art;
      listener({
        "permissionGranted": true,
        "session": {
          ...media,
          "art": Uint8List.fromList([1, 2, 3]),
          "playing": true,
        },
      });

      expect(mediaService.lastSpotify, isNull);
      expect(identical(mediaService.nowPlaying!.art, art), isTrue);
    });

    test("resumeSpotify calls channel", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);

      await mediaService.resumeSpotify();

      verify(channel.resumeSpotify());
    });

    test("reports missing permission", () {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;

      listener({"permissionGranted": false});

      expect(mediaService.permissionGranted, isFalse);
      expect(mediaService.nowPlaying, isNull);
    });

    test("openPlayer calls channel", () async {
      final channel = MockFLauncherChannel();
      final mediaService = MediaService(channel);
      final listener = verify(channel.addMediaSessionListener(captureAny)).captured.single;
      listener({
        "permissionGranted": true,
        "session": {"packageName": "com.spotify.tv.android"},
      });

      await mediaService.openPlayer();

      verify(channel.openMediaSession("com.spotify.tv.android"));
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
