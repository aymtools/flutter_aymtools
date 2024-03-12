import 'dart:collection';

import 'package:aymtools/src/tools/element_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

import 'cancellable_timer.dart';
import 'toast_widget.dart';

class _ToastTask {
  final Widget Function(BuildContext context, int duration) builder;

  final int _duration;
  final void Function() _onFinish;
  final ToastGravity gravity;
  late final OverlayEntry _toastOverlay = _makeToastOverlay();

  bool _isFinished;

  CancellableTimer? _timer;

  bool get isActive => _timer != null && _timer!.isActive;

  _ToastTask(this.builder, this._duration, this._onFinish,
      Cancellable? cancellable, this.gravity)
      : _isFinished = false {
    cancellable?.whenCancel.then((_) => cancel());
  }

  void run(OverlayState overlayState) {
    if (_isFinished) return;
    finishTimer() {
      if (_isFinished) {
        return;
      }
      _isFinished = true;
      _onFinish.call();
      try {
        _toastOverlay.remove();
      } catch (ignore) {
        print(ignore);
      }
      _timer = null;
    }

    overlayState.insert(_toastOverlay);
    _timer = CancellableTimer(
        Duration(milliseconds: _duration), finishTimer, finishTimer);
  }

  void cancel() {
    if (_isFinished) return;
    if (_timer == null) {
      _isFinished = true;
      _onFinish.call();
    } else {
      _timer?.cancel();
    }
  }

  OverlayEntry _makeToastOverlay() {
    Widget builder(BuildContext context) {
      Widget toast =
          Builder(builder: (context) => this.builder(context, _duration));

      toast = Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: toast,
        ),
      );

      toast = Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        child: toast,
      );

      toast = SafeArea(child: toast);

      toast = IgnorePointer(
        child: toast,
      );
      switch (gravity) {
        case ToastGravity.top:
          toast =
              Positioned(top: kToolbarHeight, left: 0, right: 0, child: toast);
          break;
        case ToastGravity.center:
          break;
        case ToastGravity.bottom:
          toast = Positioned(
              bottom: kBottomNavigationBarHeight,
              left: 0,
              right: 0,
              child: toast);
          break;
      }
      return toast;
    }

    return OverlayEntry(builder: builder);
  }
}

class ToastManager {
  static const int DURATION_SHORT = 1000;
  static const int DURATION_LONG = 3000;

  ToastManager._();

  static final ToastManager _instance = ToastManager._();

  static ToastManager get instance => _instance;

  ///是否立即展示最新的toast 之前的toast将会立即结束或跳过展示
  bool immediately = true;

  ToastGravity gravity = ToastGravity.bottom;

  int duration = ToastManager.DURATION_LONG;

  final Queue<_ToastTask> _toastQueue = Queue<_ToastTask>();
  Widget Function(BuildContext context, int duration, Widget toastWidget)
      toastAnimateBuilder = (_, d, t) => AnimationToastWidget(
            animationDuration: d,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.75),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: DefaultTextStyle.merge(
                  style: TextStyle(color: Colors.white), child: t),
            ),
          );

  void showToast(Widget Function(BuildContext context, int duration) builder,
      {int? duration,
      ToastGravity? gravity,
      void Function()? onDismiss,
      Cancellable? cancellable}) {
    assert(() {
      if (duration != null && duration < 1) {
        assert(false, 'showToast duration must >0');
      }
      return true;
    }());

    late _ToastTask toast;
    taskFinish() {
      _toastQueue.remove(toast);
      onDismiss?.call();
      _peekToast();
    }

    toast = _ToastTask(builder, duration ?? this.duration, taskFinish,
        cancellable, gravity ?? this.gravity);
    _toastQueue.addLast(toast);
    _peekToast();
  }

  OverlayState? _overlayState;

  void _peekToast() {
    if (_overlayState == null || !_overlayState!.mounted) {
      _overlayState = _findOverlayState();
      if (_overlayState == null || !_overlayState!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _peekToast());
        return;
      }
    }
    if (_toastQueue.isNotEmpty) {
      var curr = _toastQueue.first;
      if (immediately && _toastQueue.length > 1) {
        curr.cancel();
      } else if (!curr.isActive) {
        curr.run(_overlayState!);
      }
    }
  }

  OverlayState? _findOverlayState() {
    final rootElement = WidgetsBinding.instance.renderViewElement;
    if (rootElement != null) {
      NavigatorState? navigator = rootElement.findStateForChildren();
      if (navigator != null && navigator.mounted) {
        return navigator.overlay;
      }
    }
    return null;
  }
}

class ToastCompanion {
  const ToastCompanion._();
}

const ToastCompanion Toast = ToastCompanion._();

extension ToastCompanionDefShow on ToastCompanion {
  void show(String message,
          {int? duration,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidget(Text(message),
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  void showWidget(Widget messageWidget,
          {int? duration,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidgetBuilder(
          (context, duration) => ToastManager.instance
              .toastAnimateBuilder(context, duration, messageWidget),
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  void showWidgetBuilder(
      Widget Function(BuildContext context, int duration) messageWidgetBuilder,
      {int? duration,
      ToastGravity? gravity,
      void Function()? onDismiss,
      Cancellable? cancellable}) {
    ToastManager.instance.showToast(messageWidgetBuilder,
        duration: duration,
        gravity: gravity,
        onDismiss: onDismiss,
        cancellable: cancellable);
  }
}

// class Toast {
//
// }

enum ToastGravity {
  top,
  center,
  bottom,
}
