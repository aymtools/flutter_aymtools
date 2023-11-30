import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

mixin CancellableState<W extends StatefulWidget> on State<W> {
  final Cancellable _base = Cancellable();

  Cancellable makeCancellable({Cancellable? father, bool infectious = false}) =>
      _base.makeCancellable(father: father, infectious: infectious);

  @override
  void dispose() {
    _base.cancel();
    super.dispose();
  }
}

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
}
