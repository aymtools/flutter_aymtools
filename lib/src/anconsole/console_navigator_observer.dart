part of 'console.dart';

class _OnBackPressedDispatcher with WidgetsBindingObserver {
  WillPopCallback? _willPop;
  final List<WillPopCallback> _willPops = [];

  void addWillPopCallback(WillPopCallback callback) {
    _willPops.add(callback);
  }

  void removerWillPopCallback(WillPopCallback callback) {
    _willPops.remove(callback);
  }

  _OnBackPressedDispatcher();

  @override
  Future<bool> didPopRoute() async {
    if (_willPops.isNotEmpty) {
      for (var fun in _willPops.reversed) {
        if (await fun.call() == true) {
          return true;
        }
      }
    }

    if (_willPop == null) return false;
    return !(await _willPop!());
  }
}

_OnBackPressedDispatcher? _hookedOnBackPressedDispatcher;

_hookOnBackPressed() {
  if (_hookedOnBackPressedDispatcher == null) return;
  try {
    final dispatcher = _OnBackPressedDispatcher();
    WidgetsBinding.instance.addObserver(dispatcher);
    _hookedOnBackPressedDispatcher = dispatcher;
  } catch (_) {}
}

class ConsoleNavigatorObserver extends NavigatorTopRouteChangeObserver {
  //某些路由下不展示的过滤器
  final List<RoutePredicate> _fitter = [];

  final ValueNotifier<bool> _toolsStatus = ValueNotifier(false);

  final List<_ConsoleRoute> _routes = [];

  //
  // final _OnBackPressedDispatcher _onBackPressedDispatcher =
  //     _OnBackPressedDispatcher();

  ConsoleNavigatorObserver._() {
    // WidgetsBinding.instance.addObserver(_onBackPressedDispatcher);
  }

  static final ConsoleNavigatorObserver _instance =
      ConsoleNavigatorObserver._();

  void _addConsole(_ConsoleRoute route) {
    _routes.add(route);
  }

  @override
  void onTopRouteChange(Route? route) {
    if (!AnConsole.instance.isEnable) return;
    if (route is ModalBottomSheetRoute || route is DialogRoute) {
      _toolsStatus.value = false;
    } else if (route?.settings != null && _fitter.any((e) => e.call(route!))) {
      _toolsStatus.value = false;
    } else if (route?.settings != null) {
      _toolsStatus.value = true;
      if (_btnConsole == null && _routes.isNotEmpty) {
        _btnConsole = _createFloatingButton();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_btnConsole != null) {
            navigator?.overlay?.insert(_btnConsole!);
          }
        });
      }
    }
  }

  OverlayEntry? _btnConsole;

  OverlayEntry _createFloatingButton() {
    return OverlayEntry(
        builder: (BuildContext c) =>
            _ConsoleFloatingButton(toolsStatus: _toolsStatus));
  }
}
