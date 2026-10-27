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

import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/media_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// The accesses the features of the launcher need. Pressing one which isn't granted asks for it, or opens the settings
/// where it is granted; as Android TV often lacks them, how to grant it otherwise is then told below.
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
          Text("Autorisations et launcher par défaut", style: Theme.of(context).textTheme.titleLarge),
          Divider(),
          EnsureVisible(
            alignment: 0.5,
            child: _access(
              context,
              icon: Symbols.home,
              title: "Launcher par défaut",
              feature: "Ouvert par le bouton Accueil",
              granted: _defaultLauncher,
              request: () => context.read<AppsService>().requestDefaultLauncher(),
              hint:
                  "Si aucune fenêtre ne s'est ouverte, appuyez sur Accueil et choisissez Waves Launcher TV, "
                  "puis « Toujours ».",
            ),
          ),
          _access(
            context,
            icon: Symbols.live_tv,
            title: "Programmes TV",
            feature: "Lectures récentes",
            granted: watchNextService.permissionGranted,
            request: watchNextService.requestPermission,
            hint:
                "Si aucune fenêtre ne s'est ouverte, autorisez « Lire toutes les sources TV » dans "
                "Paramètres > Applications > Waves Launcher TV > Autorisations.",
          ),
          _access(
            context,
            icon: Symbols.notifications,
            title: "Accès aux notifications",
            feature: "Lecture en cours",
            granted: mediaService.permissionGranted,
            request: mediaService.openPermissionSettings,
            hint:
                "Si aucun écran ne s'est ouvert, les paramètres de cet appareil ne permettent pas de l'accorder : "
                "voir le README de Waves Launcher TV.",
          ),
          _access(
            context,
            icon: Symbols.accessibility_new,
            title: "Accessibilité",
            feature: "Applis récentes en appuyant deux fois sur Accueil",
            granted: _accessibilityServiceEnabled,
            request: () => context.read<AppsService>().openAccessibilitySettings(),
            hint:
                "Si aucun écran ne s'est ouvert, activez Waves Launcher TV dans "
                "Paramètres > Préférences de l'appareil > Accessibilité.",
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
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () async {
            if (granted == false) {
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
