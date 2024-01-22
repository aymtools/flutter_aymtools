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

  static void push(BuildContext context, String title, Widget content) {
    _AnConsoleOverlay.push(context, title, content);
  }

  static void pop(BuildContext context) {
    _AnConsoleOverlay.pop(context);
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
}

class AnConsoleOverlayController {
  final void Function() callClose;
  WillPopCallback? _willPop;

  AnConsoleOverlayController({required this.callClose});
}
