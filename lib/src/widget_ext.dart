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
