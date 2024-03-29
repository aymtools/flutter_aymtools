import 'package:flutter/widgets.dart';

List<Widget> _childList(
    List<Widget> children, IndexedWidgetBuilder separatorBuilder) {
  List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(children[i]);
    result.add(Builder(builder: (context) => separatorBuilder(context, i)));
  }
  if (result.isNotEmpty) result.removeLast();
  return result;
}

class ColumnSeparated extends Column {
  ColumnSeparated({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    IndexedWidgetBuilder? separatorBuilder,
    List<Widget> children = const [],
  }) : super(
            children: separatorBuilder == null
                ? children
                : _childList(children, separatorBuilder));

  ColumnSeparated.separatorWidget({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    Widget? separator,
    List<Widget> children = const [],
  }) : super(
            children: separator == null
                ? children
                : _childList(children, (_, __) => separator));

  ColumnSeparated.separatorSize({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    double? separatorSize,
    List<Widget> children = const [],
  }) : super(
          children: separatorSize == null || separatorSize <= 0
              ? children
              : _childList(
                  children,
                  (_, __) => SizedBox(
                    height: separatorSize,
                    // width: double.infinity,
                  ),
                ),
        );
}

class RowSeparated extends Row {
  RowSeparated({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    IndexedWidgetBuilder? separatorBuilder,
    List<Widget> children = const [],
  }) : super(
            children: separatorBuilder == null
                ? children
                : _childList(children, separatorBuilder));

  RowSeparated.separatorWidget({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    Widget? separator,
    List<Widget> children = const [],
  }) : super(
            children: separator == null
                ? children
                : _childList(children, (_, __) => separator));

  RowSeparated.separatorSize({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    double? separatorSize,
    List<Widget> children = const [],
  }) : super(
          children: separatorSize == null || separatorSize <= 0
              ? children
              : _childList(
                  children,
                  (_, __) => SizedBox(
                    width: separatorSize,
                    // height: double.infinity,
                  ),
                ),
        );
}
