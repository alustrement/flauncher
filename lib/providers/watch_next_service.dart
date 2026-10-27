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

import 'dart:collection';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flutter/foundation.dart';

const _maxPrograms = 20;

enum WatchNextType { continueWatching, next, newContent, watchlist }

class WatchNextProgram {
  final int id;
  final String packageName;
  final WatchNextType? type;
  final String? title;
  final String? episodeTitle;
  final String? seasonNumber;
  final String? episodeNumber;
  final String? imageUri;
  final Uint8List? image;
  final Duration? position;
  final Duration? duration;
  final String? intentUri;

  WatchNextProgram({
    required this.id,
    required this.packageName,
    this.type,
    this.title,
    this.episodeTitle,
    this.seasonNumber,
    this.episodeNumber,
    this.imageUri,
    this.image,
    this.position,
    this.duration,
    this.intentUri,
  });

  /// [previousImage] is reused when the image did not change, so that image widgets don't reload it.
  factory WatchNextProgram.fromMap(Map<dynamic, dynamic> map, {Uint8List? previousImage}) {
    final type = map["watchNextType"] as int?;
    final image = map["image"] as Uint8List?;
    return WatchNextProgram(
      id: map["id"],
      packageName: map["packageName"],
      type: type != null && type >= 0 && type < WatchNextType.values.length ? WatchNextType.values[type] : null,
      title: map["title"],
      episodeTitle: map["episodeTitle"],
      seasonNumber: map["seasonNumber"],
      episodeNumber: map["episodeNumber"],
      imageUri: map["imageUri"],
      image: image != null && listEquals(image, previousImage) ? previousImage : image,
      position: map["position"] != null ? Duration(milliseconds: map["position"]) : null,
      duration: map["duration"] != null ? Duration(milliseconds: map["duration"]) : null,
      intentUri: map["intentUri"],
    );
  }

  /// e.g. "S2 E6 · Episode title", skipping the episode number when the title already contains it.
  String? get subtitle {
    final parts = <String>[];
    if (seasonNumber != null && episodeNumber != null) {
      final number = "S$seasonNumber E$episodeNumber";
      if (!(title?.contains(number) ?? false)) {
        parts.add(number);
      }
    } else if (episodeNumber != null) {
      parts.add("E$episodeNumber");
    }
    if (episodeTitle != null) {
      parts.add(episodeTitle!);
    }
    return parts.isNotEmpty ? parts.join(" · ") : null;
  }

  bool sameAs(WatchNextProgram other) =>
      id == other.id &&
      packageName == other.packageName &&
      type == other.type &&
      title == other.title &&
      episodeTitle == other.episodeTitle &&
      seasonNumber == other.seasonNumber &&
      episodeNumber == other.episodeNumber &&
      imageUri == other.imageUri &&
      identical(image, other.image) &&
      position == other.position &&
      duration == other.duration &&
      intentUri == other.intentUri;

  /// Whether [media] is this program: the session of some apps gives the title of the program as subtitle, e.g. the
  /// show as title and the program as subtitle.
  bool isSameMediaAs(NowPlaying media) {
    if (media.packageName != packageName) {
      return false;
    }
    final mediaTitles = [media.title, media.artist].nonNulls.map(_normalize).where((title) => title.isNotEmpty);
    final programTitles = [title, episodeTitle].nonNulls.map(_normalize).toSet();
    return mediaTitles.any(programTitles.contains);
  }

  static String _normalize(String title) =>
      title.replaceAll("’", "'").replaceAll(RegExp(r"\s+"), " ").trim().toLowerCase();

  /// Watched fraction, or null when unknown.
  double? get progress {
    if (position == null || duration == null || duration!.inMilliseconds <= 0) {
      return null;
    }
    return (position!.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }
}

class WatchNextService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;
  bool _permissionGranted = true;
  List<WatchNextProgram> _programs = [];

  bool get permissionGranted => _permissionGranted;

  /// Most recently engaged first.
  List<WatchNextProgram> get programs => UnmodifiableListView(_programs);

  WatchNextService(this._fLauncherChannel) {
    _fLauncherChannel.addWatchNextListener(_onWatchNextEvent);
  }

  /// The programs are sent again each time the launcher comes back: it is only rebuilt when they changed.
  void _onWatchNextEvent(Map<dynamic, dynamic> event) {
    final permissionGranted = event["permissionGranted"] as bool;
    final previousImages = {for (final program in _programs) program.id: program.image};
    final programs = ((event["programs"] as List<dynamic>?) ?? [])
        .take(_maxPrograms)
        .map((program) => program as Map<dynamic, dynamic>)
        .map((program) => WatchNextProgram.fromMap(program, previousImage: previousImages[program["id"]]))
        .toList(growable: false);
    if (permissionGranted == _permissionGranted &&
        programs.length == _programs.length &&
        Iterable.generate(programs.length).every((i) => programs[i].sameAs(_programs[i]))) {
      return;
    }
    _permissionGranted = permissionGranted;
    _programs = programs;
    notifyListeners();
  }

  Future<void> requestPermission() => _fLauncherChannel.requestWatchNextPermission();

  Future<void> open(WatchNextProgram program) =>
      _fLauncherChannel.openWatchNextProgram(program.packageName, program.intentUri);
}
