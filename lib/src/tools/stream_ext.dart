import 'dart:async';

// import 'package:anlifecycle/anlifecycle.dart';

extension StreamToolsExt<T> on Stream<T> {
  Stream<T> onData(void Function(T event) onData) => map((event) {
        onData(event);
        return event;
      });

  Stream<T> repeatLatest({Duration? repeatTimeout, T? onTimeout}) {
    var done = false;
    T? latest;

    void Function(T value) setLatest;

    Timer? timer;
    if (repeatTimeout != null && repeatTimeout != Duration.zero) {
      setLatest = (value) {
        timer?.cancel();
        latest = value;
        timer = Timer(repeatTimeout, () => latest = onTimeout);
      };
    } else {
      setLatest = (v) => latest = v;
    }

    var currentListeners = <MultiStreamController<T>>{};
    listen((event) {
      setLatest(event);
      for (var listener in [...currentListeners]) {
        listener.addSync(event);
      }
    }, onError: (Object error, StackTrace stack) {
      for (var listener in [...currentListeners]) {
        listener.addErrorSync(error, stack);
      }
    }, onDone: () {
      done = true;
      timer?.cancel();
      latest = null;
      for (var listener in [...currentListeners]) {
        listener.closeSync();
      }
      currentListeners.clear();
    });
    return Stream.multi((controller) {
      if (done) {
        controller.close();
        return;
      }
      currentListeners.add(controller);
      var latestValue = latest;
      if (latestValue != null) controller.add(latestValue);
      controller.onCancel = () {
        currentListeners.remove(controller);
      };
    });
  }

// Stream<T> bindLifecycle(LifecycleObserverRegister register,
//     {LifecycleState state = LifecycleState.started,
//     bool repeatLastOnRestart = false}) {
//
//   final transformer =
//       StreamTransformer<T, T>.fromHandlers(handleData: (data, sink) {
//     if (register.currentLifecycleState >= state) {
//       sink.add(data);
//     }
//   });
//
//   StreamTransformer.fromBind((p0) => null)
//   return transform(transformer);
// }
}
