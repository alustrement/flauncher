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

import 'package:flauncher/providers/home_service.dart';
import 'package:flauncher/widgets/reveal_on_focus.dart';
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
///
/// Pressing Home ([homeService]) brings the page back to its top, every row back to its start, and the focus to the
/// top again: smoothly when the launcher is already displayed, right away when it comes back from another app.
class InitialFocus extends StatefulWidget {
  final HomeService? homeService;
  final Widget child;

  InitialFocus({super.key, this.homeService, required this.child});

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
    widget.homeService?.addListener(_backToTop);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusTop());
  }

  @override
  void didUpdateWidget(covariant InitialFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.homeService != oldWidget.homeService) {
      oldWidget.homeService?.removeListener(_backToTop);
      widget.homeService?.addListener(_backToTop);
    }
  }

  @override
  void dispose() {
    widget.homeService?.removeListener(_backToTop);
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

  Future<void> _backToTop() async {
    _moved = false;
    final positions = {
      for (final node in _focusNode.traversalDescendants)
        if (node.context != null) ..._scrollPositions(node.context!),
    }.where((position) => position.pixels != position.minScrollExtent);
    if (widget.homeService?.inLauncher ?? true) {
      await Future.wait(
        positions.map(
          (position) => position.animateTo(
            position.minScrollExtent,
            duration: RevealOnFocus.duration,
            curve: RevealOnFocus.curve,
          ),
        ),
      );
    } else {
      for (final position in positions.toList()) {
        position.jumpTo(position.minScrollExtent);
      }
      await WidgetsBinding.instance.endOfFrame;
    }
    // the first element of the top row is now at its start, and built
    _focusTop();
  }

  /// The positions of the page and of the row or grid [context] is in.
  Iterable<ScrollPosition> _scrollPositions(BuildContext context) sync* {
    for (
      var scrollable = Scrollable.maybeOf(context);
      scrollable != null;
      scrollable = Scrollable.maybeOf(scrollable.context)
    ) {
      yield scrollable.position;
    }
  }

  void _focusTop() {
    if (_moved || !mounted) {
      return;
    }
    final candidates = _focusNode.traversalDescendants.where(
      (node) => node.canRequestFocus && node.context?.findAncestorWidgetOfExactType<SkipInitialFocus>() == null,
    );
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

  SkipInitialFocus({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
