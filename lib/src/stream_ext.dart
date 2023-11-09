import 'dart:async';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:aymtools/src/lifecycle_ext.dart';

extension StreamToolsExt<T> on Stream<T> {
  Stream<T> onData(void Function(T event) onData) => map((event) {
        onData(event);
        return event;
      });

  Stream<T> bindLifecycle(LifecycleObserverRegister register,
      {LifecycleState state = LifecycleState.started,
      int repeatCacheSize = 1}) {
    List<T> cache;
    if (repeatCacheSize < 0) {
      repeatCacheSize = 0;
      cache = List.empty();
    } else {
      cache = [];
    }

    EventSink<T>? sinkCache;

    final transformer =
        StreamTransformer<T, T>.fromHandlers(handleData: (data, sink) {
      if (register.currentLifecycleState >= state) {
        sink.add(data);
      } else if (repeatCacheSize > 0) {
        sinkCache ??= sink;
        cache.add(data);
      }
    });

    register.repeatOnLifecycle(state, (cancellable) {
      if (sinkCache != null && cache.isNotEmpty) {
        for (var element in cache) {
          sinkCache?.add(element);
        }
        cache.clear();
      }
    });

    return transform(transformer);
  }
}
