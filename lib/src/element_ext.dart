import 'package:flutter/widgets.dart';

extension ElementExt on Element {
  T? findStateForChildren<T extends State>() => _findStateForChildren(this);

  T? _findStateForChildren<T extends State>(Element element) {
    if (element is StatefulElement && element.state is T) {
      return element.state as T;
    }
    T? target;
    element.visitChildElements((e) => target ??= _findStateForChildren(e));
    return target;
  }

  T? findElementForChildren<T extends Element>() =>
      _findElementForChildren(this);

  T? _findElementForChildren<T extends Element>(Element element) {
    if (element is T) {
      return element;
    }
    T? target;
    element.visitChildElements((e) => target ??= _findElementForChildren(e));
    return target;
  }
}
