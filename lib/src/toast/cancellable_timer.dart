import 'dart:async';

class CancellableTimer implements Timer {
  final void Function() onCancel;

  final Timer timer;

  CancellableTimer(Duration duration, void Function() callback, this.onCancel)
      : timer = Timer(duration, callback);

  @override
  void cancel() {
    timer.cancel();
    onCancel();
  }

  @override
  bool get isActive => timer.isActive;

  @override
  int get tick => timer.tick;
}
