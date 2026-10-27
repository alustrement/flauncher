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

import 'package:flutter/material.dart';

/// Scrolls the home page to its child when it gets the focus, the same way for every row so that moving from row to
/// row is smooth and regular: the focused row always comes at the same height, just under its section's title, where
/// the first section stands when the page isn't scrolled.
///
/// The child must be a card of a row, or a row of a grid, without the section's title: the space for the title is
/// left above it. In the top bar, it brings the page back to its top.
class RevealOnFocus extends StatelessWidget {
  static const duration = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;

  /// Where the child goes in its horizontal list, if it is in one.
  static const horizontalAlignment = 0.1;

  /// The space between a section's top and its first row of cards, apart from its title: the margin between
  /// sections, the space under the title and the list's padding.
  static const _spaceAboveRow = 24.0;

  final Widget child;

  RevealOnFocus({super.key, required this.child});

  /// The top bar at the top of the page, with the clock and the settings, and its margin with the first section.
  static const topBarHeight = kToolbarHeight + 16;

  /// Where the first section stands, under the top bar.
  static double pageTop(BuildContext context) => MediaQuery.of(context).padding.top + topBarHeight;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (focused) {
        _revealHorizontally(context);
        _revealVertically(context);
      }
    },
    child: child,
  );

  void _revealHorizontally(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && axisDirectionToAxis(scrollable.axisDirection) == Axis.horizontal) {
      scrollable.position.ensureVisible(
        context.findRenderObject()!,
        alignment: horizontalAlignment,
        duration: duration,
        curve: curve,
      );
    }
  }

  void _revealVertically(BuildContext context) {
    final scrollable = _outermostVerticalScrollable(context);
    final viewport = scrollable?.context.findRenderObject();
    final box = context.findRenderObject();
    if (scrollable == null || viewport is! RenderBox || box is! RenderBox) {
      return;
    }
    final position = scrollable.position;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final target = (position.pixels + top - _rowTop(context))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() > 0.5) {
      position.animateTo(target, duration: duration, curve: curve);
    }
  }

  /// Where the focused row's top goes: under the space for its section's title.
  double _rowTop(BuildContext context) {
    final title = TextPainter(
      text: TextSpan(text: " ", style: Theme.of(context).textTheme.titleLarge),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return pageTop(context) + _spaceAboveRow + title.height;
  }

  /// The page itself rather than a list or a grid it contains.
  ScrollableState? _outermostVerticalScrollable(BuildContext context) {
    ScrollableState? outermost;
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      if (axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical) {
        outermost = scrollable;
      }
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return outermost;
  }
}
