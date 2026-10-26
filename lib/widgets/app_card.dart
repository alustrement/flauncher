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

import 'package:flauncher/database.dart';
import 'package:flauncher/palette.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

const _validationKeys = [LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA];
const _radius = 12.0;

class AppCard extends StatefulWidget {
  /// The category the card is shown in, if any: the applications outside of a category can't be moved.
  final Category? category;
  final App application;
  final void Function(AxisDirection)? onMove;
  final VoidCallback? onMoveEnd;

  AppCard({super.key, required this.category, required this.application, this.onMove, this.onMoveEnd});

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _moving = false;

  @override
  Widget build(BuildContext context) => FocusKeyboardListener(
    onPressed: (key) => _onPressed(context, key),
    onLongPress: (key) => _onLongPress(context, key),
    builder: (context) => AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transformAlignment: Alignment.center,
        transform: _scaleTransform(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: Focus.of(context).hasFocus ? ZenPalette.focusGlow : [],
        ),
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: widget.application.banner == null
                ? BorderSide(color: ZenPalette.lavender.withValues(alpha: 0.18))
                : BorderSide.none,
          ),
          color: ZenPalette.surface,
          clipBehavior: Clip.antiAlias,
          elevation: Focus.of(context).hasFocus ? 16 : 0,
          shadowColor: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InkWell(
                focusColor: Colors.transparent,
                onTap: () => _onPressed(context, null),
                onLongPress: () => _onLongPress(context, null),
                child: widget.application.banner != null
                    ? Ink.image(image: MemoryImage(widget.application.banner!), fit: BoxFit.cover)
                    : Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(image: MemoryImage(widget.application.icon!), gaplessPlayback: true),
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text(
                                  widget.application.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_moving) ..._arrows(),
              IgnorePointer(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  // a translucent color rather than an opacity, which would take a layer for each card
                  decoration: BoxDecoration(
                    color: Focus.of(context).hasFocus ? Colors.transparent : Colors.black.withValues(alpha: 0.10),
                    border: Focus.of(context).hasFocus ? Border.all(color: ZenPalette.accent, width: 2) : null,
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

  Matrix4 _scaleTransform(BuildContext context) {
    final scale = _moving
        ? 1.0
        : Focus.of(context).hasFocus
        ? 1.06
        : 1.0;
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  List<Widget> _arrows() => [
    _arrow(Alignment.centerLeft, Symbols.keyboard_arrow_left),
    _arrow(Alignment.topCenter, Symbols.keyboard_arrow_up),
    _arrow(Alignment.bottomCenter, Symbols.keyboard_arrow_down),
    _arrow(Alignment.centerRight, Symbols.keyboard_arrow_right),
  ];

  Widget _arrow(Alignment alignment, IconData icon) => Align(
    alignment: alignment,
    child: Padding(
      padding: EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
        child: Icon(icon, size: 16),
      ),
    ),
  );

  KeyEventResult _onPressed(BuildContext context, LogicalKeyboardKey? key) {
    if (_moving) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Scrollable.ensureVisible(
          context,
          alignment: 0.1,
          duration: Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        ),
      );
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.onMove?.call(AxisDirection.left);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.onMove?.call(AxisDirection.up);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        widget.onMove?.call(AxisDirection.right);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.onMove?.call(AxisDirection.down);
      } else if (_validationKeys.contains(key)) {
        setState(() => _moving = false);
        widget.onMoveEnd?.call();
      }
      return KeyEventResult.handled;
    } else if (_validationKeys.contains(key)) {
      context.read<AppsService>().launchApp(widget.application);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onLongPress(BuildContext context, LogicalKeyboardKey? key) {
    if (!_moving && (key == null || longPressableKeys.contains(key))) {
      _showPanel(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showPanel(BuildContext context) async {
    final result = await showDialog<ApplicationInfoPanelResult>(
      context: context,
      builder: (context) => ApplicationInfoPanel(category: widget.category, application: widget.application),
    );
    if (result == ApplicationInfoPanelResult.reorderApp) {
      setState(() => _moving = true);
    }
  }
}
