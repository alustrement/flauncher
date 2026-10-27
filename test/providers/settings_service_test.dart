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

import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
  });

  test("setUse24HourTimeFormat", () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(sharedPreferences);

    await settingsService.setUse24HourTimeFormat(true);

    expect(sharedPreferences.getBool("use_24_hour_time_format"), isTrue);
  });

  group("getUse24HourTimeFormat", () {
    test("without value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      final settingsService = SettingsService(sharedPreferences);

      final use24HourTimeFormat = settingsService.use24HourTimeFormat;

      expect(use24HourTimeFormat, isTrue);
    });

    test("with value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      sharedPreferences.setBool("use_24_hour_time_format", false);
      final settingsService = SettingsService(sharedPreferences);

      final use24HourTimeFormat = settingsService.use24HourTimeFormat;

      expect(use24HourTimeFormat, isFalse);
    });
  });

  test("setShowAllApplications", () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(sharedPreferences);

    await settingsService.setShowAllApplications(false);

    expect(sharedPreferences.getBool("show_all_applications"), isFalse);
  });

  group("showAllApplications", () {
    test("without value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      final settingsService = SettingsService(sharedPreferences);

      expect(settingsService.showAllApplications, isTrue);
    });

    test("with value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      sharedPreferences.setBool("show_all_applications", false);
      final settingsService = SettingsService(sharedPreferences);

      expect(settingsService.showAllApplications, isFalse);
    });
  });

  test("setShowRecentPlays", () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final settingsService = SettingsService(sharedPreferences);

    await settingsService.setShowRecentPlays(false);

    expect(sharedPreferences.getBool("show_recent_plays"), isFalse);
  });

  group("showRecentPlays", () {
    test("without value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      final settingsService = SettingsService(sharedPreferences);

      expect(settingsService.showRecentPlays, isTrue);
    });

    test("with value from shared preferences", () async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
      sharedPreferences.setBool("show_recent_plays", false);
      final settingsService = SettingsService(sharedPreferences);

      expect(settingsService.showRecentPlays, isFalse);
    });
  });
}
