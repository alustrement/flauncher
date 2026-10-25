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
        _background(),
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
                : _emptyState(context),
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

  /// The clock and the settings, which scroll with the page.
  Widget _topBar(BuildContext context) => Container(
    height: RevealOnFocus.topBarHeight,
    padding: EdgeInsets.only(bottom: RevealOnFocus.topBarHeight - kToolbarHeight),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RevealOnFocus(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 2.0,
                top: 18.0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2, tileMode: TileMode.decal),
                  child: Icon(Icons.settings_outlined, color: Colors.black54),
                ),
              ),
              IconButton(
                padding: EdgeInsets.all(2),
                constraints: BoxConstraints(),
                splashRadius: 20,
                color: ZenPalette.lavender,
                focusColor: ZenPalette.waves.first.withValues(alpha: 0.4),
                icon: Icon(Icons.settings_outlined),
                onPressed: () => showDialog(context: context, builder: (_) => SettingsPanel()),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: Align(alignment: Alignment.center, child: TimeWidget()),
        ),
      ],
    ),
  );

  /// The night blue of the Zen look, with its layers of violet waves.
  Widget _background() => Container(
    key: Key("background"),
    color: ZenPalette.night,
    child: RepaintBoundary(
      child: CustomPaint(painter: ZenWavesPainter(), child: SizedBox.expand()),
    ),
  );

  /// In the middle of the upper half of the screen, where the splash screen shows FLauncher's name.
  Widget _emptyState(BuildContext context) => Align(
    alignment: Alignment(0, -0.5),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(ZenPalette.accent)),
        SizedBox(height: 16),
        Text("Chargement…", style: Theme.of(context).textTheme.titleLarge!.copyWith(color: ZenPalette.lavender)),
      ],
    ),
  );
}
