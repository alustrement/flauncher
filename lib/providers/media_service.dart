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

  /// Whether its app plays in the background: its paused media is then resumed without leaving the launcher.
  final bool background;

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
    this.background = false,
  });

  /// The one of [previousArts] equal to the artwork is reused, so that image widgets don't reload it.
  factory NowPlaying.fromMap(Map<dynamic, dynamic> map, {Iterable<Uint8List?> previousArts = const []}) {
    final art = map["art"] as Uint8List?;
    final previousArt = art != null ? previousArts.where((previous) => listEquals(art, previous)).firstOrNull : null;
    return NowPlaying(
      packageName: map["packageName"],
      title: map["title"],
      artist: map["artist"],
      album: map["album"],
      duration: map["duration"] != null ? Duration(milliseconds: map["duration"]) : null,
      art: previousArt ?? art,
      artUri: map["artUri"],
      playing: map["playing"] ?? false,
      position: map["position"] != null ? Duration(milliseconds: map["position"]) : null,
      positionUpdatedAt: map["positionUpdatedAt"] != null
          ? DateTime.fromMillisecondsSinceEpoch(map["positionUpdatedAt"])
          : null,
      speed: map["speed"] ?? 1.0,
      background: map["background"] ?? false,
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
  List<NowPlaying> _medias = [];
  String? _focusedMedia;

  bool get permissionGranted => _permissionGranted;

  /// The media playing alone, otherwise the last media of an app which doesn't play in the background, a video, next to
  /// the last one of an app which does, to be resumed.
  List<NowPlaying> get medias => _medias;

  bool get playing => _medias.any((media) => media.playing);

  MediaService(this._fLauncherChannel) {
    _fLauncherChannel.addMediaSessionListener(_onMediaSessionEvent);
  }

  void _onMediaSessionEvent(Map<dynamic, dynamic> event) {
    _permissionGranted = event["permissionGranted"];
    final medias = event["medias"] as List<dynamic>? ?? [];
    // a media resumed beside the other one keeps its artwork while it takes the whole width
    final previousArts = [for (final media in _medias) media.art];
    _medias = [
      for (final media in medias) NowPlaying.fromMap(media as Map<dynamic, dynamic>, previousArts: previousArts),
    ];
    notifyListeners();
  }

  /// A paused media of an app which plays in the background is resumed in place, any other media opens its player. Once
  /// its session is gone, a video opens its "Continue watching" program, and any other media its app.
  Future<void> open(NowPlaying media) async {
    if (media.background && !media.playing) {
      await _fLauncherChannel.playMedia(media.packageName);
    } else {
      await _fLauncherChannel.openMediaSession(media.packageName);
    }
  }

  /// Media keys go to the focused media when several are offered. Focus changes come in any order when it moves from
  /// one to the other, hence the media losing it only clears it when it still has it.
  Future<void> setMediaFocused(String packageName, bool focused) async {
    if (focused) {
      _focusedMedia = packageName;
    } else if (_focusedMedia == packageName) {
      _focusedMedia = null;
    } else {
      return;
    }
    await _fLauncherChannel.setFocusedMedia(_focusedMedia);
  }
}
