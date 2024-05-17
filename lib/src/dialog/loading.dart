import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:aymtools/src/tools/cancellable_ext.dart';
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
    _cancellable!.onCancel.then((_) => _cancellable = null);
    // assert(WidgetsBinding.instance.rootElement != null);
    // final navigator = WidgetsBinding.instance.rootElement
    //     ?.findStateForChildren<NavigatorState>();
    assert(WidgetsBinding.instance.renderViewElement != null);
    final navigator = WidgetsBinding.instance.renderViewElement
        ?.findStateForChildren<NavigatorState>();
    navigator?.showDialog(
        builder: _builder!, cancellable: _cancellable?.asCancellable());
  }

  void dismissAlways() {
    if (_cancellable?.isAvailable == true) {
      _cancellable?.asCancellable().cancel();
    }
  }
}
