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

const spotifyPackage = "com.spotify.tv.android";

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
    );
  }

  /// A paused media of another app than Spotify, a video which doesn't play in the background, is offered to be
  /// resumed next to Spotify's.
  bool get resumable => !playing && packageName != spotifyPackage;

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
  NowPlaying? _spotify;
  String? _focusedMedia;

  bool get permissionGranted => _permissionGranted;

  NowPlaying? get nowPlaying => _nowPlaying;

  /// Spotify's paused media, next to a [NowPlaying.resumable] media, to be resumed.
  NowPlaying? get spotify => _spotify;

  MediaService(this._fLauncherChannel) {
    _fLauncherChannel.addMediaSessionListener(_onMediaSessionEvent);
  }

  void _onMediaSessionEvent(Map<dynamic, dynamic> event) {
    _permissionGranted = event["permissionGranted"];
    final session = event["session"] as Map<dynamic, dynamic>?;
    final spotify = event["spotify"] as Map<dynamic, dynamic>?;
    // resuming Spotify's media brings it from beside the video to the media playing
    final previousArts = [_nowPlaying?.art, _spotify?.art];
    _nowPlaying = session != null ? NowPlaying.fromMap(session, previousArts: previousArts) : null;
    _spotify = spotify != null ? NowPlaying.fromMap(spotify, previousArts: previousArts) : null;
    notifyListeners();
  }

  Future<void> openPlayer() async {
    if (_nowPlaying != null) {
      await _fLauncherChannel.openMediaSession(_nowPlaying!.packageName);
    }
  }

  Future<void> resumeSpotify() => _fLauncherChannel.resumeSpotify();

  /// Media keys go to the focused media when Spotify's is shown next to a video. Focus changes come in any order when
  /// it moves from one to the other, hence the media losing it only clears it when it still has it.
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
