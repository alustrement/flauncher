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

import 'dart:async';
import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flutter/foundation.dart' hide Category;

class AppsService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;
  final FLauncherDatabase _database;
  bool _initialized = false;
  bool _refreshed = false;

  List<App> _applications = [];
  List<CategoryWithApps> _categoriesWithApps = [];

  /// The instances of the applications last read from the database, by package name.
  Map<String, App> _knownApplications = {};

  bool get initialized => _initialized;

  /// Whether the applications have been compared with the system's since the launch.
  bool get refreshed => _refreshed;

  List<App> get applications => UnmodifiableListView(_applications);

  List<CategoryWithApps> get categoriesWithApps => _categoriesWithApps
      .map((item) => CategoryWithApps(item.category, UnmodifiableListView(item.applications)))
      .toList(growable: false);

  AppsService(this._fLauncherChannel, this._database) {
    _init();
  }

  Future<void> _init() async {
    // the applications known from the last launch are shown right away, while the system's are scanned; on the first
    // launch, the scan is needed to fill the default categories
    await _reloadCategories();
    if (!_database.wasCreated) {
      await _reloadApplications();
      _initialized = true;
      notifyListeners();
    }
    await _refreshState(shouldNotifyListeners: false);
    if (_database.wasCreated) {
      await _initDefaultCategories();
    }
    _fLauncherChannel.addAppsChangedListener((event) async {
      switch (event["action"]) {
        case "PACKAGE_ADDED":
        case "PACKAGE_CHANGED":
          await _database.persistApps([_buildAppCompanion(event["activitiyInfo"])]);
          break;
        case "PACKAGES_AVAILABLE":
          await _database.persistApps((event["activitiesInfo"] as List<dynamic>).map(_buildAppCompanion).toList());
          break;
        case "PACKAGE_REMOVED":
          await _database.deleteApps([event["packageName"]]);
          break;
      }
      await _reloadCategories();
      await _reloadApplications();
      notifyListeners();
    });
    _initialized = true;
    _refreshed = true;
    notifyListeners();
  }

  AppsCompanion _buildAppCompanion(dynamic data) => AppsCompanion(
    packageName: Value(data["packageName"]),
    name: Value(data["name"]),
    version: Value(data["version"] ?? "(unknown)"),
    banner: Value(data["banner"]),
    icon: Value(data["icon"]),
    hidden: Value.absent(),
    sideloaded: Value(data["sideloaded"]),
  );

  Future<void> _initDefaultCategories() => _database.transaction(() async {
    final tvApplications = _applications.where((element) => element.sideloaded == false);
    final nonTvApplications = _applications.where((element) => element.sideloaded == true);
    if (tvApplications.isNotEmpty) {
      await addCategory("Applis TV", shouldNotifyListeners: false);
      final tvAppsCategory = _categoriesWithApps
          .map((e) => e.category)
          .firstWhere((element) => element.name == "Applis TV");
      await setCategoryType(tvAppsCategory, CategoryType.grid, shouldNotifyListeners: false);
      for (final app in tvApplications) {
        await addToCategory(app, tvAppsCategory, shouldNotifyListeners: false);
      }
    }
    if (nonTvApplications.isNotEmpty) {
      await addCategory("Applis non TV", shouldNotifyListeners: false);
      final nonTvAppsCategory = _categoriesWithApps
          .map((e) => e.category)
          .firstWhere((element) => element.name == "Applis non TV");
      for (final app in nonTvApplications) {
        await addToCategory(app, nonTvAppsCategory, shouldNotifyListeners: false);
      }
    }
    await _reloadCategories();
  });

  Future<void> _refreshState({bool shouldNotifyListeners = true}) async {
    await _database.transaction(() async {
      final appsFromSystem = (await _fLauncherChannel.getApplications()).map(_buildAppCompanion).toList();

      final appsRemovedFromSystem = (await _database.listApplications())
          .where((app) => !appsFromSystem.any((systemApp) => systemApp.packageName.value == app.packageName))
          .map((app) => app.packageName)
          .toList();

      final List<String> uninstalledApplications = [];
      await Future.forEach(appsRemovedFromSystem, (String packageName) async {
        if (!(await _fLauncherChannel.applicationExists(packageName))) {
          uninstalledApplications.add(packageName);
        }
      });

      await _database.persistApps(appsFromSystem);
      await _database.deleteApps(uninstalledApplications);

      await _reloadCategories();
      await _reloadApplications();
    });
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// The applications which didn't change keep their instance, and so their images, which aren't decoded again.
  App _knownInstance(App application) {
    final known = _knownApplications[application.packageName];
    if (known != null && _sameApplication(known, application)) {
      return known;
    }
    _knownApplications[application.packageName] = application;
    return application;
  }

  Future<void> _reloadCategories() async {
    _categoriesWithApps = (await _database.listCategoriesWithVisibleApps())
        .map((item) => CategoryWithApps(item.category, item.applications.map(_knownInstance).toList()))
        .toList();
  }

  /// Also forgets the applications which aren't there anymore.
  Future<void> _reloadApplications() async {
    _applications = (await _database.listApplications()).map(_knownInstance).toList();
    _knownApplications = {for (final application in _applications) application.packageName: application};
  }

  Future<void> launchApp(App app) => _fLauncherChannel.launchApp(app.packageName);

  Future<void> openAppInfo(App app) => _fLauncherChannel.openAppInfo(app.packageName);

  Future<void> uninstallApp(App app) => _fLauncherChannel.uninstallApp(app.packageName);

  Future<void> openSettings() => _fLauncherChannel.openSettings();

  Future<bool> isDefaultLauncher() => _fLauncherChannel.isDefaultLauncher();

  Future<void> startAmbientMode() => _fLauncherChannel.startAmbientMode();

  Future<void> addToCategory(App app, Category category, {bool shouldNotifyListeners = true}) async {
    int index = await _database.nextAppCategoryOrder(category.id) ?? 0;
    await _database.insertAppsCategories([
      AppsCategoriesCompanion.insert(categoryId: category.id, appPackageName: app.packageName, order: index),
    ]);
    await _reloadCategories();
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> removeFromCategory(App app, Category category) async {
    await _database.deleteAppCategory(category.id, app.packageName);
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> saveOrderInCategory(Category category) async {
    final applications = _categoriesWithApps.firstWhere((element) => element.category.id == category.id).applications;
    final orderedAppCategories = <AppsCategoriesCompanion>[];
    for (int i = 0; i < applications.length; ++i) {
      orderedAppCategories.add(
        AppsCategoriesCompanion(
          categoryId: Value(category.id),
          appPackageName: Value(applications[i].packageName),
          order: Value(i),
        ),
      );
    }
    await _database.replaceAppsCategories(orderedAppCategories);
    await _reloadCategories();
    notifyListeners();
  }

  void reorderApplication(Category category, int oldIndex, int newIndex) {
    final applications = _categoriesWithApps.firstWhere((element) => element.category.id == category.id).applications;
    final application = applications.removeAt(oldIndex);
    applications.insert(newIndex, application);
    notifyListeners();
  }

  Future<void> addCategory(String categoryName, {bool shouldNotifyListeners = true}) async {
    final orderedCategories = <CategoriesCompanion>[];
    for (int i = 0; i < _categoriesWithApps.length; ++i) {
      final category = _categoriesWithApps[i].category;
      orderedCategories.add(CategoriesCompanion(id: Value(category.id), order: Value(i + 1)));
    }
    await _database.insertCategory(CategoriesCompanion.insert(name: categoryName, order: 0));
    await _database.updateCategories(orderedCategories);
    await _reloadCategories();
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> renameCategory(Category category, String categoryName) async {
    await _database.updateCategory(category.id, CategoriesCompanion(name: Value(categoryName)));
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(Category category) async {
    await _database.deleteCategory(category.id);
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> moveCategory(int oldIndex, int newIndex) async {
    final categoryWithApps = _categoriesWithApps.removeAt(oldIndex);
    _categoriesWithApps.insert(newIndex, categoryWithApps);
    final orderedCategories = <CategoriesCompanion>[];
    for (int i = 0; i < _categoriesWithApps.length; ++i) {
      final category = _categoriesWithApps[i].category;
      orderedCategories.add(CategoriesCompanion(id: Value(category.id), order: Value(i)));
    }
    await _database.updateCategories(orderedCategories);
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> hideApplication(App application) async {
    await _database.updateApp(application.packageName, AppsCompanion(hidden: Value(true)));
    await _reloadCategories();
    await _reloadApplications();
    notifyListeners();
  }

  Future<void> unHideApplication(App application) async {
    await _database.updateApp(application.packageName, AppsCompanion(hidden: Value(false)));
    await _reloadCategories();
    await _reloadApplications();
    notifyListeners();
  }

  Future<void> setCategoryType(Category category, CategoryType type, {bool shouldNotifyListeners = true}) async {
    await _database.updateCategory(category.id, CategoriesCompanion(type: Value(type)));
    await _reloadCategories();
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setCategorySort(Category category, CategorySort sort) async {
    await _database.updateCategory(category.id, CategoriesCompanion(sort: Value(sort)));
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> setCategoryColumnsCount(Category category, int columnsCount) async {
    await _database.updateCategory(category.id, CategoriesCompanion(columnsCount: Value(columnsCount)));
    await _reloadCategories();
    notifyListeners();
  }

  Future<void> setCategoryRowHeight(Category category, int rowHeight) async {
    await _database.updateCategory(category.id, CategoriesCompanion(rowHeight: Value(rowHeight)));
    await _reloadCategories();
    notifyListeners();
  }
}

bool _sameApplication(App a, App b) =>
    a.copyWith(banner: Value(null), icon: Value(null)) == b.copyWith(banner: Value(null), icon: Value(null)) &&
    _sameBytes(a.banner, b.banner) &&
    _sameBytes(a.icon, b.icon);

/// Faster than the generic list equality, which matters for the images of all the applications.
bool _sameBytes(Uint8List? a, Uint8List? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; ++i) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
