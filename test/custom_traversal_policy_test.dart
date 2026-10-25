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

import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("going up stays in the scroll view when the row above is scrolled out of view", (tester) async {
    final topBarNode = FocusNode(debugLabel: "top bar");
    final firstRowNode = FocusNode(debugLabel: "first row");
    final secondRowNode = FocusNode(debugLabel: "second row");
    final scrollController = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: FocusTraversalGroup(
        policy: RowByRowTraversalPolicy(),
        child: Column(
          children: [
            _focusable(topBarNode, height: 50),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    _focusable(firstRowNode, height: 300),
                    _focusable(secondRowNode, height: 300),
                    SizedBox(height: 1000),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
    scrollController.jumpTo(250);
    secondRowNode.requestFocus();
    await tester.pump();
    // the first row is now mostly hidden above the top bar
    expect(firstRowNode.rect.center.dy, lessThan(topBarNode.rect.center.dy));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(firstRowNode.hasFocus, isTrue);

    // the launcher scrolls focused rows into view
    scrollController.jumpTo(0);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(topBarNode.hasFocus, isTrue);
  });
}

Widget _focusable(FocusNode focusNode, {required double height}) => Focus(
      focusNode: focusNode,
      child: SizedBox(height: height, width: 100),
    );
