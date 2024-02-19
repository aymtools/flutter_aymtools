part of 'an_console.dart';

class _AnConsoleOverlay extends StatefulWidget {
  final AnConsoleOverlayController _controller;

  const _AnConsoleOverlay(
      {super.key, required AnConsoleOverlayController controller})
      : _controller = controller;

  @override
  State<_AnConsoleOverlay> createState() => _AnConsoleOverlayState();

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

class _AnConsoleOverlayState extends State<_AnConsoleOverlay> {
  final List<_ConsoleRoute> _routes = [];
  final ValueNotifier<int> _selectedConsole = ValueNotifier(0);

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
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;

    final consoles = AnConsoleObserver.instance._routes;
    return Container(
      color: Theme
          .of(context)
          .disabledColor,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Material(
            color: Theme
                .of(context)
                .scaffoldBackgroundColor,
            elevation: 2.0,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SafeArea(
              top: false,
              bottom: false,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  padding: mediaQuery.padding.copyWith(top: 0),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: pop,
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: Theme
                                  .of(context)
                                  .iconTheme
                                  .color,
                            ),
                          ),
                          Expanded(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  color: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color),
                              child: SizedBox(
                                height: 22,
                                width: double.infinity,
                                child: _routes.isNotEmpty
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _routes.last.title,
                                        maxLines: 1,
                                      )),
                                )
                                    : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (_, index) =>
                                      GestureDetector(
                                        onTap: () =>
                                        _selectedConsole.value = index,
                                        child: Center(
                                          child: ValueListenableBuilder<int>(
                                            valueListenable: _selectedConsole,
                                            builder: (context, selectedIndex,
                                                _) =>
                                                Text(consoles[index].title,
                                                    style: TextStyle(
                                                        color:
                                                        selectedIndex ==
                                                            index
                                                            ? Colors.blue
                                                            : null),
                                                    maxLines: 1),
                                          ),
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
                          GestureDetector(
                            onTap: widget._controller.callClose,
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.close,
                              size: 22,
                              color: Theme
                                  .of(context)
                                  .iconTheme
                                  .color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 0.5,
                      color: Theme
                          .of(context)
                          .dividerColor,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _routes.length,
                        sizing: StackFit.expand,
                        children: [
                          consoles.isEmpty
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
                          ),
                          ..._routes.map((e) => e.content),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<T?> push<T>(String title, Widget content) {
    final route = _ConsoleRoute<T>(title, content);
    _routes.add(route);
    setState(() {});
    return route.completer.future;
  }

  void pop([dynamic result]) {
    _willPop(result);
  }
}

class _ConsoleRoute<T> {
  final String title;
  final Widget content;
  final Completer<T?> completer = Completer();

  _ConsoleRoute(this.title, this.content);
}
