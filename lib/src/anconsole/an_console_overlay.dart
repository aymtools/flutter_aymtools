part of 'an_console.dart';

class _AnConsoleOverlay extends StatefulWidget {
  final AnConsoleOverlayController _controller;

  const _AnConsoleOverlay(
      {super.key, required AnConsoleOverlayController controller})
      : _controller = controller;

  @override
  State<_AnConsoleOverlay> createState() => _AnConsoleOverlayState();
}

class _AnConsoleOverlayState extends State<_AnConsoleOverlay>
    with TickerProviderStateMixin {
  final List<_ConsoleRoute> _routes = [];

  late final TabController _controller = TabController(
      length: AnConsoleObserver.instance._routes.length,
      vsync: this,
      animationDuration: Duration.zero,
      initialIndex: 0);

  late final _ConsoleRoute initRoute = _ConsoleRoute(
      _InitRouteTitle(controller: _controller),
      _InitRoute(controller: _controller));

  Future<bool> _willPop([dynamic result]) async {
    if (_routes.isNotEmpty) {
      final route = _routes.removeLast();
      route.completer.complete(result);
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
    AnConsole.instance._overlayState = this;
  }

  @override
  void dispose() {
    AnConsoleObserver.instance._onBackPressedDispatcher._willPop = null;
    AnConsole.instance._overlayState = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AnConsoleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._controller != oldWidget._controller) {
      oldWidget._controller._willPop = null;
      widget._controller._willPop = _willPop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget title = _routes.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
                alignment: Alignment.centerLeft, child: _routes.last.title),
          )
        : RepaintBoundary(child: initRoute.title);

    final content = IndexedStack(
      index: _routes.length,
      sizing: StackFit.expand,
      children: [
        RepaintBoundary(child: initRoute.content),
        ..._routes.map((e) => RepaintBoundary(child: e.content)),
      ],
    );

    return _AnConsoleOverlayGroup(
      title: title,
      content: content,
      controller: widget._controller,
    );
  }

  Future<T?> push<T>(String title, Widget content) {
    final route = _ConsoleRoute<T>(Text(title, maxLines: 1), content);
    _routes.add(route);
    setState(() {});
    return route.completer.future;
  }

  void pop([dynamic result]) {
    _willPop(result);
  }

  Future<bool> showConfirm({
    String? title,
    required String content,
    String? ok,
    String? cancel,
  }) {
    return Future(() => false);
  }

  void showToast(String message) {}

  Future<T?> showOptionSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    T? selected,
    String? cancel,
  }) {
    return Future(() => selected);
  }

  Future<List<T>?> showOptionMultiSelect<T>({
    String? title,
    required List<T> options,
    required String Function(T option) displayToStr,
    List<T>? selected,
    String? cancel,
  }) {
    return Future(() => selected);
  }
}

class _ConsoleRoute<T> {
  final Widget title;
  final Widget content;
  final Completer<T?> completer = Completer();

  _ConsoleRoute(this.title, this.content);
}
