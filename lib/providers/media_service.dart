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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';

class NowPlaying {
  final String packageName;
  final String? title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final Uint8List? art;
  final String? artUri;
  final bool playing;
  final Duration? position;
  final DateTime? positionUpdatedAt;
  final double speed;
  final bool canSkipNext;
  final bool canSkipPrevious;

  NowPlaying({
    required this.packageName,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.art,
    this.artUri,
    this.playing = false,
    this.position,
    this.positionUpdatedAt,
    this.speed = 1.0,
    this.canSkipNext = false,
    this.canSkipPrevious = false,
  });

  /// [previousArt] is reused when the artwork did not change, so that image widgets don't reload it.
  factory NowPlaying.fromMap(Map<dynamic, dynamic> map, {Uint8List? previousArt}) {
    final art = map["art"] as Uint8List?;
    return NowPlaying(
      packageName: map["packageName"],
      title: map["title"],
      artist: map["artist"],
      album: map["album"],
      duration: map["duration"] != null ? Duration(milliseconds: map["duration"]) : null,
      art: art != null && listEquals(art, previousArt) ? previousArt : art,
      artUri: map["artUri"],
      playing: map["playing"] ?? false,
      position: map["position"] != null ? Duration(milliseconds: map["position"]) : null,
      positionUpdatedAt:
          map["positionUpdatedAt"] != null ? DateTime.fromMillisecondsSinceEpoch(map["positionUpdatedAt"]) : null,
      speed: map["speed"] ?? 1.0,
      canSkipNext: map["canSkipNext"] ?? false,
      canSkipPrevious: map["canSkipPrevious"] ?? false,
    );
  }

  /// Extrapolates the playback position from the last reported one.
  Duration? currentPosition(DateTime now) {
    if (position == null) {
      return null;
    }
    var current = position!;
    if (playing && positionUpdatedAt != null) {
      current += now.difference(positionUpdatedAt!) * speed;
    }
    if (duration != null && current > duration!) {
      return duration;
    }
    return current;
  }
}

class MediaService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;
  bool _permissionGranted = true;
  NowPlaying? _nowPlaying;

  bool get permissionGranted => _permissionGranted;

  NowPlaying? get nowPlaying => _nowPlaying;

  MediaService(this._fLauncherChannel) {
    _fLauncherChannel.addMediaSessionListener(_onMediaSessionEvent);
  }

  void _onMediaSessionEvent(Map<dynamic, dynamic> event) {
    _permissionGranted = event["permissionGranted"];
    final session = event["session"] as Map<dynamic, dynamic>?;
    _nowPlaying = session != null ? NowPlaying.fromMap(session, previousArt: _nowPlaying?.art) : null;
    notifyListeners();
  }

  Future<void> playPause() => _fLauncherChannel.mediaPlayPause();

  Future<void> skipToNext() => _fLauncherChannel.mediaSkipToNext();

  Future<void> skipToPrevious() => _fLauncherChannel.mediaSkipToPrevious();

  Future<void> openPlayer() async {
    if (_nowPlaying != null) {
      await _fLauncherChannel.openMediaSession(_nowPlaying!.packageName);
    }
  }
}
