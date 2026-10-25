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

import 'dart:async';
import 'dart:ui';

import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _panelHeight = 150.0;
const _artSize = 126.0;
const _textShadows = [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 8)];

class NowPlayingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<MediaService>(
        builder: (context, mediaService, _) {
          if (!mediaService.permissionGranted) {
            return _section(context, _PermissionHint());
          }
          final nowPlaying = mediaService.nowPlaying;
          if (nowPlaying == null) {
            return SizedBox.shrink();
          }
          return _section(context, _Panel(nowPlaying: nowPlaying));
        },
      );

  Widget _section(BuildContext context, Widget child) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: EnsureVisible(
          alignment: 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child:
                    Text("Now playing", style: Theme.of(context).textTheme.titleLarge!.copyWith(shadows: _textShadows)),
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: child),
            ],
          ),
        ),
      );
}

class _Panel extends StatelessWidget {
  final NowPlaying nowPlaying;

  _Panel({required this.nowPlaying});

  @override
  Widget build(BuildContext context) {
    final mediaService = context.read<MediaService>();
    final application = context.select<AppsService, App?>((appsService) {
      final matches = appsService.applications.where((app) => app.packageName == nowPlaying.packageName);
      return matches.isNotEmpty ? matches.first : null;
    });
    final artImage = _artImage(nowPlaying);
    final textTheme = Theme.of(context).textTheme;
    final title = nowPlaying.title ?? application?.name ?? nowPlaying.packageName;
    // some apps repeat the title as artist
    final subtitle =
        [nowPlaying.artist, nowPlaying.album].where((text) => (text?.isNotEmpty ?? false) && text != title).join(" · ");

    return SizedBox(
      height: _panelHeight,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        shadowColor: Colors.black,
        color: Theme.of(context).cardColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (artImage != null)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Image(image: artImage, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            Container(color: Colors.black.withOpacity(artImage != null ? 0.45 : 0.2)),
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  _ArtCard(image: artImage, application: application, onPressed: mediaService.openPlayer),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AppLabel(application: application),
                        SizedBox(height: 4),
                        Text(
                          title,
                          style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, shadows: _textShadows),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: textTheme.titleMedium!.copyWith(color: Colors.white70, shadows: _textShadows),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (nowPlaying.duration != null) ...[
                          SizedBox(height: 12),
                          _ProgressBar(nowPlaying: nowPlaying),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  _ControlButton(
                    icon: Icons.skip_previous,
                    onPressed: nowPlaying.canSkipPrevious ? mediaService.skipToPrevious : null,
                  ),
                  SizedBox(width: 12),
                  _ControlButton(
                    icon: nowPlaying.playing ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    onPressed: mediaService.playPause,
                  ),
                  SizedBox(width: 12),
                  _ControlButton(
                    icon: Icons.skip_next,
                    onPressed: nowPlaying.canSkipNext ? mediaService.skipToNext : null,
                  ),
                  SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _artImage(NowPlaying nowPlaying) {
    if (nowPlaying.art != null) {
      return MemoryImage(nowPlaying.art!);
    } else if (nowPlaying.artUri != null) {
      return NetworkImage(nowPlaying.artUri!);
    }
    return null;
  }
}

class _AppLabel extends StatelessWidget {
  final App? application;

  _AppLabel({required this.application});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (application?.icon != null) ...[
            Image.memory(application!.icon!, height: 18, gaplessPlayback: true),
            SizedBox(width: 6),
          ],
          if (application != null)
            Text(
              application!.name,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white70, shadows: _textShadows),
            ),
        ],
      );
}

class _ArtCard extends StatefulWidget {
  final ImageProvider? image;
  final App? application;
  final VoidCallback onPressed;

  _ArtCard({required this.image, required this.application, required this.onPressed});

  @override
  State<_ArtCard> createState() => _ArtCardState();
}

class _ArtCardState extends State<_ArtCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _focused ? 1.08 : 1.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: SizedBox.square(
          dimension: _artSize,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            elevation: _focused ? 16 : 4,
            shadowColor: Colors.black,
            color: Colors.black26,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  focusColor: Colors.transparent,
                  onFocusChange: (focused) => setState(() => _focused = focused),
                  onTap: widget.onPressed,
                  child: widget.image != null ? Ink.image(image: widget.image!, fit: BoxFit.cover) : _placeholder(),
                ),
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: _focused ? Border.all(color: Colors.white, width: 3) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _placeholder() => widget.application?.icon != null
      ? Padding(padding: EdgeInsets.all(24), child: Image.memory(widget.application!.icon!))
      : Icon(Icons.music_note, size: 64, color: Colors.white54);
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  _ControlButton({required this.icon, this.size = 28, required this.onPressed});

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return AnimatedScale(
      scale: _focused ? 1.15 : 1.0,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: _focused ? Colors.white : Colors.white.withOpacity(0.12),
        elevation: _focused ? 8 : 0,
        shadowColor: Colors.black,
        child: InkWell(
          customBorder: CircleBorder(),
          focusColor: Colors.transparent,
          onFocusChange: (focused) => setState(() => _focused = focused),
          onTap: widget.onPressed,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: _focused
                  ? Colors.black87
                  : enabled
                      ? Colors.white
                      : Colors.white30,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final NowPlaying nowPlaying;

  _ProgressBar({required this.nowPlaying});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    _timer?.cancel();
    _timer = widget.nowPlaying.playing ? Timer.periodic(Duration(milliseconds: 500), (_) => setState(() {})) : null;
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.nowPlaying.duration!;
    final position = widget.nowPlaying.currentPosition(DateTime.now()) ?? Duration.zero;
    final textStyle = Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.white70, shadows: _textShadows);
    return Row(
      children: [
        Text(_format(position), style: textStyle),
        SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(_format(duration), style: textStyle),
      ],
    );
  }

  String _format(Duration duration) {
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, "0");
    if (duration.inHours > 0) {
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, "0");
      return "${duration.inHours}:$minutes:$seconds";
    }
    return "${duration.inMinutes}:$seconds";
  }
}

class _PermissionHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.music_off, size: 32, color: Colors.white70),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notification access is required to display what's playing.",
                        style: Theme.of(context).textTheme.titleSmall),
                    SizedBox(height: 4),
                    SelectableText(
                      "adb shell cmd notification allow_listener "
                      "me.efesser.flauncher/me.efesser.flauncher.MediaNotificationListener",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontFamily: "monospace"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
