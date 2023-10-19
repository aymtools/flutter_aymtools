import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

import 'expando_ext.dart';

typedef VoidCallBack = void Function();

class SingleListenerManager {
  final WeakSet<VoidCallBack> functions = WeakSet();

  void callback() => functions.forEach((element) => element.call());

  SingleListenerManager();
}

Expando<SingleListenerManager> _singleListener = Expando('_singleListener');
Expando<VoidCallBack> _listenerConvert = Expando('_listenerConvert');

Expando<Stream> _valueNotifierStream = Expando('_valueNotifierStream');

extension ListenableCancellable on Listenable {
  void addCListener(Cancellable cancellable, VoidCallback listener) {
    if (cancellable.isUnavailable) return;

    notifierCallback() {
      if (cancellable.isAvailable) listener();
    }

    addListener(notifierCallback);
    cancellable.whenCancel.then((value) => removeListener(notifierCallback));
  }

  void addCSListener(Cancellable cancellable, VoidCallback listener) {
    if (cancellable.isUnavailable) return;

    final sl = _singleListener.getOrPut(this, defaultValue: () {
      final r = SingleListenerManager();
      addListener(r.callback);
      return r;
    });

    final l = _listenerConvert.getOrPut(listener,
        defaultValue: () => () {
              if (cancellable.isAvailable) listener();
            });

    sl.functions.add(l);
    cancellable.whenCancel.then((value) => sl.functions.remove(l));
  }
}

extension ChangeNotifierCancellable on ChangeNotifier {
  void disposeByCancellable(Cancellable cancellable) {
    cancellable.whenCancel.then((_) => dispose());
  }
}

extension ValueNotifierCancellable<T> on ValueNotifier<T> {
  void addCVListener(Cancellable cancellable, void Function(T value) listener) {
    if (cancellable.isUnavailable) return;

    notifierCallback() {
      if (cancellable.isAvailable) listener(value);
    }

    addListener(notifierCallback);
    cancellable.whenCancel.then((value) => removeListener(notifierCallback));
  }

  void addCSVListener(
      Cancellable cancellable, void Function(T value) listener) {
    if (cancellable.isUnavailable) return;

    final sl = _singleListener.getOrPut(this, defaultValue: () {
      final r = SingleListenerManager();
      addListener(r.callback);
      return r;
    });

    final l = _listenerConvert.getOrPut(listener,
        defaultValue: () => () {
              if (cancellable.isAvailable) listener(value);
            });

    sl.functions.add(l);
    cancellable.whenCancel.then((value) => sl.functions.remove(l));
  }

  Stream<T> asStream({Cancellable? cancellable}) {
    Stream<T>? result = _valueNotifierStream[this] as Stream<T>?;
    if (result == null) {
      var listeners = <MultiStreamController<T>>{};
      result = Stream.multi((controller) {
        if (cancellable?.isUnavailable == true) {
          controller.close();
          return;
        }
        listeners.add(controller);
        controller.add(value);
        controller.onCancel = () {
          listeners.remove(controller);
        };
      });
      if (cancellable != null) {
        cancellable.onCancel.then((value) {
          for (var l in listeners) {
            l.closeSync();
          }
        });
        addCVListener(cancellable, (value) {
          for (var l in listeners) {
            l.add(value);
          }
        });
      } else {
        addListener(() {
          for (var l in listeners) {
            l.add(value);
          }
        });
      }
      _valueNotifierStream[this] = result;
    }

    return result;
  }

  Future<T> whenValue(bool Function(T value) test, {Cancellable? cancellable}) {
    final v = value;
    if (test(v)) {
      return Future.value(v);
    }

    Completer<T> completer = Completer();
    if (cancellable == null || cancellable.isAvailable) {
      Cancellable c =
          cancellable?.makeCancellable(infectious: true) ?? Cancellable();
      addCSVListener(c, (value) {
        final v = value;
        if (test(v)) {
          completer.complete(v);
          c.cancel();
        }
      });
    }
    return completer.future;
  }
}
