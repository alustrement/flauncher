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

import 'package:flauncher/database.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/initial_focus.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _rowHeight = 170.0;
const _radius = 12.0;

/// Margin of the progress bar inside the card, so that it clears its rounded corners.
const _progressInset = 10.0;
const _progressHeight = 4.0;
const _textShadows = [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 8)];

class WatchNextRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<WatchNextService>(
        builder: (context, watchNextService, _) {
          if (!watchNextService.permissionGranted) {
            return _section(
                context, SkipInitialFocus(child: _PermissionHint(onPressed: watchNextService.requestPermission)));
          }
          if (watchNextService.programs.isEmpty) {
            return SizedBox.shrink();
          }
          final programs = watchNextService.programs;
          return _section(
            context,
            SizedBox(
              height: _rowHeight,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: programs.length,
                itemBuilder: (context, index) => RevealOnFocus(
                  key: Key("watch-next-${programs[index].id}"),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: _ProgramCard(
                      program: programs[index],
                      onPressed: () => watchNextService.open(programs[index]),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _section(BuildContext context, Widget child) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 32, bottom: 8),
              child: Text("Continuer à regarder",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: ZenPalette.lavender, shadows: _textShadows)),
            ),
            child,
          ],
        ),
      );
}

class _ProgramCard extends StatefulWidget {
  final WatchNextProgram program;
  final VoidCallback onPressed;

  _ProgramCard({required this.program, required this.onPressed});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final application = context.select<AppsService, App?>((appsService) {
      final matches = appsService.applications.where((app) => app.packageName == program.packageName);
      return matches.isNotEmpty ? matches.first : null;
    });
    final textTheme = Theme.of(context).textTheme;
    final subtitle = program.subtitle;
    final progress = program.progress;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedScale(
        scale: _focused ? 1.06 : 1.0,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: _focused ? ZenPalette.focusGlow : [],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            elevation: _focused ? 16 : 0,
            shadowColor: Colors.black,
            color: Theme.of(context).cardColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  focusColor: Colors.transparent,
                  onFocusChange: (focused) => setState(() => _focused = focused),
                  onTap: widget.onPressed,
                  child: _image(program, application),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1.0],
                        colors: [ZenPalette.night.withOpacity(0), ZenPalette.night.withOpacity(0.88)],
                      ),
                    ),
                  ),
                ),
                if (application?.icon != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.memory(application!.icon!, height: 24, gaplessPlayback: true),
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: progress != null ? _progressInset + _progressHeight + 6 : 8,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title ?? application?.name ?? program.packageName,
                          style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w500, shadows: _textShadows),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: textTheme.bodySmall!.copyWith(color: ZenPalette.lavender, shadows: _textShadows),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                if (progress != null)
                  Positioned(
                    left: _progressInset,
                    right: _progressInset,
                    bottom: _progressInset,
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_progressHeight / 2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: _progressHeight,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          valueColor: AlwaysStoppedAnimation(ZenPalette.accent),
                        ),
                      ),
                    ),
                  ),
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: _focused ? Border.all(color: ZenPalette.accent, width: 2) : null,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(WatchNextProgram program, App? application) {
    final ImageProvider image;
    if (program.image != null) {
      image = MemoryImage(program.image!);
    } else if (program.imageUri != null) {
      image = ResizeImage(NetworkImage(program.imageUri!), width: 640);
    } else {
      return _placeholder(application);
    }
    return Ink.image(
      image: image,
      fit: BoxFit.cover,
      onImageError: (_, __) {},
    );
  }

  Widget _placeholder(App? application) => application?.banner != null
      ? Ink.image(image: MemoryImage(application!.banner!), fit: BoxFit.cover)
      : Center(child: Icon(Icons.movie_outlined, size: 48, color: ZenPalette.lavender));
}

class _PermissionHint extends StatelessWidget {
  final VoidCallback onPressed;

  _PermissionHint({required this.onPressed});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: RevealOnFocus(
            child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, size: 32, color: Colors.white70),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "L'accès aux programmes TV est nécessaire pour afficher ce que vous pouvez continuer à regarder.",
                          style: Theme.of(context).textTheme.titleSmall),
                      SizedBox(height: 4),
                      SelectableText(
                        "adb shell pm grant me.efesser.flauncher android.permission.READ_TV_LISTINGS",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontFamily: "monospace"),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(onPressed: onPressed, child: Text("Autoriser")),
              ],
            ),
          ),
        )),
      );
}
