import 'dart:js';

import 'package:flutter/material.dart';

NullableIndexedWidgetBuilder _sliverChildBuilderDelegate(
    NullableIndexedWidgetBuilder itemBuilder,
    IndexedWidgetBuilder separatorBuilder) {
  build(context, index) {
    final int itemIndex = index ~/ 2;
    final Widget? widget;
    if (index.isEven) {
      widget = itemBuilder(context, itemIndex);
    } else {
      widget = separatorBuilder(context, itemIndex);
      assert(() {
        if (widget == null) {
          throw FlutterError('separatorBuilder cannot return null.');
        }
        return true;
      }());
    }
    return widget;
  }

  return build;
}

class SliverChildSeparatedBuilderDelegate extends SliverChildBuilderDelegate {
  SliverChildSeparatedBuilderDelegate({
    required NullableIndexedWidgetBuilder builder,
    required IndexedWidgetBuilder separatorBuilder,
    int? childCount,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
  }) : super(
          _sliverChildBuilderDelegate(builder, separatorBuilder),
          childCount: childCount == null ? null : childCount * 2 - 1,
        );
}

List<Widget> _sliverChildListDelegate(
    List<Widget> children, IndexedWidgetBuilder separatorBuilder) {
  List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    result.add(Builder(builder: (context) => separatorBuilder(context, i)));
  }
  if (result.isNotEmpty) result.removeLast();
  return result;
}

class SliverChildSeparatedListDelegate extends SliverChildListDelegate {
  SliverChildSeparatedListDelegate(
    List<Widget> children, {
    required IndexedWidgetBuilder separatorBuilder,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
  }) : super(_sliverChildListDelegate(children, separatorBuilder));
}
