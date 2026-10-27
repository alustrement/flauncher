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

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FLauncherAboutDialog extends StatelessWidget {
  final PackageInfo packageInfo;

  FLauncherAboutDialog({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final underlined = textStyle.copyWith(decoration: TextDecoration.underline);
    return AboutDialog(
      applicationName: packageInfo.appName,
      applicationVersion: "${packageInfo.version} (${packageInfo.buildNumber})",
      applicationIcon: Image.asset("assets/logo.png", height: 72),
      applicationLegalese: "© 2021 Étienne Fesser\n© 2026 Aurélien Lustrement",
      children: [
        SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: textStyle,
            children: [
              TextSpan(
                text:
                    "Waves Launcher TV est un launcher alternatif et open source pour Android TV, "
                    "basé sur FLauncher et distribué sous licence GPLv3.\n"
                    "Code source disponible sur ",
              ),
              TextSpan(text: "https://github.com/alustrement/flauncher", style: underlined),
              TextSpan(text: "."),
            ],
          ),
        ),
      ],
    );
  }
}
