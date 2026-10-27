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
    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
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

  testWidgets("going down from a wide element leads to the first element of the row", (tester) async {
    final panelNode = FocusNode(debugLabel: "panel");
    final rowNodes = List.generate(4, (index) => FocusNode(debugLabel: "row item $index"));
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _focusable(panelNode, height: 100, width: 800),
              Row(children: rowNodes.map((node) => _focusable(node, height: 100, width: 200)).toList()),
            ],
          ),
        ),
      ),
    );
    panelNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rowNodes.first.hasFocus, isTrue);
  });

  testWidgets("going up or down leads to the first element of the row, wherever the current one is", (tester) async {
    final topNodes = List.generate(4, (index) => FocusNode(debugLabel: "top item $index"));
    final bottomNodes = List.generate(4, (index) => FocusNode(debugLabel: "bottom item $index"));
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: topNodes.map((node) => _focusable(node, height: 100, width: 200)).toList()),
              Row(children: bottomNodes.map((node) => _focusable(node, height: 100, width: 150)).toList()),
            ],
          ),
        ),
      ),
    );
    topNodes[2].requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(bottomNodes.first.hasFocus, isTrue);

    bottomNodes[3].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(topNodes.first.hasFocus, isTrue);
  });

  testWidgets("going down skips elements scrolled out of view on the left", (tester) async {
    final topNode = FocusNode(debugLabel: "top");
    final rowNodes = List.generate(6, (index) => FocusNode(debugLabel: "row item $index"));
    final scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _focusable(topNode, height: 100),
              SizedBox(
                height: 100,
                child: ListView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  children: rowNodes.map((node) => _focusable(node, height: 100, width: 200)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // item 0 is out of view, item 1 partially
    scrollController.jumpTo(250);
    topNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rowNodes[2].hasFocus, isTrue);
  });

  testWidgets("going left from the first element of a row stays there, even when the row above is scrolled", (
    tester,
  ) async {
    final firstRowNodes = List.generate(6, (index) => FocusNode(debugLabel: "first row item $index"));
    final secondRowNodes = List.generate(2, (index) => FocusNode(debugLabel: "second row item $index"));
    final scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: ListView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  children: firstRowNodes.map((node) => _focusable(node, height: 100, width: 200)).toList(),
                ),
              ),
              Row(children: secondRowNodes.map((node) => _focusable(node, height: 100, width: 200)).toList()),
            ],
          ),
        ),
      ),
    );
    // the first items of the first row are on the left of the screen
    scrollController.jumpTo(450);
    secondRowNodes.first.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(secondRowNodes.first.hasFocus, isTrue);
  });

  testWidgets("going right from the last element of a row stays there, even when the row below is longer", (
    tester,
  ) async {
    final firstRowNodes = List.generate(2, (index) => FocusNode(debugLabel: "first row item $index"));
    final secondRowNodes = List.generate(4, (index) => FocusNode(debugLabel: "second row item $index"));
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: firstRowNodes.map((node) => _focusable(node, height: 100, width: 150)).toList()),
              Row(children: secondRowNodes.map((node) => _focusable(node, height: 100, width: 150)).toList()),
            ],
          ),
        ),
      ),
    );
    firstRowNodes.last.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(firstRowNodes.last.hasFocus, isTrue);
  });
}

Widget _focusable(FocusNode focusNode, {required double height, double width = 100}) => Focus(
  focusNode: focusNode,
  child: SizedBox(height: height, width: width),
);
