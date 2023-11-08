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
  }) : super(
          _sliverChildBuilderDelegate(builder, separatorBuilder),
          childCount: childCount == null ? null : childCount * 2 - 1,
        );
}
