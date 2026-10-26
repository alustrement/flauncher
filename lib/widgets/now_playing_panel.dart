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
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flauncher/database.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/widgets/initial_focus.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
import 'package:flauncher/widgets/zen_waves_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _panelHeight = 150.0;
const _artSize = 126.0;
const _radius = 16.0;
const _columnSpacing = 24.0;

/// Duration of the panels' moves, e.g. when a panel takes the whole width once its media is resumed.
const _transitionDuration = Duration(milliseconds: 400);
const _transitionCurve = Curves.easeInOutCubic;
const _textShadows = [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 8)];

/// The media playing, full width. Otherwise, the last media of an app which doesn't play in the background, a video, is
/// offered to be resumed next to the last one of an app which does.
class NowPlayingPanel extends StatefulWidget {
  @override
  State<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends State<NowPlayingPanel> {
  /// A panel keeps its focus when it moves from beside the other one to full width, once its media is resumed.
  final _panelKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) => Consumer<MediaService>(
    builder: (context, mediaService, _) {
      if (!mediaService.permissionGranted) {
        return _section(context, "En cours de lecture", SkipInitialFocus(child: _PermissionHint()));
      }
      if (mediaService.medias.isEmpty) {
        return SizedBox.shrink();
      }
      return _section(
        context,
        mediaService.playing ? "En cours de lecture" : "Reprendre la lecture",
        _AnimatedPanels(slots: [for (final media in mediaService.medias) _panel(mediaService, media)]),
      );
    },
  );

  _Slot _panel(MediaService mediaService, NowPlaying media) => _Slot(
    key: ValueKey(media.packageName),
    child: _Panel(
      key: _panelKeys.putIfAbsent(media.packageName, () => GlobalKey()),
      nowPlaying: media,
      onPressed: () => mediaService.open(media),
      onFocusChange: (focused) => mediaService.setMediaFocused(media.packageName, focused),
    ),
  );

  Widget _section(BuildContext context, String title, Widget child) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 32, bottom: 8),
          child: AnimatedSwitcher(
            duration: MediaQuery.of(context).disableAnimations ? Duration.zero : _transitionDuration,
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
            child: Text(
              title,
              key: ValueKey(title),
              style: Theme.of(context).textTheme.titleLarge!
                  .copyWith(color: ZenPalette.lavender, shadows: _textShadows),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: RevealOnFocus(child: child),
        ),
      ],
    ),
  );
}

/// A panel of [_AnimatedPanels], which shares the width with the other panels.
class _Slot {
  final Key key;
  final Widget child;

  _Slot({required this.key, required this.child});
}

/// Panels side by side, which grow from nothing when they come and shrink to nothing when they go, while the other
/// panels take the room left: a panel grows to the whole width once its media is resumed, while the other one goes.
class _AnimatedPanels extends StatefulWidget {
  final List<_Slot> slots;

  _AnimatedPanels({required this.slots});

  @override
  State<_AnimatedPanels> createState() => _AnimatedPanelsState();
}

class _AnimatedPanelsState extends State<_AnimatedPanels> with TickerProviderStateMixin {
  late List<_SlotEntry> _entries = [
    for (final slot in widget.slots) _SlotEntry(slot, AnimationController(vsync: this, value: 1)),
  ];

