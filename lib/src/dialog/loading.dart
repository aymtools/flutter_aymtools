import 'package:aymtools/src/dialog/navigator_ext.dart';
import 'package:aymtools/src/tools/element_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

class LoadingDialog {
  CancellableEvery? _cancellable;
  Widget Function(BuildContext context)? _builder;

  LoadingDialog._();

  static final LoadingDialog _instance = LoadingDialog._();

  static LoadingDialog get instance => _instance;

  set loading(Widget Function(BuildContext context) builder) =>
      _builder = builder;

  void showLoading(Cancellable cancellable) {
    assert(_builder != null);
    if (_builder == null) return;
    if (_cancellable?.isAvailable == true) {
      _cancellable?.add(cancellable);
      return;
    }
    _cancellable = CancellableEvery();
    assert(WidgetsBinding.instance.rootElement != null);
    final navigator = WidgetsBinding.instance.rootElement
        ?.findStateForChildren<NavigatorState>();
    navigator?.showDialog(
        builder: _builder!, cancellable: _cancellable?.asCancellable());
  }
}

abstract class CancellableGroup {
  final List<Cancellable> _cancellableList = [];

  late final Cancellable _manager = Cancellable();

  void add(Cancellable cancellable);

  Future<dynamic> get whenCancel => _manager.whenCancel;

  bool get isAvailable => _manager.isAvailable;

  bool get isUnavailable => _manager.isUnavailable;

  Future get onCancel => _manager.onCancel;

  Cancellable asCancellable() => _manager.makeCancellable(infectious: true);
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
    cancellable.onCancel.then((value) => _manager.cancel());
  }
}
