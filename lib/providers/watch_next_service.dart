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

import 'dart:collection';

import 'package:flauncher/flauncher_channel.dart';
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

  factory WatchNextProgram.fromMap(Map<dynamic, dynamic> map) {
    final type = map["watchNextType"] as int?;
    return WatchNextProgram(
      id: map["id"],
      packageName: map["packageName"],
      type: type != null && type >= 0 && type < WatchNextType.values.length ? WatchNextType.values[type] : null,
      title: map["title"],
      episodeTitle: map["episodeTitle"],
      seasonNumber: map["seasonNumber"],
      episodeNumber: map["episodeNumber"],
      imageUri: map["imageUri"],
      image: map["image"],
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

  void _onWatchNextEvent(Map<dynamic, dynamic> event) {
    _permissionGranted = event["permissionGranted"];
    final programs = (event["programs"] as List<dynamic>?) ?? [];
    _programs = programs
        .take(_maxPrograms)
        .map((program) => WatchNextProgram.fromMap(program as Map<dynamic, dynamic>))
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> requestPermission() => _fLauncherChannel.requestWatchNextPermission();

  Future<void> open(WatchNextProgram program) =>
      _fLauncherChannel.openWatchNextProgram(program.packageName, program.intentUri);
}
