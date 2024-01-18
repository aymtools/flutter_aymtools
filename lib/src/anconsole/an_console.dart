import 'package:aymtools/src/floating/draggable.dart';
import 'package:aymtools/src/navigator/observer/top_router_change.dart';
import 'package:flutter/material.dart';

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
  final List<RoutePredicate> fitter = [];

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

  void addConsole(String title, Widget content) {
    _routes.add(_ConsoleRoute(title, content));
  }

  @override
  void onTopRouteChange(Route? route) {
    assert(() {
      //仅在非release模式下显示悬浮窗
      if (route is ModalBottomSheetRoute || route is DialogRoute) {
        _toolsStatus.value = false;
      } else if (route?.settings != null && fitter.any((e) => e.call(route!))) {
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

class _AnConsoleFloatingButton extends StatelessWidget {
  final ValueNotifier<bool> toolsStatus;

  const _AnConsoleFloatingButton({super.key, required this.toolsStatus});

  // Route _findLastRoute(BuildContext context) {
  //   final history = LifecycleNavigatorObserver.getHistoryRoute(context);
  //   final currentRoute = history.lastWhere((element) => element is PageRoute);
  //   return _find(currentRoute.navigator!.context) ?? currentRoute;
  // }
  //
  // Route? _find(BuildContext context) {
  //   Route? result;
  //   context.visitChildElements((element) {
  //     if (element is StatefulElement && element.state is NavigatorState) {
  //       final history = LifecycleNavigatorObserver.getHistoryRoute(element);
  //       final r = history.lastWhereOrNull((element) => element is PageRoute);
  //       result = r;
  //     }
  //     final r = _find(element);
  //     if (r != null) {
  //       result = r;
  //     }
  //   });
  //   return result;
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FloatingDraggableButton(
      sharedPreferencesKEY: 'AnConsole',
      initOffset: Offset(size.width - MediaQuery.of(context).padding.right - 57,
          size.height * 3 / 4),
      onTap: () {
        final navigator = Navigator.of(context, rootNavigator: true);
        final overlay = navigator.overlay!;
        // final currentRoute = _findLastRoute(context) as ModalRoute;

        late OverlayEntry overlayEntry;
        late WillPopCallback callback;
        AnConsoleOverlayController controller = AnConsoleOverlayController(
          callClose: () {
            try {
              overlayEntry.remove();
            } catch (ignore) {}
            // currentRoute.removeScopedWillPopCallback(callback);
          },
        );

        callback = () {
          return controller._willPop?.call() ?? Future.value(false);
        };

        // currentRoute.addScopedWillPopCallback(callback);
        overlayEntry = OverlayEntry(
            builder: (context) => AnConsoleOverlay(controller: controller));
        overlay.insert(overlayEntry);
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: toolsStatus,
        builder: (context, value, child) {
          return value != true
              ? const Material(child: SizedBox.shrink())
              : child!;
        },
        child: SizedBox(
          width: 45,
          height: 45,
          child: Material(
            color: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            elevation: 2.0,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: const Icon(
              Icons.settings,
              color: Colors.blue,
              size: 45,
            ),
          ),
        ),
      ),
    );
  }
}

class AnConsoleOverlayController {
  final void Function() callClose;
  WillPopCallback? _willPop;

  AnConsoleOverlayController({required this.callClose});
}

class AnConsoleOverlay extends StatefulWidget {
  final AnConsoleOverlayController _controller;

  const AnConsoleOverlay(
      {super.key, required AnConsoleOverlayController controller})
      : _controller = controller;

  @override
  State<AnConsoleOverlay> createState() => _AnConsoleOverlayState();

  static void push(BuildContext context, String title, Widget content) {
    if (context is StatefulElement && context.state is _AnConsoleOverlayState) {
      (context.state as _AnConsoleOverlayState).push(title, content);
    } else {
      context
          .findAncestorStateOfType<_AnConsoleOverlayState>()
          ?.push(title, content);
    }
  }

  static void pop(BuildContext context) {
    if (context is StatefulElement && context.state is _AnConsoleOverlayState) {
      (context.state as _AnConsoleOverlayState).pop();
    } else {
      context.findAncestorStateOfType<_AnConsoleOverlayState>()?.pop();
    }
  }
}

class _AnConsoleOverlayState extends State<AnConsoleOverlay> {
  final List<_ConsoleRoute> _routes = [];
  final ValueNotifier<int> _selectedConsole = ValueNotifier(0);

  Future<bool> _willPop() async {
    if (_routes.isNotEmpty) {
      _routes.removeLast();
      setState(() {});
    } else {
      widget._controller.callClose();
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    widget._controller._willPop = _willPop;
    AnConsoleObserver.instance._onBackPressedDispatcher._willPop = _willPop;
  }

  @override
  void dispose() {
    AnConsoleObserver.instance._onBackPressedDispatcher._willPop = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnConsoleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._controller != oldWidget._controller) {
      oldWidget._controller._willPop = null;
      widget._controller._willPop = _willPop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;

    final consoles = AnConsoleObserver.instance._routes;
    return Container(
      color: Theme.of(context).disabledColor,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 2.0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: pop,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                        Expanded(
                          child: MediaQuery(
                            data: mediaQuery.copyWith(
                              padding: mediaQuery.padding.copyWith(top: 0),
                            ),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color),
                              child: SizedBox(
                                height: 22,
                                child: _routes.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(_routes.last.title),
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (_, index) =>
                                            GestureDetector(
                                          onTap: () =>
                                              _selectedConsole.value = index,
                                          child: Center(
                                            child: Text(consoles[index].title),
                                          ),
                                        ),
                                        separatorBuilder: (_, __) =>
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 12)),
                                        itemCount: consoles.length,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget._controller.callClose,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.close,
                            size: 22,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(top: 0),
                    ),
                    child: Stack(
                      children: [
                        if (_routes.isEmpty)
                          Positioned.fill(
                              child: consoles.isEmpty
                                  ? Container()
                                  : ValueListenableBuilder<int>(
                                      valueListenable: _selectedConsole,
                                      builder: (context, index, _) =>
                                          IndexedStack(
                                        index: index,
                                        children: consoles
                                            .map((e) => e.content)
                                            .toList(growable: false),
                                      ),
                                    )),
                        if (_routes.isNotEmpty)
                          Positioned.fill(child: _routes.last.content),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void push(String title, Widget content) {
    _routes.add(_ConsoleRoute(title, content));
    setState(() {});
  }

  void pop() {
    _willPop();
  }
}

class _ConsoleRoute {
  final String title;
  final Widget content;

  _ConsoleRoute(this.title, this.content);
}
