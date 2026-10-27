/*
 * Waves Launcher TV, based on FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _use24HourTimeFormatKey = "use_24_hour_time_format";
const _showAllApplicationsKey = "show_all_applications";
const _showRecentPlaysKey = "show_recent_plays";

class SettingsService extends ChangeNotifier {
  final SharedPreferences _sharedPreferences;

  bool get use24HourTimeFormat => _sharedPreferences.getBool(_use24HourTimeFormatKey) ?? true;

  /// Whether the top bar offers the page with all the applications.
  bool get showAllApplications => _sharedPreferences.getBool(_showAllApplicationsKey) ?? true;

  /// Whether the home page shows the row of the recent plays.
  bool get showRecentPlays => _sharedPreferences.getBool(_showRecentPlaysKey) ?? true;

  SettingsService(this._sharedPreferences);

  Future<void> setUse24HourTimeFormat(bool value) async {
    await _sharedPreferences.setBool(_use24HourTimeFormatKey, value);
    notifyListeners();
  }

  Future<void> setShowAllApplications(bool value) async {
    await _sharedPreferences.setBool(_showAllApplicationsKey, value);
    notifyListeners();
  }

  Future<void> setShowRecentPlays(bool value) async {
    await _sharedPreferences.setBool(_showRecentPlaysKey, value);
    notifyListeners();
  }
}
