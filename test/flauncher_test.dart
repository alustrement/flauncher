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
import 'package:flauncher/flauncher.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/home_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/all_apps_page.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
import 'package:flauncher/widgets/watch_next_row.dart';
import 'package:flauncher/widgets/zen_waves_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'helpers.dart';
import 'mocks.dart';
import 'mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = Size(1280, 720);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Home page shows categories with apps", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    final favoritesCategory = fakeCategory(name: "Favorites", order: 0, type: CategoryType.row);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(favoritesCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher.1",
          name: "FLauncher 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: null,
        ),
      ]),
      CategoryWithApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "2.0.0",
          banner: kTransparentImage,
          icon: null,
        ),
      ]),
    ]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(AppsGrid), findsOneWidget);
    expect(find.byKey(Key("${applicationsCategory.id}-me.efesser.flauncher.2")), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.byKey(Key("${favoritesCategory.id}-me.efesser.flauncher.1")), findsOneWidget);
    expect(tester.widget(find.byKey(Key("background"))), isA<Container>());
  });

  testWidgets("Home page shows category empty-state", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    final applicationsCategory = fakeCategory(name: "Applications", order: 0, type: CategoryType.grid);
    final favoritesCategory = fakeCategory(name: "Favorites", order: 1, type: CategoryType.row);
    when(appsService.categoriesWithApps)
        .thenReturn([CategoryWithApps(applicationsCategory, []), CategoryWithApps(favoritesCategory, [])]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.byType(AppsGrid), findsOneWidget);
    expect(find.text("Cette catégorie est vide."), findsNWidgets(2));
  });

  testWidgets("Home page paints the Zen waves in the background", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.categoriesWithApps).thenReturn([]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    final background = find.byKey(Key("background"));
    final waves = find.descendant(of: background, matching: find.byType(CustomPaint));
    expect(tester.widget<CustomPaint>(waves).painter, isA<ZenWavesPainter>());
    expect(tester.getSize(waves), tester.getSize(background));
  });

  testWidgets("Pressing select on settings icon opens SettingsPanel", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "Favorites", order: 0), []),
      CategoryWithApps(fakeCategory(name: "Applications", order: 1), []),
    ]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.byType(SettingsPanelPage), findsOneWidget);
  });

  testWidgets("Pressing select on all apps icon opens AllAppsPage, sorted and without the hidden apps", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.categoriesWithApps).thenReturn([CategoryWithApps(fakeCategory(name: "Favorites", order: 0), [])]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);
    when(appsService.applications).thenReturn([
      fakeApp(packageName: "me.efesser.b", name: "beta", icon: kTransparentImage),
      fakeApp(packageName: "me.efesser.hidden", name: "Hidden", icon: kTransparentImage, hidden: true),
      fakeApp(packageName: "me.efesser.a", name: "Alpha", icon: kTransparentImage),
    ]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AllAppsPage), findsOneWidget);
    expect(find.text("Toutes les applications"), findsOneWidget);
    final cards = tester.widgetList<AppCard>(find.byType(AppCard)).map((card) => card.application.name);
    expect(cards, ["Alpha", "beta"]);
    expect(
      FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<AppCard>()!.application.name,
      "Alpha",
    );
  });

  testWidgets("The all apps icon and the recent plays can be hidden", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(appsService.categoriesWithApps).thenReturn([]);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    await _pumpWidgetWithProviders(
      tester,
      appsService,
      settingsService,
      showAllApplications: false,
      showRecentPlays: false,
    );

    expect(find.byKey(Key("all-apps")), findsNothing);
    expect(find.byIcon(Symbols.apps), findsNothing);
    expect(find.byType(WatchNextRow), findsNothing);
  });

  testWidgets("Pressing select on app opens ApplicationInfoPanel", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
      banner: kTransparentImage,
      icon: kTransparentImage,
    );
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "Favorites", order: 0), []),
      CategoryWithApps(fakeCategory(name: "Applications", order: 1), [app]),
    ]);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    verify(appsService.launchApp(app));
  });

  testWidgets("Long pressing on app opens ApplicationInfoPanel", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "Favorites", order: 0), []),
      CategoryWithApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    await tester.longPress(find.byKey(Key("${applicationsCategory.id}-me.efesser.flauncher")));
    await tester.pump();

    expect(find.byType(ApplicationInfoPanel), findsOneWidget);
  });

  testWidgets("AppCard moves in grid", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "Favorites", order: 0), []),
      CategoryWithApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    await tester.longPress(find.byKey(Key("${applicationsCategory.id}-me.efesser.flauncher")));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveOrderInCategory(applicationsCategory));
  });

  testWidgets("AppCard moves in row", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.row);
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "Favorites", order: 0), []),
      CategoryWithApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);
    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    await tester.longPress(find.byKey(Key("${applicationsCategory.id}-me.efesser.flauncher")));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveOrderInCategory(applicationsCategory));
  });

  testWidgets("Moving down does not skip row", (tester) async {
    // given
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();

    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    /*
     * we are creating 3 rows like the following:
     * ▭ ▭ ▭
     * ▭ ▭
     * ▭ ▭ ▭
     */
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.tv3",
          name: "tv 3",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
      CategoryWithApps(fakeCategory(name: "music", order: 1), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
      CategoryWithApps(fakeCategory(name: "games", order: 2), [
        fakeApp(
          packageName: "me.efesser.game1",
          name: "game 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.game2",
          name: "game 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.game3",
          name: "game 3",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    // when
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    Element? music1 = findAppCardByPackageName(tester, "me.efesser.music1");
    expect(music1, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isFalse);
    // going down leads to the first app of the next row, whatever the position in the current one
    expect(Focus.of(music1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    Element? game1 = findAppCardByPackageName(tester, "me.efesser.game1");
    expect(game1, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1).hasFocus, isFalse);
    expect(Focus.of(game1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1).hasFocus, isTrue);
    expect(Focus.of(game1).hasFocus, isFalse);
  });

  testWidgets("Moving left or right stays on the same row", (tester) async {
    // given
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();

    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭ ▭ ▭
     */
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
      CategoryWithApps(fakeCategory(name: "music", order: 1, columnsCount: 5), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music3",
          name: "music 3",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music4",
          name: "music 4",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music5",
          name: "music 5",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    Element? music1 = findAppCardByPackageName(tester, "me.efesser.music1");
    expect(music1, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1!).hasFocus, isTrue);

    // check right direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1).hasFocus, isFalse);
    expect(Focus.of(music2!).hasFocus, isTrue);

    // check if right on the last app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? music5 = findAppCardByPackageName(tester, "me.efesser.music5");
    expect(music5, isNotNull);
    // Element? settings = findSettingsIcon(tester);
    // expect(settings, isNotNull);
    expect(Focus.of(music5!).hasFocus, isTrue);
    // expect(Focus.of(settings!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(Focus.of(tv1).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(Focus.of(music1).hasFocus, isTrue);

    // check left direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(Focus.of(music2).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(Focus.of(music1).hasFocus, isTrue);

    // check if going left on the first app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(Focus.of(music1).hasFocus, isTrue);
  });

  group("Initial focus", () {
    late MockAppsService appsService;
    late MockSettingsService settingsService;
    final nowPlaying = NowPlaying(packageName: "com.spotify.tv.android", title: "Lonely Soldier");

    setUp(() {
      appsService = MockAppsService();
      settingsService = MockSettingsService();
      when(appsService.initialized).thenReturn(true);
      when(appsService.applications).thenReturn([]);
      when(settingsService.use24HourTimeFormat).thenReturn(false);
      when(appsService.categoriesWithApps).thenReturn([
        CategoryWithApps(fakeCategory(name: "tv", order: 0, type: CategoryType.row), [
          for (var i = 1; i <= 2; ++i)
            fakeApp(packageName: "me.efesser.tv$i", name: "tv $i", banner: kTransparentImage, icon: kTransparentImage),
        ]),
      ]);
    });

    bool panelHasFocus(WidgetTester tester) => Focus.of(tester.element(find.text("Lonely Soldier"))).hasFocus;

    testWidgets("goes to the top of the page, even when it appears after the launch", (tester) async {
      await _pumpWidgetWithProviders(tester, appsService, settingsService);
      expect(Focus.of(findAppCardByPackageName(tester, "me.efesser.tv1")!).hasFocus, isTrue);

      await _pumpWidgetWithProviders(tester, appsService, settingsService, nowPlaying: nowPlaying);
      await tester.pump();
      expect(panelHasFocus(tester), isTrue);
    });

    for (final inLauncher in [true, false]) {
      testWidgets("goes back to the top of the page when Home is pressed "
          "${inLauncher ? "in the launcher" : "in another app"}", (tester) async {
        final channel = MockFLauncherChannel();
        final homeService = HomeService(channel);
        final homePressed = verify(channel.addHomePressedListener(captureAny)).captured.single as void Function(bool);
        when(appsService.categoriesWithApps).thenReturn([
          CategoryWithApps(fakeCategory(name: "tv", order: 0, type: CategoryType.row), [
            for (var i = 1; i <= 10; ++i)
              fakeApp(
                packageName: "me.efesser.tv$i",
                name: "tv $i",
                banner: kTransparentImage,
                icon: kTransparentImage,
              ),
          ]),
          CategoryWithApps(fakeCategory(name: "music", order: 1, type: CategoryType.row), [
            for (var i = 1; i <= 3; ++i)
              fakeApp(
                packageName: "me.efesser.music$i",
                name: "music $i",
                banner: kTransparentImage,
                icon: kTransparentImage,
              ),
          ]),
        ]);
        await _pumpWidgetWithProviders(tester, appsService, settingsService, homeService: homeService);
        final start = tester.getTopLeft(find.byWidget(findAppCardByPackageName(tester, "me.efesser.tv1")!.widget));

        // the first row scrolled, and the focus in the second one
        for (var i = 0; i < 7; ++i) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        }
        // a first frame starts the scrolling, the next ones move it
        await tester.pump();
        await tester.pump(RevealOnFocus.duration);
        expect(findAppCardByPackageName(tester, "me.efesser.tv1"), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.pump(RevealOnFocus.duration);
        expect(Focus.of(findAppCardByPackageName(tester, "me.efesser.music2")!).hasFocus, isTrue);

        homePressed(inLauncher);
        // the rows scroll back, then the focus goes to the top
        await tester.pump();
        await tester.pump(RevealOnFocus.duration);
        await tester.pump(RevealOnFocus.duration);
        final tv1 = findAppCardByPackageName(tester, "me.efesser.tv1")!;
        expect(Focus.of(tv1).hasFocus, isTrue);
        expect(tester.getTopLeft(find.byWidget(tv1.widget)), start);
      });
    }

    testWidgets("stays where the user moved when a section appears above", (tester) async {
      await _pumpWidgetWithProviders(tester, appsService, settingsService);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final tv2 = findAppCardByPackageName(tester, "me.efesser.tv2")!;
      expect(Focus.of(tv2).hasFocus, isTrue);

      await _pumpWidgetWithProviders(tester, appsService, settingsService, nowPlaying: nowPlaying);
      await tester.pump();
      expect(Focus.of(tv2).hasFocus, isTrue);
      expect(panelHasFocus(tester), isFalse);
    });
  });

  testWidgets("Moving down brings every row at the same height", (tester) async {
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();
    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);
    when(appsService.categoriesWithApps).thenReturn([
      for (var row = 0; row < 10; ++row)
        CategoryWithApps(fakeCategory(name: "row $row", order: row, type: CategoryType.row), [
          for (var column = 0; column < 3; ++column)
            fakeApp(
              packageName: "me.efesser.app$row.$column",
              name: "app $row.$column",
              banner: kTransparentImage,
              icon: kTransparentImage,
            ),
        ]),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    double focusedRowTop(int row) {
      final card = findAppCardByPackageName(tester, "me.efesser.app$row.0")!;
      expect(Focus.of(card).hasFocus, isTrue);
      return tester.getTopLeft(find.byWidget(card.widget)).dy;
    }

    // the first row is where every row comes when focused, until the end of the page
    final top = focusedRowTop(0);
    for (var row = 1; row < 5; ++row) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump(RevealOnFocus.duration);
      expect(focusedRowTop(row), moreOrLessEquals(top, epsilon: 0.5));
    }
  });

  testWidgets("Moving up can go the settings icon, moving right stays on the row", (tester) async {
    // given
    final appsService = MockAppsService();
    final settingsService = MockSettingsService();

    when(appsService.initialized).thenReturn(true);
    when(settingsService.use24HourTimeFormat).thenReturn(false);

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭
     */
    when(appsService.categoriesWithApps).thenReturn([
      CategoryWithApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
      CategoryWithApps(fakeCategory(name: "music", order: 1), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
        fakeApp(
          packageName: "me.efesser.music3",
          name: "music 3",
          version: "1.0.0",
          banner: kTransparentImage,
          icon: kTransparentImage,
        ),
      ]),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, settingsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? tv2 = findAppCardByPackageName(tester, "me.efesser.tv2");
    expect(Focus.of(tv2!).hasFocus, isTrue);

    // the leftmost entry of the top bar is all the applications, the settings are on its right
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? settingsIcon = findSettingsIcon(tester);
    expect(settingsIcon, isNotNull);
    expect(Focus.of(settingsIcon!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(Focus.of(settingsIcon).hasFocus, isFalse);
    expect(Focus.of(tv1).hasFocus, isTrue);

    // the second row is longer: going right from the end of the first one doesn't go down to it
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(Focus.of(tv2).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? music3 = findAppCardByPackageName(tester, "me.efesser.music3");
    expect(Focus.of(music3!).hasFocus, isTrue);
    expect(Focus.of(settingsIcon).hasFocus, isFalse);
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  AppsService appsService,
  SettingsService settingsService, {
  NowPlaying? nowPlaying,
  HomeService? homeService,
  bool showAllApplications = true,
  bool showRecentPlays = true,
}) async {
  when(settingsService.showAllApplications).thenReturn(showAllApplications);
  when(settingsService.showRecentPlays).thenReturn(showRecentPlays);
  final mediaService = MockMediaService();
  when(mediaService.permissionGranted).thenReturn(true);
  when(mediaService.medias).thenReturn([?nowPlaying]);
  when(mediaService.playing).thenReturn(nowPlaying?.playing ?? false);
  when(appsService.applications).thenReturn([]);
  final watchNextService = MockWatchNextService();
  when(watchNextService.permissionGranted).thenReturn(true);
  when(watchNextService.programs).thenReturn([]);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        ChangeNotifierProvider<MediaService>.value(value: mediaService),
        ChangeNotifierProvider<WatchNextService>.value(value: watchNextService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<HomeService>.value(value: homeService ?? HomeService(MockFLauncherChannel())),
      ],
      builder: (_, _) => MaterialApp(
        locale: Locale("fr"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FLauncher(),
      ),
    ),
  );
  await tester.pump(Duration(seconds: 30), EnginePhase.sendSemanticsUpdate);
}
