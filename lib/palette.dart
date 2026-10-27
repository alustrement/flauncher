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

import 'package:flutter/widgets.dart';

/// Colors of the "Zen" look: a night blue background with layers of violet waves.
mixin ZenPalette {
  static const night = Color(0xFF001220);
  static const surface = Color(0xFF0A1832);
  static const lavender = Color(0xFFC9C4F5);
  static const accent = Color(0xFFB9AEFF);
  static const waves = [Color(0xFF6F5DF1), Color(0xFF6B50F5), Color(0xFF6840F9), Color(0xFF652BFB), Color(0xFF6500FE)];

  /// Halo around the focused element, outside of its [accent] border.
  static const focusGlow = [BoxShadow(color: Color(0x476F5DF1), spreadRadius: 4, blurRadius: 6)];
}
