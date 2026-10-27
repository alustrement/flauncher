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

import 'package:flauncher/palette.dart';
import 'package:flutter/widgets.dart';

/// The night blue of the Zen look, with its layers of violet waves, behind the launcher's pages.
class ZenBackground extends StatelessWidget {
  const ZenBackground({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: Key("background"),
    color: ZenPalette.night,
    child: RepaintBoundary(
      child: CustomPaint(painter: ZenWavesPainter(), child: SizedBox.expand()),
    ),
  );
}

/// Layers of violet waves rising from the bottom.
///
/// The shapes are drawn on a 1920x1080 canvas which is stretched to the painted size.
/// A curve is either a cubic Bézier (two control points and its end), or a smooth one (second control point and end)
/// whose first control point mirrors the previous curve's second one, like SVG's "S" command.
class ZenWavesPainter extends CustomPainter {
  static const width = 1920.0;
  static const height = 1080.0;
  static const _opacity = 0.9;

  static const _waveStarts = [Offset(0, 760), Offset(0, 880), Offset(0, 900), Offset(0, 960), Offset(0, 1010)];
  static const _waves = [
    [
      [Offset(160, 820), Offset(300, 840), Offset(460, 760)],
      [Offset(760, 560), Offset(900, 560)],
      [Offset(1180, 680), Offset(1350, 690)],
      [Offset(1600, 600), Offset(1700, 620)],
      [Offset(1860, 700), Offset(1920, 740)],
    ],
    [
      [Offset(200, 870), Offset(420, 820), Offset(600, 830)],
      [Offset(900, 800), Offset(1100, 760)],
      [Offset(1400, 860), Offset(1600, 850)],
      [Offset(1850, 730), Offset(1920, 690)],
    ],
    [
      [Offset(150, 950), Offset(300, 960), Offset(520, 880)],
      [Offset(900, 790), Offset(1100, 760)],
      [Offset(1350, 860), Offset(1550, 900)],
      [Offset(1820, 960), Offset(1920, 1000)],
    ],
    [
      [Offset(180, 950), Offset(320, 1020), Offset(520, 990)],
      [Offset(720, 920), Offset(840, 940)],
      [Offset(1050, 1010), Offset(1250, 1000)],
      [Offset(1700, 960), Offset(1920, 920)],
    ],
    [
      [Offset(120, 1050), Offset(220, 1070), Offset(330, 1040)],
      [Offset(600, 990), Offset(900, 1000)],
      [Offset(1250, 1020), Offset(1400, 1010)],
      [Offset(1750, 990), Offset(1920, 1010)],
    ],
  ];

  static int get waveCount => _waves.length;

  const ZenWavesPainter();

  /// The [index]-th wave, from the back to the front, filled down to the bottom of the 1920x1080 canvas.
  ///
  /// [move] displaces each point of its curve, control points included, e.g. to animate it.
  static Path wave(int index, {Offset Function(Offset point)? move}) {
    final at = move ?? ((point) => point);
    final start = at(_waveStarts[index]);
    final wave = Path()..moveTo(start.dx, start.dy);
    _addCurves(wave, start, _waves[index].map((curve) => curve.map(at).toList()).toList());
    return wave
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / width, size.height / height);
    for (var i = 0; i < waveCount; ++i) {
      canvas.drawPath(wave(i), Paint()..color = ZenPalette.waves[i].withValues(alpha: _opacity));
    }
    canvas.restore();
  }

  static void _addCurves(Path path, Offset start, List<List<Offset>> curves) {
    var current = start;
    var lastControl = start;
    for (final curve in curves) {
      final firstControl = curve.length == 3 ? curve[0] : current * 2 - lastControl;
      final secondControl = curve[curve.length - 2];
      path.cubicTo(firstControl.dx, firstControl.dy, secondControl.dx, secondControl.dy, curve.last.dx, curve.last.dy);
      lastControl = secondControl;
      current = curve.last;
    }
  }

  @override
  bool shouldRepaint(ZenWavesPainter oldDelegate) => false;
}
