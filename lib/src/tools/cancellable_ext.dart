import 'package:cancellable/cancellable.dart';

extension CancellableRemake on Cancellable? {
  Cancellable cancelAndRemakeNew(
      Cancellable Function({Cancellable? father, bool infectious})
          makeCancellable) {
    this?.cancel();
    return makeCancellable();
  }
}
//
// Expando<Cancellable> _functionCancellable = Expando('_functionCancellable');
//
// extension CancellableFunction on Function {
//   bool get isCancelled => _functionCancellable[this]?.isUnavailable ?? false;
//
//
// }
