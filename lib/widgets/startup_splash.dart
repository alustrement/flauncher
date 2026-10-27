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

import 'dart:async';

import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/zen_waves_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

/// Covers [child] with the look of the splash screen and a greeting, while the home page is built, its images decoded
/// and drawn for the first time, which makes its first frames take hundreds of milliseconds: the page then shows up
/// already smooth, and the keys pressed meanwhile are ignored instead of moving the focus on a page that can't be seen.
///
/// It fades out once the applications are shown and compared with the system's, and the frames follow each other at
/// the display's pace again; or at the latest [maxWait] after the applications are shown.
class StartupSplash extends StatefulWidget {
  static const maxWait = Duration(seconds: 4);
  static const fadeDuration = Duration(milliseconds: 400);

  /// A frame is smooth when it comes at most this long after the previous one: a few vsyncs, even at 24Hz.
  static const _smoothFrameGap = Duration(milliseconds: 50);
  static const _smoothFramesNeeded = 15;

  final Widget child;

  StartupSplash({super.key, required this.child});

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> with SingleTickerProviderStateMixin {
  // runs on every frame until the page is ready, which also keeps frames coming to tell when they are smooth
  late final Ticker _ticker = createTicker(_onFrame);
  Duration? _lastFrame;
  int _smoothFrames = 0;
  Timer? _maxWaitTimer;
  bool _ready = false;
  bool _faded = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_ignoreKey);
    _ticker.start();
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_ignoreKey);
    _maxWaitTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  KeyEventResult _ignoreKey(KeyEvent event) => _ready ? KeyEventResult.ignored : KeyEventResult.handled;

  void _onFrame(Duration elapsed) {
    final gap = _lastFrame != null ? elapsed - _lastFrame! : null;
    _lastFrame = elapsed;
    final appsService = context.read<AppsService>();
    if (!appsService.initialized) {
      return;
    }
    _maxWaitTimer ??= Timer(StartupSplash.maxWait, _fadeOut);
    _smoothFrames = appsService.refreshed && gap != null && gap <= StartupSplash._smoothFrameGap
        ? _smoothFrames + 1
        : 0;
    if (_smoothFrames >= StartupSplash._smoothFramesNeeded) {
      _fadeOut();
    }
  }

  void _fadeOut() {
    if (_ready) {
      return;
    }
    _maxWaitTimer?.cancel();
    _ticker.stop();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (!_faded)
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _ready ? 0 : 1,
            duration: StartupSplash.fadeDuration,
            onEnd: () => setState(() => _faded = true),
            child: _splash(context),
          ),
        ),
    ],
  );

  /// The splash screen's waves, with the greeting in the middle of the upper half, where the screen has room for it.
  Widget _splash(BuildContext context) => Container(
    color: ZenPalette.night,
    child: Stack(
      children: [
        // the waves aren't painted again with each frame of the progress indicator
        RepaintBoundary(
          child: CustomPaint(painter: ZenWavesPainter(), child: SizedBox.expand()),
        ),
        Align(
          alignment: Alignment(0, -0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_greeting(), style: Theme.of(context).textTheme.displayMedium!.copyWith(color: ZenPalette.lavender)),
              SizedBox(height: 24),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(ZenPalette.accent)),
            ],
          ),
        ),
      ],
    ),
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 5 ? "Bonsoir" : "Bonjour";
  }
}
