part of 'an_console.dart';

class _AnConsoleOnBackPressedDispatcher with WidgetsBindingObserver {
  WillPopCallback? _willPop;

  _AnConsoleOnBackPressedDispatcher();

  @override
  Future<bool> didPopRoute() async {
    if (_willPop == null) return false;
    return !(await _willPop!());
  }
}

class AnConsoleObserver extends NavigatorTopRouteChangeObserver {
  //某些路由下不展示的过滤器
  final List<RoutePredicate> _fitter = [];

  final ValueNotifier<bool> _toolsStatus = ValueNotifier(false);

  final List<_ConsoleRoute> _routes = [];

  final _AnConsoleOnBackPressedDispatcher _onBackPressedDispatcher =
      _AnConsoleOnBackPressedDispatcher();

  AnConsoleObserver._() {
    WidgetsBinding.instance.addObserver(_onBackPressedDispatcher);
  }

  static final AnConsoleObserver _instance = AnConsoleObserver._();

  static AnConsoleObserver get instance => _instance;

  factory AnConsoleObserver() => instance;

  void _addConsole(_ConsoleRoute route) {
    _routes.add(route);
  }

  @override
  void onTopRouteChange(Route? route) {
    assert(() {
      //仅在非release模式下显示悬浮窗
      if (route is ModalBottomSheetRoute || route is DialogRoute) {
        _toolsStatus.value = false;
      } else if (route?.settings != null && _fitter.any((e) => e.call(route!))) {
        _toolsStatus.value = false;
      } else if (route?.settings != null) {
        _toolsStatus.value = true;
        if (_btnConsole == null) {
          _btnConsole = _createFloatingButton();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_btnConsole != null) {
              navigator?.overlay?.insert(_btnConsole!);
            }
          });
        }
      }
      return true;
    }());
  }

  OverlayEntry? _btnConsole;

  OverlayEntry _createFloatingButton() {
    return OverlayEntry(
        builder: (BuildContext c) =>
            _AnConsoleFloatingButton(toolsStatus: _toolsStatus));
  }
}