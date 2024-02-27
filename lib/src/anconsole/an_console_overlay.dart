part of 'an_console.dart';

class _AnConsoleOverlay extends StatefulWidget {
  final AnConsoleOverlayController _controller;

  const _AnConsoleOverlay(
      {super.key, required AnConsoleOverlayController controller})
      : _controller = controller;

  @override
  State<_AnConsoleOverlay> createState() => _AnConsoleOverlayState();
}

class _AnConsoleOverlayState extends State<_AnConsoleOverlay> {
  final List<_ConsoleRoute> _routes = [];
  final ValueNotifier<int> _selectedConsole = ValueNotifier(0);
  late final _ConsoleRoute initRoute;

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

  Widget _initRouteTitle() {
    final consoles = AnConsoleObserver.instance._routes;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => _selectedConsole.value = index,
        child: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: _selectedConsole,
            builder: (context, selectedIndex, _) => DefaultTextStyle.merge(
                style: TextStyle(
                    color: selectedIndex == index ? Colors.blue : null),
                maxLines: 1,
                child: consoles[index].title),
          ),
        ),
      ),
      separatorBuilder: (_, __) =>
          const Padding(padding: EdgeInsets.only(left: 12)),
      itemCount: consoles.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _initRouteContent() {
    final consoles = AnConsoleObserver.instance._routes;
    return consoles.isEmpty
        ? Container()
        : ValueListenableBuilder<int>(
            valueListenable: _selectedConsole,
            builder: (context, index, _) => IndexedStack(
              index: index,
              children: consoles.map((e) => e.content).toList(growable: false),
            ),
          );
  }

  @override
  void initState() {
    super.initState();
    initRoute = _ConsoleRoute(
        _initRouteTitle(), _InitRoute(selectedConsole: _selectedConsole));

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
        : RepaintBoundary(child: initRoute.content);

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
}

class _ConsoleRoute<T> {
  final Widget title;
  final Widget content;
  final Completer<T?> completer = Completer();

  _ConsoleRoute(this.title, this.content);
}
