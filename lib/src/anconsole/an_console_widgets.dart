part of 'an_console.dart';

class _AnConsoleOverlayGroup extends StatelessWidget {
  final AnConsoleOverlayController controller;
  final Widget title;
  final Widget content;

  const _AnConsoleOverlayGroup(
      {super.key,
      required this.title,
      required this.content,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;
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
                            onTap: () => controller._willPop?.call(),
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              Icons.arrow_back,
                              size: 22,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                          Expanded(
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
                                width: double.infinity,
                                child: title,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.callClose.call(),
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
                    Container(
                      height: 0.5,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: content,
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
}

class _InitRoute extends StatefulWidget {
  final ValueNotifier<int> selectedConsole;

  const _InitRoute({super.key, required this.selectedConsole});

  @override
  State<_InitRoute> createState() => _InitRouteState();
}

class _InitRouteState extends State<_InitRoute> with TickerProviderStateMixin {
  late TabController _controller = TabController(
      length: AnConsoleObserver.instance._routes.length,
      vsync: this,
      initialIndex: widget.selectedConsole.value);

  _change() {
    _controller.index = widget.selectedConsole.value;
  }

  @override
  void initState() {
    super.initState();
    widget.selectedConsole.addListener(_change);
  }

  @override
  void didUpdateWidget(covariant _InitRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedConsole != oldWidget.selectedConsole) {
      oldWidget.selectedConsole.removeListener(_change);
      _controller = TabController(
          length: AnConsoleObserver.instance._routes.length,
          vsync: this,
          initialIndex: widget.selectedConsole.value);
      widget.selectedConsole.addListener(_change);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.selectedConsole.removeListener(_change);
  }

  @override
  Widget build(BuildContext context) {
    final consoles = AnConsoleObserver.instance._routes;

    return consoles.isEmpty
        ? Container()
        : TabBarView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: consoles
                .map((e) =>
                    _InitRouteContent(child: RepaintBoundary(child: e.content)))
                .toList(growable: false),
          );
  }
}

class _InitRouteContent extends StatefulWidget {
  final Widget child;

  const _InitRouteContent({super.key, required this.child});

  @override
  State<_InitRouteContent> createState() => _InitRouteContentState();
}

class _InitRouteContentState extends State<_InitRouteContent>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
