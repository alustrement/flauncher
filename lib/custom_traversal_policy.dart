import 'dart:math';

import 'package:flutter/material.dart';

/// This traversal policy manage the up and down direction to be totally
/// predictable.
/// Going up or down will always go to the next or previous row. All other
/// traversal policy try to be smart, and in some cases can skip rows when
/// going up or down.
class RowByRowTraversalPolicy extends FocusTraversalPolicy with DirectionalFocusTraversalPolicyMixin {
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) => descendants;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    List<FocusNode>? nodes = currentNode.nearestScope?.traversalDescendants.toList();
    if (nodes == null) {
      return super.inDirection(currentNode, direction);
    }

    NodeSearcher searcher = NodeSearcher(direction);
    List<CandidateNode> candidates = searcher.findCandidates(nodes, currentNode);
    if (candidates.isEmpty) {
      // the first and last elements of a row stay focused: the default policy would go to the closest element on
      // the left or on the right anywhere, e.g. in the row above when it is scrolled, or in a longer row below
      if (direction == TraversalDirection.left || direction == TraversalDirection.right) {
        return false;
      }
      return super.inDirection(currentNode, direction);
    }
    FocusNode nextNode = searcher.findBestFocusNode(candidates, currentNode);
    nextNode.requestFocus();
    return true;
  }
}

class NodeSearcher {
  final TraversalDirection directionToSearch;

  NodeSearcher(this.directionToSearch);

  /// should be called first
  List<CandidateNode> findCandidates(List<FocusNode> nodes, FocusNode from) {
    List<FocusNode> copy = List.from(nodes, growable: true);

    switch (directionToSearch) {
      case TraversalDirection.up:
        copy.removeWhere((element) => element.isBelowOrEquals(from));
        _preferSameScrollable(copy, from);
        break;
      case TraversalDirection.down:
        copy.removeWhere((element) => element.isAboveOrEquals(from));
        _preferSameScrollable(copy, from);
        break;
      case TraversalDirection.right:
        copy.removeWhere((element) => element.isLeftToOrEquals(from) || !element.isOnTheSameRow(from));
        break;
      case TraversalDirection.left:
        copy.removeWhere((element) => element.isRightToOrEquals(from) || !element.isOnTheSameRow(from));
        break;
    }
    return toCandidateNodes(copy);
  }

  /// Positions are compared on screen, so a row scrolled out of view can end up "above" a widget laid out outside
  /// of the scroll view (e.g. the app bar) and be skipped. Staying in the same scroll view as long as possible
  /// prevents that.
  void _preferSameScrollable(List<FocusNode> nodes, FocusNode from) {
    final scrollable = from.outermostVerticalScrollable;
    if (scrollable != null && nodes.any((node) => node.outermostVerticalScrollable == scrollable)) {
      nodes.removeWhere((node) => node.outermostVerticalScrollable != scrollable);
    }
  }

  FocusNode findBestFocusNode(List<CandidateNode> nodes, FocusNode from) {
    List<FocusNode> candidates = toFocusNodes(nodes);

    switch (directionToSearch) {
      case TraversalDirection.up:
      case TraversalDirection.down:
        return _leftmostVisibleOfClosestRow(candidates);
      case TraversalDirection.left:
      case TraversalDirection.right:
        return candidates.reduce((bestNode, challenger) {
          if (directionToSearch == TraversalDirection.left && challenger.isRightTo(bestNode)) {
            return challenger;
          } else if (directionToSearch == TraversalDirection.right && challenger.isLeftTo(bestNode)) {
            return challenger;
          }
          // compute the element which is the closest horizontally
          if (challenger.isOnTheSameRow(bestNode) && challenger.distance(from) < bestNode.distance(from)) {
            return challenger;
          }
          return bestNode;
        });
    }
  }

  /// Going up or down always leads to the leftmost visible element of the next row, whatever the position of the
  /// current element in its own row.
  FocusNode _leftmostVisibleOfClosestRow(List<FocusNode> candidates) {
    final closest = candidates.reduce((bestNode, challenger) {
      if (directionToSearch == TraversalDirection.down && challenger.isAbove(bestNode)) {
        return challenger;
      } else if (directionToSearch == TraversalDirection.up && challenger.isBelow(bestNode)) {
        return challenger;
      }
      return bestNode;
    });
    final row = candidates.where((node) => node.isOnTheSameRow(closest)).toList();
    final visible = row.where((node) => node.isHorizontallyVisible).toList();
    return (visible.isNotEmpty ? visible : row).reduce(
        (bestNode, challenger) => challenger.rect.left.round() < bestNode.rect.left.round() ? challenger : bestNode);
  }
}

/// An internal object to use the [NodeSearcher] class as expected
class CandidateNode {
  final FocusNode node;

  CandidateNode(this.node);
}

/// Some conversion utilities used internally
List<CandidateNode> toCandidateNodes(List<FocusNode> nodes) => nodes.map((e) => CandidateNode(e)).toList();

List<FocusNode> toFocusNodes(List<CandidateNode> nodes) => nodes.map((e) => e.node).toList();

/// A few extension methods to the [FocusNode] to be able to compare their
/// respective position easily.
extension Geometry on FocusNode {
  /// The outermost vertically scrolling ancestor, e.g. the launcher's main scroll view rather than a category grid.
  ScrollableState? get outermostVerticalScrollable {
    ScrollableState? outermost;
    var scrollable = context?.findAncestorStateOfType<ScrollableState>();
    while (scrollable != null) {
      if (axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical) {
        outermost = scrollable;
      }
      scrollable = scrollable.context.findAncestorStateOfType<ScrollableState>();
    }
    return outermost;
  }

  /// Whether the node starts within the viewport of its horizontal scroll view, if any: elements scrolled out of
  /// view, even partially, on the left are not visible.
  bool get isHorizontallyVisible {
    var scrollable = context?.findAncestorStateOfType<ScrollableState>();
    while (scrollable != null && axisDirectionToAxis(scrollable.axisDirection) != Axis.horizontal) {
      scrollable = scrollable.context.findAncestorStateOfType<ScrollableState>();
    }
    final viewport = scrollable?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) {
      return true;
    }
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    return rect.left.round() >= viewportRect.left.round() && rect.left.round() < viewportRect.right.round();
  }

  bool isBelow(FocusNode other) {
    return rect.center.dy.round() > other.rect.center.dy.round();
  }

  bool isBelowOrEquals(FocusNode other) {
    return rect.center.dy.round() >= other.rect.center.dy.round();
  }

  bool isRightTo(FocusNode other) {
    return rect.center.dx.round() > other.rect.center.dx.round();
  }

  bool isRightToOrEquals(FocusNode other) {
    return rect.center.dx.round() >= other.rect.center.dx.round();
  }

  bool isLeftTo(FocusNode other) {
    return rect.center.dx.round() < other.rect.center.dx.round();
  }

  bool isLeftToOrEquals(FocusNode other) {
    return rect.center.dx.round() <= other.rect.center.dx.round();
  }

  bool isAbove(FocusNode other) {
    return rect.center.dy.round() < other.rect.center.dy.round();
  }

  bool isAboveOrEquals(FocusNode other) {
    return rect.center.dy.round() <= other.rect.center.dy.round();
  }

  bool isOnTheSameRow(FocusNode other) {
    return rect.center.dy.round() == other.rect.center.dy.round();
  }

  double distance(FocusNode other) {
    return sqrt(pow(rect.center.dx.round() - other.rect.center.dx.round(), 2) +
        pow(rect.center.dy.round() - other.rect.center.dy.round(), 2));
  }
}
