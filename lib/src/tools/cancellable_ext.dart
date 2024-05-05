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

abstract class CancellableGroup {
  final List<Cancellable> _cancellableList = [];

  late final Cancellable _manager = Cancellable()
    ..onCancel.then((_) => _cancellableList.forEach((c) => c.cancel()));

  late final Cancellable _managerAs =
      _manager.makeCancellable(infectious: true);

  void add(Cancellable cancellable);

  Future<dynamic> get whenCancel => _manager.whenCancel;

  bool get isAvailable => _manager.isAvailable;

  bool get isUnavailable => _manager.isUnavailable;

  Future get onCancel => _manager.onCancel;

  Cancellable asCancellable() => _managerAs;
}

class CancellableEvery extends CancellableGroup {
  @override
  void add(Cancellable cancellable) {
    if (cancellable.isUnavailable || _manager.isUnavailable) return;
    _cancellableList.add(cancellable);
    cancellable.onCancel.then((value) {
      _cancellableList.remove(cancellable);
      _check();
    });
  }

  _check() {
    _cancellableList.removeWhere((e) => e.isUnavailable);
    if (_cancellableList.isEmpty) {
      _manager.cancel();
    }
  }
}

class CancellableAny extends CancellableGroup {
  @override
  void add(Cancellable cancellable) {
    if (_manager.isUnavailable) return;
    if (cancellable.isUnavailable) {
      _manager.cancel();
      return;
    }
    _cancellableList.add(cancellable);
    cancellable.onCancel.then((value) => _manager.cancel());
  }
}
