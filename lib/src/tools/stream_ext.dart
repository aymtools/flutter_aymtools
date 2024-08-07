import 'dart:async';

// import 'package:anlifecycle/anlifecycle.dart';

extension StreamToolsExt<T> on Stream<T> {
  Stream<T> onData(void Function(T event) onData) => map((event) {
        onData(event);
        return event;
      });

  Stream<T> repeatLatest(
      {Duration? repeatTimeout,
      T? onTimeout,
      bool repeatError = false,
      bool? broadcast}) {
    var done = false;
    T? latest;

    void Function(T value) setLatest;

    Timer? timer;
    if (repeatTimeout != null && repeatTimeout > Duration.zero) {
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
    final isBroadcast_ = broadcast ?? isBroadcast;
    return Stream.multi((controller) {
      if (done) {
        if (latest != null) {
          controller.add(latest as T);
        }
        controller.close();
        return;
      }
      currentListeners.add(controller);
      var latestValue = latest;
      if (latestValue != null) controller.add(latestValue);
      controller.onCancel = () {
        currentListeners.remove(controller);
      };
    }, isBroadcast: isBroadcast_);
  }
}