  @override
  void didUpdateWidget(covariant _AnimatedPanels oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : _transitionDuration;
    final previous = {for (final entry in _entries) entry.slot.key: entry};
    final entries = <_SlotEntry>[];
    for (final slot in widget.slots) {
      final entry = previous.remove(slot.key) ?? _SlotEntry(slot, AnimationController(vsync: this));
      entry.slot = slot;
      entry.leaving = false;
      entry.controller.animateTo(1, duration: duration, curve: _transitionCurve);
      entries.add(entry);
    }
    final staying = List.of(entries);
    // the panels which go stay where they were while they shrink, and are removed once, whatever the updates meanwhile
    for (final entry in previous.values) {
      if (!entry.leaving) {
        // a panel which goes hands the focus over to one which stays, rather than to the next row
        if (entry.focusNode.hasFocus && staying.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              staying.first.focusNode.traversalDescendants.firstOrNull?.requestFocus();
            }
          });
        }
        entry.leaving = true;
        entry.controller.animateBack(0, duration: duration, curve: _transitionCurve).whenCompleteOrCancel(() {
          if (mounted && entry.leaving) {
            setState(() => _entries.remove(entry));
            entry.dispose();
          }
        });
      }
      entries.insert(min(_entries.indexOf(entry), entries.length), entry);
    }
    _entries = entries;
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _panelHeight,
    child: AnimatedBuilder(
      animation: Listenable.merge([for (final entry in _entries) entry.controller]),
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) => _layout(constraints.maxWidth)),
    ),
  );

  Widget _layout(double width) {
    final presences = [for (final entry in _entries) entry.controller.value];
    final gaps = [
      for (var i = 0; i < _entries.length; ++i) i == 0 ? 0.0 : _columnSpacing * min(presences[i - 1], presences[i]),
    ];
    final shared = max(width - gaps.fold(0.0, (sum, gap) => sum + gap), 0.0);
    final sharedPresence = presences.fold(0.0, (sum, presence) => sum + presence);
    return Row(
      children: [
        for (var i = 0; i < _entries.length; ++i) ...[
          SizedBox(width: gaps[i]),
          _slot(_entries[i], presences[i], sharedPresence > 0 ? shared / sharedPresence : 0.0),
        ],
      ],
    );
  }

  /// The panel keeps its full width while it shrinks or grows, cut on its right, and fades meanwhile.
  Widget _slot(_SlotEntry entry, double presence, double fullWidth) {
    if (presence == 1 && !entry.leaving) {
      entry.fullWidth = fullWidth;
    }
    final contentWidth = entry.leaving ? entry.fullWidth ?? fullWidth : fullWidth;
    return SizedBox(
      key: entry.slot.key,
      width: fullWidth * presence,
      child: ClipRect(
        // the focused panel's glow goes beyond its slot
        clipBehavior: presence < 1 ? Clip.hardEdge : Clip.none,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: contentWidth,
          maxWidth: contentWidth,
          child: Focus(
            focusNode: entry.focusNode,
            canRequestFocus: false,
            skipTraversal: true,
            child: ExcludeFocus(
              excluding: entry.leaving,
              child: Opacity(opacity: presence, child: entry.slot.child),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotEntry {
  _Slot slot;
  final AnimationController controller;

  /// Has the focus while the panel has it.
  final focusNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  bool leaving = false;

  /// The width of the panel when it is fully there, which it keeps while it goes.
  double? fullWidth;

  _SlotEntry(this.slot, this.controller);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _Panel extends StatefulWidget {
  final NowPlaying nowPlaying;
  final VoidCallback onPressed;
  final ValueChanged<bool> onFocusChange;

  _Panel({super.key, required this.nowPlaying, required this.onPressed, required this.onFocusChange});

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  bool _focused = false;

  @override
  void dispose() {
    if (_focused) {
      widget.onFocusChange(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = widget.nowPlaying;
    final application = context.select<AppsService, App?>((appsService) {
      final matches = appsService.applications.where((app) => app.packageName == nowPlaying.packageName);
      return matches.isNotEmpty ? matches.first : null;
    });
    final artImage = _artImage(nowPlaying);
    final textTheme = Theme.of(context).textTheme;
    final title = nowPlaying.title ?? application?.name ?? nowPlaying.packageName;
    // some apps repeat the title as artist
    final subtitle = [
      nowPlaying.artist,
      nowPlaying.album,
    ].where((text) => (text?.isNotEmpty ?? false) && text != title).join(" · ");

    return AnimatedScale(
      scale: _focused ? 1.02 : 1.0,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: _panelHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: _focused ? ZenPalette.focusGlow : [],
        ),
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: BorderSide(color: ZenPalette.lavender.withValues(alpha: 0.18)),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: _focused ? 16 : 8,
          shadowColor: Colors.black,
          color: ZenPalette.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: RepaintBoundary(
                  child: _ArtworkWaves(image: artImage, playing: nowPlaying.playing),
                ),
              ),
              InkWell(
                focusColor: Colors.transparent,
                onFocusChange: (focused) {
                  setState(() => _focused = focused);
                  widget.onFocusChange(focused);
                },
                onTap: widget.onPressed,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _Art(image: artImage, application: application),
                      SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AppLabel(application: application, remote: nowPlaying.remote),
                            SizedBox(height: 4),
                            Text(
                              title,
                              style: textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.w500,
                                shadows: _textShadows,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: textTheme.titleMedium!.copyWith(
                                  color: ZenPalette.lavender,
                                  fontWeight: FontWeight.w300,
                                  shadows: _textShadows,
                                ),
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
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: _focused ? Border.all(color: ZenPalette.accent, width: 2) : null,
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                ),
              ),
            ],
          ),
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

/// The blurred artwork seen through the waves of the background: the tint gets lighter below each wave, so that the
/// artwork's colors show more and more towards the bottom. The waves swell while the media plays.
class _ArtworkWaves extends StatefulWidget {
  final ImageProvider? image;
  final bool playing;

  _ArtworkWaves({required this.image, required this.playing});

  @override
  State<_ArtworkWaves> createState() => _ArtworkWavesState();
}

class _ArtworkWavesState extends State<_ArtworkWaves> with SingleTickerProviderStateMixin {
  late final AnimationController _swell = AnimationController(vsync: this, duration: _ArtworkWavesPainter.swellPeriod);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSwell();
  }

  @override
  void didUpdateWidget(covariant _ArtworkWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSwell();
  }

  @override
  void dispose() {
    _swell.dispose();
    super.dispose();
  }

  /// The waves stay still when paused, when there is no artwork to see them, and when animations are disabled.
  void _updateSwell() {
    final swelling = widget.playing && widget.image != null && !MediaQuery.of(context).disableAnimations;
    if (swelling && !_swell.isAnimating) {
      _swell.repeat();
    } else if (!swelling && _swell.isAnimating) {
      _swell.stop();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // its own layer, so that the blurred artwork is cached instead of being blurred again on every frame
      if (widget.image != null)
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Image(image: widget.image!, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
      RepaintBoundary(child: CustomPaint(painter: _ArtworkWavesPainter(_swell))),
    ],
  );
}

class _ArtworkWavesPainter extends CustomPainter {
  static const swellPeriod = Duration(seconds: 9);

  /// Where the top of the panel is on the background's canvas, just above the crest of its first wave.
  static const _top = 490.0;

  /// Opacity of the tint above the first wave, then below each wave.
  static const _tints = [0.86, 0.68, 0.52, 0.38, 0.26, 0.16];

  // the swell travels along the waves, slightly out of step from one wave to the next
  static const _amplitude = 22.0;
  static const _wavelength = 1300.0;
  static const _phaseShift = 0.9;

  final Animation<double> swell;

  _ArtworkWavesPainter(this.swell) : super(repaint: swell);

  @override
  void paint(Canvas canvas, Size size) {
    // same proportions as the background: the panel only shows the crests of the first waves, unless it is too narrow
    // for the waves to reach its bottom, e.g. beside another panel: it then shows less of their width
    final scale = max(size.width / ZenWavesPainter.width, size.height / (ZenWavesPainter.height - _top));
    // in a layer, each wave replaces the tint of the ones behind instead of adding to it
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(scale);
    canvas.translate(0, -_top);
    final paint = Paint()..blendMode = BlendMode.src;
    canvas.drawRect(
      Rect.fromLTWH(0, _top, ZenWavesPainter.width, size.height / scale),
      paint..color = ZenPalette.surface.withValues(alpha: _tints[0]),
    );
    for (var i = 0; i < ZenWavesPainter.waveCount; ++i) {
      final phase = i * _phaseShift - 2 * pi * swell.value;
      final wave = ZenWavesPainter.wave(
        i,
        move: (point) => point.translate(0, _amplitude * sin(2 * pi * point.dx / _wavelength + phase)),
      );
      canvas.drawPath(wave, paint..color = ZenPalette.surface.withValues(alpha: _tints[i + 1]));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtworkWavesPainter oldDelegate) => swell != oldDelegate.swell;
}

/// The app, and whether the media plays on another device.
class _AppLabel extends StatelessWidget {
  final App? application;
  final bool remote;

  _AppLabel({required this.application, required this.remote});

  @override
  Widget build(BuildContext context) {
    final label = [?application?.name, if (remote) "Sur un autre appareil"].join(" · ");
    return Row(
      children: [
        if (application?.icon != null) ...[
          Image.memory(application!.icon!, height: 18, gaplessPlayback: true),
          SizedBox(width: 6),
        ],
        if (label.isNotEmpty)
          Text(label, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: ZenPalette.lavender)),
      ],
    );
  }
}

/// The artwork keeps its own aspect ratio (e.g. square album covers, 16:9 video thumbnails) so that it isn't cropped.
class _Art extends StatelessWidget {
  final ImageProvider? image;
  final App? application;

  _Art({required this.image, required this.application});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: _artSize * 16 / 9, maxHeight: _artSize),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: image != null
            ? Image(image: image!, height: _artSize, fit: BoxFit.contain, gaplessPlayback: true)
            : _placeholder(),
      ),
    ),
  );

  Widget _placeholder() => Container(
    width: _artSize,
    height: _artSize,
    color: ZenPalette.night,
    child: application?.icon != null
        ? Padding(padding: EdgeInsets.all(24), child: Image.memory(application!.icon!))
        : Icon(Icons.music_note, size: 64, color: ZenPalette.lavender),
  );
}

class _ProgressBar extends StatefulWidget {
  final NowPlaying nowPlaying;

  _ProgressBar({required this.nowPlaying});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  Timer? _timer;
  String? _timeWidthKey;
  double _timeWidth = 0;

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
    final textStyle = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: ZenPalette.lavender, fontFeatures: [ui.FontFeature.tabularFigures()]);
    final timeWidth = _cachedTimeWidth(context, duration, textStyle);
    // its own layer, as it is repainted twice a second
    return RepaintBoundary(
      child: Row(
        children: [
          SizedBox(
            width: timeWidth,
            child: Text(_format(position), style: textStyle, textAlign: TextAlign.end),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(ZenPalette.accent),
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: timeWidth,
            child: Text(_format(duration), style: textStyle),
          ),
        ],
      ),
    );
  }

  /// Measuring the digits takes a dozen text layouts, which are only done again when the duration's format changes.
  double _cachedTimeWidth(BuildContext context, Duration duration, TextStyle style) {
    final key =
        "${_format(duration).replaceAll(RegExp(r"\d"), "0")} ${MediaQuery.textScalerOf(context).hashCode} ${style.hashCode}";
    if (key != _timeWidthKey) {
      _timeWidthKey = key;
      _timeWidth = _measureTimeWidth(context, duration, style);
    }
    return _timeWidth;
  }

  /// Both times take the room of the duration written with the widest digit, so that the bar keeps its size while the
  /// position moves, whatever the digits of the font.
  double _measureTimeWidth(BuildContext context, Duration duration, TextStyle style) {
    double width(String text) => (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).width;
    final widestDigit = List.generate(10, (digit) => "$digit").reduce((a, b) => width(b) > width(a) ? b : a);
    return width(_format(duration).replaceAll(RegExp(r"\d"), widestDigit)).ceilToDouble();
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
                Text(
                  "L'accès aux notifications est nécessaire pour afficher la lecture en cours.",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
