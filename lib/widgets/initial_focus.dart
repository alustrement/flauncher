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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _directionKeys = [
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
];

/// Focuses the element at the top of the page (the leftmost one of the top row) once it is displayed, and again
/// whenever sections appear or disappear above it, e.g. the media playing which is known a bit after the launch, until
/// the user moves.
class InitialFocus extends StatefulWidget {
  final Widget child;

  InitialFocus({Key? key, required this.child}) : super(key: key);

  @override
  State<InitialFocus> createState() => _InitialFocusState();
}

class _InitialFocusState extends State<InitialFocus> {
  final _focusNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusTop());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _focusNode.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && _directionKeys.contains(event.logicalKey)) {
      _moved = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _focusTop());
          return false;
        },
        child: Focus(
          focusNode: _focusNode,
          child: SizeChangedLayoutNotifier(child: widget.child),
        ),
      );

  void _focusTop() {
    if (_moved || !mounted) {
      return;
    }
    final candidates = _focusNode.traversalDescendants.where(
        (node) => node.canRequestFocus && node.context?.findAncestorWidgetOfExactType<SkipInitialFocus>() == null);
    if (candidates.isEmpty) {
      return;
    }
    final top = candidates.reduce((best, challenger) {
      final dy = challenger.rect.top.round() - best.rect.top.round();
      return dy < 0 || (dy == 0 && challenger.rect.left.round() < best.rect.left.round()) ? challenger : best;
    });
    if (!top.hasPrimaryFocus) {
      top.requestFocus();
    }
  }
}

/// Keeps its child from getting the initial focus, e.g. the placeholder of an empty category or a permission hint:
/// the focus goes to the first content instead.
class SkipInitialFocus extends StatelessWidget {
  final Widget child;

  SkipInitialFocus({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}
