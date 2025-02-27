import 'dart:core';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

@Deprecated('Use package:ffx XState')
mixin CancellableState<W extends StatefulWidget> on State<W> {
  Cancellable? _base;

  Cancellable makeCancellable({Cancellable? father}) {
    _base ??= this is ILifecycleRegistry
        ? (this as ILifecycleRegistry).makeLiveCancellable()
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

extension LazyByRoute on State {
  T lazyByRout<T>() {
    return ModalRoute.of(context)!.settings.arguments as T;
  }

  T lazyByRoute<T, I>({required T Function(I arguments) block}) {
    return block(ModalRoute.of(context)!.settings.arguments as I);
  }

  T lazyByRouteMap<T>({required T Function(Map arguments) block}) {
    return lazyByRoute<T, Map>(block: block);
  }
}
