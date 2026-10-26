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

import 'dart:ui';

import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/home_service.dart';
import 'package:flauncher/widgets/all_apps_page.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/initial_focus.dart';
import 'package:flauncher/widgets/now_playing_panel.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flauncher/widgets/watch_next_row.dart';
import 'package:flauncher/widgets/zen_waves_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: RowByRowTraversalPolicy(),
    child: Stack(
      children: [
        ZenBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer<AppsService>(
            builder: (context, appsService, _) => appsService.initialized
                ? SingleChildScrollView(
                    // no horizontal margin: the horizontal lists reach the edges of the screen, and the other
                    // sections have their own margins
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    // scrolling only moves the page's layer instead of painting it again on every frame
                    child: RepaintBoundary(
                      child: InitialFocus(
                        homeService: context.read<HomeService>(),
                        child: _page(context, appsService.categoriesWithApps),
                      ),
                    ),
                  )
                // the startup splash covers the page meanwhile
                : SizedBox.shrink(),
          ),
        ),
      ],
    ),
  );

  Widget _page(BuildContext context, List<CategoryWithApps> categoriesWithApps) => Column(
    children: [
      SkipInitialFocus(child: _topBar(context)),
      NowPlayingPanel(),
      WatchNextRow(),
      ...categoriesWithApps.map((categoryWithApps) {
        switch (categoryWithApps.category.type) {
          case CategoryType.row:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CategoryRow(
                key: Key(categoryWithApps.category.id.toString()),
                category: categoryWithApps.category,
                applications: categoryWithApps.applications,
              ),
            );
          case CategoryType.grid:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: AppsGrid(
                key: Key(categoryWithApps.category.id.toString()),
                category: categoryWithApps.category,
                applications: categoryWithApps.applications,
              ),
            );
        }
      }),
    ],
  );

  /// All the applications, the settings and the clock, which scroll with the page.
  Widget _topBar(BuildContext context) => Container(
    height: RevealOnFocus.topBarHeight,
    padding: EdgeInsets.only(bottom: RevealOnFocus.topBarHeight - kToolbarHeight),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topBarButton(
          Icons.view_module_outlined,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllAppsPage())),
          key: Key("all-apps"),
        ),
        SizedBox(width: 8),
        _topBarButton(Icons.settings_outlined, () => showDialog(context: context, builder: (_) => SettingsPanel())),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: Align(alignment: Alignment.center, child: TimeWidget()),
        ),
      ],
    ),
  );

  Widget _topBarButton(IconData icon, VoidCallback onPressed, {Key? key}) => RevealOnFocus(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 2.0,
          top: 18.0,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2, tileMode: TileMode.decal),
            child: Icon(icon, color: Colors.black54),
          ),
        ),
        IconButton(
          key: key,
          padding: EdgeInsets.all(2),
          constraints: BoxConstraints(),
          splashRadius: 20,
          color: ZenPalette.lavender,
          focusColor: ZenPalette.waves.first.withValues(alpha: 0.4),
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ],
    ),
  );
}
