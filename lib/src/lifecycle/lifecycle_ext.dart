import 'dart:async';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

extension LifecycleObserverRegisterX on LifecycleObserverRegister {
  Future<LifecycleState> whenMoreThanState(LifecycleState state) =>
      currentLifecycleState >= LifecycleState.started
          ? Future.value(currentLifecycleState)
          : nextLifecycleState(LifecycleState.started);

  Future<LifecycleEvent> whenFirstStart() =>
      whenMoreThanState(LifecycleState.started)
          .then((value) => LifecycleEvent.start);

  Future<LifecycleEvent> whenFirstResume() =>
      whenMoreThanState(LifecycleState.resumed)
          .then((value) => LifecycleEvent.resume);
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

final Map<LifecycleObserverRegister, _CacheMapObserver> _map = {};

class _CacheMapObserver with LifecycleEventDefaultObserver {
  final Cancellable _cancellable;
  final LifecycleObserverRegister registerMixin;

  Cancellable _makeCancellableForLive({Cancellable? other}) =>
      _cancellable.makeCancellable(infectious: false, father: other);

  _CacheMapObserver(this.registerMixin) : _cancellable = Cancellable() {
    registerMixin.registerLifecycleObserver(this, fullCycle: true);
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
    assert(
        currentLifecycleState > LifecycleState.destroyed, '必须在destroyed之前使用');
    return _map
        .putIfAbsent(this, () => _CacheMapObserver(this))
        ._makeCancellableForLive(other: other);
  }

  void repeatOnLifecycle<T>(
      {LifecycleState targetState = LifecycleState.started,
      required FutureOr<T> Function(Cancellable cancellable) block}) {
    Cancellable? cancellable;
    final observer = LifecycleObserver.stateChange((state) {
      if (state >= targetState &&
          (cancellable == null || cancellable?.isUnavailable == true)) {
        cancellable = makeLiveCancellable();
        try {
          block(cancellable!);
        } catch (_) {}
      } else if (state < targetState && cancellable?.isAvailable == true) {
        cancellable?.cancel();
        cancellable = null;
      }
    });
    registerLifecycleObserver(observer, fullCycle: true);
  }

  Stream<T> repeatOnLifecycleCollect<T>(
      {LifecycleState targetState = LifecycleState.started,
      required FutureOr<T> Function(Cancellable cancellable) block}) {
    StreamController<T> controller = StreamController();
    controller.closeByCancellable(makeLiveCancellable());
    repeatOnLifecycle(block: (cancellable) async {
      if (!controller.isClosed) {
        try {
          final b = await block(cancellable);
          controller.add(b);
        } catch (_) {}
      }
    });
    return controller.stream;
  }
}

extension StreamLifecycleExt<T> on Stream<T> {
  Stream<T> bindLifecycle(LifecycleObserverRegister register,
      {LifecycleState state = LifecycleState.started,
      bool repeatLastOnRestart = false}) {
    StreamTransformer<T, T> transformer;
    if (repeatLastOnRestart) {
      T? cache;
      EventSink<T>? eventSink;
      transformer =
          StreamTransformer<T, T>.fromHandlers(handleData: (data, sink) {
        if (register.currentLifecycleState >= state) {
          cache = null;
          eventSink = null;
          sink.add(data);
        } else if (repeatLastOnRestart) {
          cache = data;
          eventSink = sink;
        }
      });
      register.repeatOnLifecycle(block: (Cancellable cancellable) {
        if (cache != null && eventSink != null) {
          eventSink?.add(cache as T);
        }
      });
    } else {
      transformer =
          StreamTransformer<T, T>.fromHandlers(handleData: (data, sink) {
        if (register.currentLifecycleState >= state) {
          sink.add(data);
        }
      });
    }

    return bindCancellable(register.makeLiveCancellable(),
            closeWhenCancel: false)
        .transform(transformer);
  }
}
