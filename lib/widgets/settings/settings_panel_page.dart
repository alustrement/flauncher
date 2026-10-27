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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
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
          Text("Paramètres", style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          EnsureVisible(
            alignment: 0.5,
            child: TextButton(
              child: Row(
                children: [
                  Icon(Symbols.apps),
                  Container(width: 8),
                  Text("Applications", style: Theme.of(context).textTheme.bodyMedium),
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
                Text("Catégories", style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            onPressed: () => Navigator.of(context).pushNamed(CategoriesPanelPage.routeName),
          ),
          Divider(),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.settings),
                Container(width: 8),
                Text("Paramètres Android", style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            onPressed: () => context.read<AppsService>().openSettings(),
          ),
          Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.use24HourTimeFormat,
            onChanged: (value) => settingsService.setUse24HourTimeFormat(value),
            title: Text("Format 24 heures"),
            dense: true,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.showAllApplications,
            onChanged: (value) => settingsService.setShowAllApplications(value),
            title: Text("Afficher toutes les applications"),
            dense: true,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            value: settingsService.showRecentPlays,
            onChanged: (value) => settingsService.setShowRecentPlays(value),
            title: Text("Afficher les lectures récentes"),
            dense: true,
          ),
          Divider(),
          TextButton(
            child: Row(
              children: [
                Icon(Symbols.info),
                Container(width: 8),
                Text("À propos de FLauncher", style: Theme.of(context).textTheme.bodyMedium),
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
