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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart';

/// Notifies its listeners when Home is pressed once, to bring the launcher back to the top of its page.
class HomeService extends ChangeNotifier {
  bool _inLauncher = true;

  /// Whether the launcher was already displayed when Home was last pressed, rather than another app.
  bool get inLauncher => _inLauncher;

  HomeService(FLauncherChannel fLauncherChannel) {
    fLauncherChannel.addHomePressedListener((inLauncher) {
      _inLauncher = inLauncher;
      notifyListeners();
    });
  }
}
