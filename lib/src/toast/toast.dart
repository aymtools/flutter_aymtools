import 'dart:collection';

import 'package:aymtools/src/tools/element_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';

import 'cancellable_timer.dart';

class _ToastTask {
  final WidgetBuilder builder;

  final int _duration;
  final void Function() _onFinish;
  final ToastGravity gravity;
  late final OverlayEntry _toastOverlay = _makeToastOverlay();

  bool _isFinished;

  CancellableTimer? _timer;

  bool get isActive => _timer != null;

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
      } catch (ignore) {}
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
      Widget toast = Builder(builder: (context) => this.builder(context));

      toast = Material(child: toast);

      final safePadding = MediaQuery.of(context).padding;

      toast = Padding(
        padding: EdgeInsets.only(
          left: safePadding.left + kFloatingActionButtonMargin,
          right: safePadding.right + kFloatingActionButtonMargin,
        ),
      );
      switch (gravity) {
        case ToastGravity.top:
          toast =
              Positioned(top: kToolbarHeight + safePadding.top, child: toast);
          break;
        case ToastGravity.center:
          break;
        case ToastGravity.bottom:
          toast = Positioned(
              bottom: kBottomNavigationBarHeight + safePadding.bottom,
              child: toast);
          break;
      }
      return toast;
    }

    return OverlayEntry(builder: builder);
  }
}

class ToastManager {
  ToastManager._();

  static ToastManager get instance => ToastManager._();

  ///是否立即展示最新的toast 之前的toast将会立即结束或跳过展示
  bool immediately = true;

  ToastGravity gravity = ToastGravity.bottom;

  final Queue<_ToastTask> _toastQueue = Queue<_ToastTask>();

  void showToast(WidgetBuilder builder,
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

    toast = _ToastTask(builder, duration ?? 1000, taskFinish, cancellable,
        gravity ?? this.gravity);
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
        _toastQueue.first.cancel();
      } else if (!curr.isActive) {
        _toastQueue.first.run(_overlayState!);
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

class Toast {
  static const int TOAST_DURATION_SHORT = 1000;
  static const int TOAST_DURATION_LONG = 3000;

  static void show(String message,
          {int duration = TOAST_DURATION_SHORT,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidget(Text(message),
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  static void showWidget(Widget messageWidget,
          {int duration = TOAST_DURATION_SHORT,
          ToastGravity? gravity,
          void Function()? onDismiss,
          Cancellable? cancellable}) =>
      showWidgetBuilder((context) => messageWidget,
          duration: duration,
          gravity: gravity,
          onDismiss: onDismiss,
          cancellable: cancellable);

  static void showWidgetBuilder(WidgetBuilder messageWidgetBuilder,
      {int duration = TOAST_DURATION_SHORT,
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

enum ToastGravity {
  top,
  center,
  bottom,
}
