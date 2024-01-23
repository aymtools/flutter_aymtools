part of 'an_console.dart';

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
            builder: (context) => _AnConsoleOverlay(controller: controller));
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
            child: const Center(
              child: Icon(
                Icons.bug_report_rounded,
                color: Colors.blue,
                size: 41,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
