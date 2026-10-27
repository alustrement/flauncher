/*
 * Waves Launcher TV
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
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// The accesses the features of the launcher need. Pressing one which isn't granted asks for it, or opens the settings
/// where it is granted; as Android TV often lacks them, how to grant it otherwise is then told below. The accesses only
/// granted in the settings tell where first, in a dialog which opens them.
class AccessesPanelPage extends StatefulWidget {
  static const String routeName = "accesses_panel";

  @override
  State<AccessesPanelPage> createState() => _AccessesPanelPageState();
}

class _AccessesPanelPageState extends State<AccessesPanelPage> with WidgetsBindingObserver {
  // unknown until read, they are read again when coming back from the settings
  bool? _defaultLauncher;
  bool? _accessibilityServiceEnabled;

  /// The titles of the accesses asked for, whose hint is shown as long as they aren't granted.
  final Set<String> _asked = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final appsService = context.read<AppsService>();
    final defaultLauncher = await appsService.isDefaultLauncher();
    final accessibilityServiceEnabled = await appsService.isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() {
        _defaultLauncher = defaultLauncher;
        _accessibilityServiceEnabled = accessibilityServiceEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Consumer2<WatchNextService, MediaService>(
    builder: (context, watchNextService, mediaService, _) => SingleChildScrollView(
      child: Column(
        children: [
          Text(AppLocalizations.of(context).accessesAndDefaultLauncher, style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          EnsureVisible(
            alignment: 0.5,
            child: _access(
              context,
              icon: Symbols.home,
              title: AppLocalizations.of(context).defaultLauncher,
              feature: AppLocalizations.of(context).defaultLauncherFeature,
              granted: _defaultLauncher,
              request: () => context.read<AppsService>().requestDefaultLauncher(),
              hint: AppLocalizations.of(context).defaultLauncherHint,
            ),
          ),
          _access(
            context,
            icon: Symbols.live_tv,
            title: AppLocalizations.of(context).tvPrograms,
            feature: AppLocalizations.of(context).recentPlays,
            granted: watchNextService.permissionGranted,
            request: watchNextService.requestPermission,
            hint: AppLocalizations.of(context).tvProgramsHint,
          ),
          _access(
            context,
            icon: Symbols.notifications,
            title: AppLocalizations.of(context).notificationAccess,
            feature: AppLocalizations.of(context).nowPlayingFeature,
            granted: mediaService.permissionGranted,
            request: mediaService.openPermissionSettings,
            hint: AppLocalizations.of(context).notificationAccessHint,
            inDialog: true,
          ),
          _access(
            context,
            icon: Symbols.accessibility_new,
            title: AppLocalizations.of(context).accessibility,
            feature: AppLocalizations.of(context).accessibilityFeature,
            granted: _accessibilityServiceEnabled,
            request: () => context.read<AppsService>().openAccessibilitySettings(),
            hint: AppLocalizations.of(context).accessibilityHint,
            inDialog: true,
          ),
        ],
      ),
    ),
  );

  Widget _access(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String feature,
    required bool? granted,
    required Future<void> Function() request,
    required String hint,
    bool inDialog = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () async {
            if (granted == false && inDialog) {
              await showDialog(
                context: context,
                builder: (_) => _SettingsProcedureDialog(title: title, procedure: hint, openSettings: request),
              );
            } else if (granted == false) {
              setState(() => _asked.add(title));
              await request();
            }
          },
          child: Row(
            children: [
              Icon(icon),
              Container(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.bodyMedium),
                    Text(feature, style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (granted != null)
                Icon(
                  granted ? Symbols.check_circle : Symbols.error,
                  key: Key("$title-${granted ? "granted" : "missing"}"),
                  color: granted ? ZenPalette.accent : Theme.of(context).colorScheme.error,
                ),
            ],
          ),
        ),
        if (granted == false && _asked.contains(title))
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(hint, style: textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Tells where an access is granted in the settings, which it opens.
class _SettingsProcedureDialog extends StatelessWidget {
  final String title;
  final String procedure;
  final Future<void> Function() openSettings;

  _SettingsProcedureDialog({required this.title, required this.procedure, required this.openSettings});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(procedure),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context).cancel)),
      TextButton(
        autofocus: true,
        onPressed: () {
          Navigator.of(context).pop();
          openSettings();
        },
        child: Text(AppLocalizations.of(context).openSettings),
      ),
    ],
  );
}
