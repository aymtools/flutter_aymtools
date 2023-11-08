import 'dart:async';

// import 'package:anlifecycle/anlifecycle.dart';

extension StreamToolsExt<T> on Stream<T> {
  Stream<T> onData(void Function(T event) onData) => map((event) {
        onData(event);
        return event;
      });

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
