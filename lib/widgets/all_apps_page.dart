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

import 'package:flauncher/actions.dart';
import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/home_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/initial_focus.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
import 'package:flauncher/widgets/time_widget.dart';
import 'package:flauncher/widgets/zen_waves_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// All the applications of the device which aren't hidden, in alphabetical order, in a grid like the categories'.
class AllAppsPage extends StatefulWidget {
  static const columnsCount = 6;

  AllAppsPage({super.key});

  @override
  State<AllAppsPage> createState() => _AllAppsPageState();
}

class _AllAppsPageState extends State<AllAppsPage> {
  late final HomeService _homeService;

  @override
  void initState() {
    super.initState();
    _homeService = context.read<HomeService>()..addListener(_backHome);
  }

  @override
  void dispose() {
    _homeService.removeListener(_backHome);
    super.dispose();
  }

  /// Pressing Home goes back to the home page, from the dialogs opened here too.
  void _backHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) => Actions(
    actions: {BackIntent: BackAction(context)},
    child: FocusTraversalGroup(
      policy: RowByRowTraversalPolicy(),
      child: Stack(
        children: [
          ZenBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              // scrolling only moves the page's layer instead of painting it again on every frame
              child: RepaintBoundary(
                child: InitialFocus(
                  child: Column(
                    children: [
                      _topBar(),
                      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: _section(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// The clock, at the same place as on the home page.
  Widget _topBar() => Container(
    height: RevealOnFocus.topBarHeight,
    padding: EdgeInsets.only(bottom: RevealOnFocus.topBarHeight - kToolbarHeight),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: Align(alignment: Alignment.center, child: TimeWidget()),
        ),
      ],
    ),
  );

  Widget _section(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(left: 32),
        child: Text(
          "Toutes les applications",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: ZenPalette.lavender,
            shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 8)],
          ),
        ),
      ),
      Selector<AppsService, List<App>>(
        selector: (_, appsService) =>
            appsService.applications.where((app) => !app.hidden).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        builder: (context, applications, _) => GridView.builder(
          shrinkWrap: true,
          primary: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AllAppsPage.columnsCount,
            childAspectRatio: 16 / 9,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
          itemCount: applications.length,
          itemBuilder: (context, index) => RevealOnFocus(
            key: Key("all-${applications[index].packageName}"),
            child: AppCard(category: null, application: applications[index]),
          ),
        ),
      ),
    ],
  );
}
