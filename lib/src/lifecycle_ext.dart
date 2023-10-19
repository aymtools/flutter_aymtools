import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

extension LifecycleObserverRegisterX on LifecycleObserverRegister {
  Future<LifecycleState> whenMoreThanState(LifecycleState state) =>
      currentLifecycleState >= LifecycleState.started
          ? Future.value(currentLifecycleState)
          : nextLifecycleState(LifecycleState.started);
}

extension LifecycleObserverRegisterMixinContextExt
    on LifecycleObserverRegisterMixin {
  Future<BuildContext> get requiredContext =>
      whenMoreThanState(LifecycleState.started).then((_) => context);

  Future<S> requiredState<S extends State>() => requiredContext.then((value) {
        if (value is StatefulElement && value.state is S) {
          return value.state as S;
        }
        return Future<S>.value(value.findAncestorStateOfType<S>());
      });
}

extension LifecycleOwnerStateMixinContextExt on LifecycleOwnerStateMixin {
  Future<BuildContext> get requiredContext =>
      whenMoreThanState(LifecycleState.started).then((_) => context);

  Future<S> requiredState<S extends State>() => requiredContext.then((value) {
        if (value is StatefulElement && value.state is S) {
          return value.state as S;
        }
        return Future<S>.value(value.findAncestorStateOfType<S>());
      });
}

final Map<LifecycleObserverRegister, _CacheMapObserver> _map = {};

class _CacheMapObserver with LifecycleEventDefaultObserver {
  final Cancellable _cancellable;
  final LifecycleObserverRegister registerMixin;

  Cancellable _makeCancellableForLive({Cancellable? other}) =>
      _cancellable.makeCancellable(infectious: false, father: other);

  _CacheMapObserver(this.registerMixin) : _cancellable = Cancellable() {
    registerMixin.registerLifecycleObserver(this);
    _cancellable.onCancel.then((value) => _map.remove(this));
  }

  @override
  void onDestroy(LifecycleOwner owner) {
    super.onDestroy(owner);
    _cancellable.cancel();
  }
}

extension LifecycleObserverRegisterCacnellable on LifecycleObserverRegister {
  Cancellable makeLiveCancellable({Cancellable? other}) {
    assert(currentLifecycleState > LifecycleState.destroyed,
        '必须在created后且非destroyed之前使用');
    return _map
        .putIfAbsent(this, () => _CacheMapObserver(this))
        ._makeCancellableForLive(other: other);
  }
}
