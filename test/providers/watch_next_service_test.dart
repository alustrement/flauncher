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
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

Map<String, dynamic> _programMap(int id, {String packageName = "fr.francetv.pluzz"}) => {
  "id": id,
  "packageName": packageName,
  "watchNextType": 0,
  "title": "Program $id",
};

void main() {
  group("WatchNextService", () {
    test("exposes programs", () {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);
      final listener = verify(channel.addWatchNextListener(captureAny)).captured.single;

      listener({
        "permissionGranted": true,
        "programs": [
          {
            "id": 833581,
            "packageName": "fr.francetv.pluzz",
            "watchNextType": 1,
            "title": "Les mystérieuses cités d'or",
            "episodeTitle": "A l'abordage !",
            "seasonNumber": "2",
            "episodeNumber": "6",
            "imageUri": "https://medias.france.tv/image.png",
            "position": 74000,
            "duration": 1380000,
            "intentUri": "https://www.france.tv/watchNext/833581",
          },
        ],
      });

      final program = watchNextService.programs.single;
      expect(watchNextService.permissionGranted, isTrue);
      expect(program.id, 833581);
      expect(program.packageName, "fr.francetv.pluzz");
      expect(program.type, WatchNextType.next);
      expect(program.title, "Les mystérieuses cités d'or");
      expect(program.episodeTitle, "A l'abordage !");
      expect(program.seasonNumber, "2");
      expect(program.episodeNumber, "6");
      expect(program.imageUri, "https://medias.france.tv/image.png");
      expect(program.position, Duration(seconds: 74));
      expect(program.duration, Duration(minutes: 23));
      expect(program.intentUri, "https://www.france.tv/watchNext/833581");
    });

    test("keeps the 20 most recent programs", () {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);
      final listener = verify(channel.addWatchNextListener(captureAny)).captured.single;

      listener({"permissionGranted": true, "programs": List.generate(30, _programMap)});

      expect(watchNextService.programs.map((program) => program.id), List.generate(20, (index) => index));
    });

    test("only notifies when the programs changed, and keeps their images", () {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);
      final listener = verify(channel.addWatchNextListener(captureAny)).captured.single;
      var notifications = 0;
      watchNextService.addListener(() => ++notifications);
      Map<String, dynamic> event(int position) => {
        "permissionGranted": true,
        "programs": [
          {
            ..._programMap(1),
            "image": Uint8List.fromList([1, 2, 3]),
            "position": position,
          },
        ],
      };

      listener(event(1000));
      final image = watchNextService.programs.single.image;
      listener(event(1000));
      expect(notifications, 1);

      listener(event(2000));
      expect(notifications, 2);
      expect(watchNextService.programs.single.position, Duration(seconds: 2));
      expect(watchNextService.programs.single.image, same(image));
    });

    test("reports missing permission", () {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);
      final listener = verify(channel.addWatchNextListener(captureAny)).captured.single;

      listener({"permissionGranted": false});

      expect(watchNextService.permissionGranted, isFalse);
      expect(watchNextService.programs, isEmpty);
    });

    test("requestPermission calls channel", () async {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);

      await watchNextService.requestPermission();

      verify(channel.requestWatchNextPermission());
    });

    test("open calls channel", () async {
      final channel = MockFLauncherChannel();
      final watchNextService = WatchNextService(channel);

      await watchNextService.open(
        WatchNextProgram(id: 1, packageName: "tv.arte.plus7", intentUri: "arte://program/127458-000-A"),
      );

      verify(channel.openWatchNextProgram("tv.arte.plus7", "arte://program/127458-000-A"));
    });
  });

  group("WatchNextProgram", () {
    test("subtitle with season, episode number and title", () {
      final program = WatchNextProgram(
        id: 1,
        packageName: "app",
        title: "Malcolm",
        seasonNumber: "1",
        episodeNumber: "4",
        episodeTitle: "Caméra cachée",
      );

      expect(program.subtitle, "S1 E4 · Caméra cachée");
    });

    test("subtitle skips episode number already in title", () {
      final program = WatchNextProgram(
        id: 1,
        packageName: "app",
        title: "Les mystérieuses cités d'or - S2 E6",
        seasonNumber: "2",
        episodeNumber: "6",
      );

      expect(program.subtitle, isNull);
    });

    test("progress", () {
      expect(
        WatchNextProgram(
          id: 1,
          packageName: "app",
          position: Duration(minutes: 5),
          duration: Duration(minutes: 20),
        ).progress,
        0.25,
      );
      expect(WatchNextProgram(id: 1, packageName: "app", position: Duration(minutes: 5)).progress, isNull);
    });

    test("isSameMediaAs matches the media of the same app with one of the program's titles", () {
      final program = WatchNextProgram(
        id: 1,
        packageName: "fr.francetv.pluzz",
        title: "\"Quelques mots d'amour\" avec Hafsia Herzi",
      );

      expect(
        program.isSameMediaAs(
          NowPlaying(
            packageName: "fr.francetv.pluzz",
            title: "Abdoul fait son cinéma",
            artist: "\"Quelques mots d’amour\"  avec hafsia Herzi",
          ),
        ),
        isTrue,
      );
      expect(
        program.isSameMediaAs(
          NowPlaying(packageName: "fr.francetv.pluzz", title: "Abdoul fait son cinéma", artist: "Un autre invité"),
        ),
        isFalse,
      );
      expect(
        program.isSameMediaAs(
          NowPlaying(packageName: "tv.arte.plus7", title: "\"Quelques mots d'amour\" avec Hafsia Herzi"),
        ),
        isFalse,
      );
      expect(program.isSameMediaAs(NowPlaying(packageName: "fr.francetv.pluzz")), isFalse);
      expect(
        WatchNextProgram(
          id: 2,
          packageName: "com.disney.disneyplus",
          title: "Malcolm",
          episodeTitle: "Caméra cachée",
        ).isSameMediaAs(NowPlaying(packageName: "com.disney.disneyplus", title: "Caméra cachée")),
        isTrue,
      );
    });
  });
}
