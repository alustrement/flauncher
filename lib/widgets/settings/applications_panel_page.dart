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

import 'package:flauncher/database.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ApplicationsPanelPage extends StatefulWidget {
  static const String routeName = "applications_panel";

  @override
  State<ApplicationsPanelPage> createState() => _ApplicationsPanelPageState();
}

class _ApplicationsPanelPageState extends State<ApplicationsPanelPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Text(_title(context), style: Theme.of(context).textTheme.titleLarge),
        Divider(),
        Material(
          type: MaterialType.transparency,
          child: TabBar(
            onTap: (index) => setState(() => _tab = index),
            tabs: [
              Tab(icon: Icon(Symbols.tv)),
              Tab(icon: Icon(Symbols.android)),
              Tab(icon: Icon(Symbols.visibility_off)),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(child: TabBarView(children: [_TVTab(), _SideloadedTab(), _HiddenTab()])),
      ],
    ),
  );

  String _title(BuildContext context) => switch (_tab) {
    0 => AppLocalizations.of(context).tvApplications,
    1 => AppLocalizations.of(context).nonTvApplications,
    2 => AppLocalizations.of(context).hiddenApplications,
    _ => throw ArgumentError.value(_tab, "index"),
  };
}

class _TVTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) => appsService.applications.where((app) => !app.sideloaded && !app.hidden).toList(),
    builder: (context, applications, _) => ListView(
      children: applications
          .map((application) => EnsureVisible(alignment: 0.5, child: _appCard(context, application)))
          .toList(),
    ),
  );
}

class _SideloadedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) => appsService.applications.where((app) => app.sideloaded && !app.hidden).toList(),
    builder: (context, applications, _) => ListView(
      children: applications
          .map((application) => EnsureVisible(alignment: 0.5, child: _appCard(context, application)))
          .toList(),
    ),
  );
}

class _HiddenTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Selector<AppsService, List<App>>(
    selector: (_, appsService) => appsService.applications.where((app) => app.hidden).toList(),
    builder: (context, applications, _) => ListView(
      children: applications
          .map((application) => EnsureVisible(alignment: 0.5, child: _appCard(context, application)))
          .toList(),
    ),
  );
}

Widget _appCard(BuildContext context, App application) => Card(
  clipBehavior: Clip.antiAlias,
  child: ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    title: Text(
      application.name,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    leading: Image.memory(application.icon!, height: 48),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!application.hidden)
          IconButton(
            constraints: BoxConstraints(),
            splashRadius: 20,
            icon: Icon(Symbols.add_box),
            onPressed: () => showDialog<Category>(context: context, builder: (_) => AddToCategoryDialog(application)),
          ),
        IconButton(
          constraints: BoxConstraints(),
          splashRadius: 20,
          icon: Icon(Symbols.info),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ApplicationInfoPanel(category: null, application: application),
          ),
        ),
      ],
    ),
  ),
);
