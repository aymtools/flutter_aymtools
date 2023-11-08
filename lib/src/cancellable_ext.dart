import 'package:cancellable/cancellable.dart';

extension CancellableRemake on Cancellable? {
  Cancellable cancelAndRemakeNew(
      Cancellable Function({Cancellable? father, bool infectious})
          makeCancellable) {
    this?.cancel();
    return makeCancellable();
  }
}
