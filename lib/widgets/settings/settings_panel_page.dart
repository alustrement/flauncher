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

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/settings/accesses_panel_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/categories_panel_page.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsPanelPage extends StatelessWidget {
  static const String routeName = "settings_panel";

  @override
  Widget build(BuildContext context) => Consumer<SettingsService>(
    builder: (context, settingsService, _) => SingleChildScrollView(
      child: Column(
        children: [
          Text(AppLocalizations.of(context).settings, style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          EnsureVisible(
            alignment: 0.5,
            child: TextButton(
              child: Row(
                children: [
                  Icon(Symbols.apps),
                  Container(width: 8),
                  Text(AppLocalizations.of(context).applications, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              onPressed: () => Navigator.of(context).pushNamed(ApplicationsPanelPage.routeName),
            ),
          ),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.category),
                Container(width: 8),
                Text(AppLocalizations.of(context).categories, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            onPressed: () => Navigator.of(context).pushNamed(CategoriesPanelPage.routeName),
          ),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.verified_user),
                Container(width: 8),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).accessesAndDefaultLauncher,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.of(context).pushNamed(AccessesPanelPage.routeName),
          ),
          Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.use24HourTimeFormat,
            onChanged: (value) => settingsService.setUse24HourTimeFormat(value),
            title: Text(AppLocalizations.of(context).use24HourTimeFormat),
            dense: true,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.showAllApplications,
            onChanged: (value) => settingsService.setShowAllApplications(value),
            title: Text(AppLocalizations.of(context).showAllApplications),
            dense: true,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.showRecentPlays,
            onChanged: (value) => settingsService.setShowRecentPlays(value),
            title: Text(AppLocalizations.of(context).showRecentPlays),
            dense: true,
          ),
          Divider(),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.settings),
                Container(width: 8),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).deviceSettings,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            onPressed: () => context.read<AppsService>().openSettings(),
          ),
          Divider(),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.info),
                Container(width: 8),
                Flexible(
                  child: Text(AppLocalizations.of(context).about, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                    ? FLauncherAboutDialog(packageInfo: snapshot.data!)
                    : Container(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
