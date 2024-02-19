import 'dart:async';
import 'package:aymtools/src/floating/draggable.dart';
import 'package:aymtools/src/navigator/observer/top_router_change.dart';
import 'package:flutter/material.dart';

part 'an_console_floatting.dart';

part 'an_console_navigator_observer.dart';

part 'an_console_overlay.dart';

class AnConsole {
  AnConsole._();

  static final AnConsole _instance = AnConsole._();

  static AnConsole get instance => _instance;

  _AnConsoleOverlayState? _overlayState;

  static Future<T?> push<T>(String title, Widget content) {
    assert(instance._overlayState != null);
    return instance._overlayState!.push(title, content);
  }

  static void pop([dynamic result]) {
    instance._overlayState?.pop(result);
  }

  final List<_ConsoleRoute> _console = [];
  final List<RoutePredicate> _doNotShowUp = [];

  AnConsoleObserver? _navigatorObserver;

  AnConsoleObserver get navigatorObserver {
    if (_navigatorObserver == null) {
      AnConsoleObserver observer = AnConsoleObserver.instance;
      _console.forEach(observer._addConsole);
      observer._fitter.addAll(_doNotShowUp);
      _navigatorObserver = observer;
    }
    return _navigatorObserver!;
  }

  void addConsole(String title, Widget content) {
    final route = _ConsoleRoute(title, content);
    _console.add(route);
    _navigatorObserver?._addConsole(route);
  }

  void addNotShowUpRoute(RoutePredicate predicate) {
    _doNotShowUp.add(predicate);
    _navigatorObserver?._fitter.add(predicate);
  }

  bool _isEnable = () {
    bool flag = false;
    assert(() {
      flag = true;
      return true;
    }());
    return flag;
  }();

  bool get isEnable => _isEnable;

  /// 工具的模式 1:一直启用 2:一直不启用  other:非release下启用
  set floatingMode(int mode) {
    switch (mode) {
      case 1:
        _isEnable = true;
        break;
      case 2:
        _isEnable = false;
        break;
      default:
        _isEnable = false;
        assert(() {
          _isEnable = true;
          return true;
        }());
    }
  }
}

class AnConsoleOverlayController {
  final void Function() callClose;
  WillPopCallback? _willPop;

  AnConsoleOverlayController({required this.callClose});
}
