import 'dart:core';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:aymtools/src/lifecycle/lifecycle_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

// abstract class ICancellableState<W extends StatefulWidget> {
//   Cancellable makeCancellable();
// }

mixin CancellableState<W extends StatefulWidget> on State<W> {
  Cancellable? _base;

  Cancellable makeCancellable({Cancellable? father}) {
    _base ??= this is LifecycleObserverRegisterMixin
        ? (this as LifecycleObserverRegisterMixin).makeLiveCancellable()
        : Cancellable();
    return _base!.makeCancellable(father: father);
  }

  Cancellable? _changeDependenciesCancellable;
  Set<void Function(Cancellable cancellable)>? _onChangeDependencies;

  void registerOnChangeDependencies(
      void Function(Cancellable cancellable) listener) {
    if (_onChangeDependencies == null) {
      _onChangeDependencies = {};
      makeCancellable().onCancel.then((value) {
        _onChangeDependencies?.clear();
        _onChangeDependencies = null;
      });
    }
    if (_changeDependenciesCancellable != null) {
      listener(_changeDependenciesCancellable!.makeCancellable());
    }
    _onChangeDependencies!.add(listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_onChangeDependencies != null) {
      _changeDependenciesCancellable?.cancel();
      _changeDependenciesCancellable = makeCancellable();
      final listeners = List.of(_onChangeDependencies!, growable: false);
      for (var l in listeners) {
        l(_changeDependenciesCancellable!.makeCancellable());
      }
    }
  }

  Set<void Function(W widget, W oldWidget)>? _onUpdateWidget;

  void registerOnUpdateWidget(void Function(W widget, W oldWidget) listener) {
    if (_onUpdateWidget == null) {
      _onUpdateWidget = {};
      makeCancellable().onCancel.then((value) {
        _onUpdateWidget?.clear();
        _onUpdateWidget = null;
      });
    }
    _onUpdateWidget!.add(listener);
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_onUpdateWidget != null && _onUpdateWidget!.isNotEmpty) {
      final listeners = List.of(_onUpdateWidget!, growable: false);
      for (var l in listeners) {
        l(widget, oldWidget);
      }
    }
  }

  @override
  void dispose() {
    _base?.cancel();
    super.dispose();
  }
}

// mixin DispatchEventState<W extends StatefulWidget> on State<W>
//     implements ICancellableState<W> {
//   Cancellable makeCancellable();
//
//   Cancellable? _changeDependenciesCancellable;
//
//   Set<void Function(Cancellable cancellable)> _onChangeDependencies = {};
//
//   Set<void Function(W widget, W oldWidget)> _onUpdateWidget = {};
//
//   void registerOnChangeDependencies(
//       void Function(Cancellable cancellable) listener) {
//     if (_changeDependenciesCancellable != null) {
//       listener(_changeDependenciesCancellable!.makeCancellable());
//     }
//     _onChangeDependencies.add(listener);
//   }
//
//   void registerOnUpdateWidget(void Function(W widget, W oldWidget) listener) {
//     _onUpdateWidget.add(listener);
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     _changeDependenciesCancellable?.cancel();
//     _changeDependenciesCancellable = makeCancellable();
//     if (_onChangeDependencies.isEmpty) return;
//     final listeners = List.of(_onChangeDependencies, growable: false);
//     for (var l in listeners) {
//       l(_changeDependenciesCancellable!.makeCancellable());
//     }
//   }
//
//   @override
//   void didUpdateWidget(covariant W oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (_onUpdateWidget.isEmpty) return;
//     final listeners = List.of(_onUpdateWidget, growable: false);
//     for (var l in listeners) {
//       l(widget, oldWidget);
//     }
//   }
//
//   @override
//   void dispose() {
//     _onChangeDependencies.clear();
//     _onUpdateWidget.clear();
//     super.dispose();
//   }
// }
//
// mixin LoaderState<W extends StatefulWidget> on DispatchEventState<W> {
//   Cancellable? _loading;
//
//   @override
//   void initState() {
//     super.initState();
//     registerOnUpdateWidget((widget, oldWidget) {
//       if (checkNeedReload(oldWidget)) {
//         _loading?.cancel();
//         _reload();
//       }
//     });
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_loading == null) {
//       _reload();
//     }
//   }
//
//   void _reload() {
//     _loading = makeCancellable();
//     loadData(_loading!);
//   }
//
//   bool checkNeedReload(covariant W oldWidget);
//
//   void loadData(Cancellable cancellable);
// }
