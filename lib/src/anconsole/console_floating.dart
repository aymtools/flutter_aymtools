part of 'console.dart';

bool _isShowConsoleOverlay = false;

class _ConsoleFloatingButton extends StatelessWidget {
  final ValueNotifier<bool> toolsStatus;

  const _ConsoleFloatingButton({super.key, required this.toolsStatus});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FloatingDraggableButton(
      sharedPreferencesKEY: 'AnConsole',
      initOffset: Offset(size.width - MediaQuery.of(context).padding.right - 57,
          size.height * 3 / 4),
      onTap: () {
        if (_isShowConsoleOverlay) return;
        _isShowConsoleOverlay = true;
        final navigator = Navigator.of(context, rootNavigator: true);
        final overlay = navigator.overlay!;
        Zone.root.fork().run(() {
          late OverlayEntry overlayEntry;
          ConsoleOverlayController controller = ConsoleOverlayController(
            callClose: () {
              AnConsole.instance._overlayController = null;
              try {
                _isShowConsoleOverlay = false;
                overlayEntry.remove();
              } catch (_) {}
            },
          );
          AnConsole.instance._overlayController = controller;

          overlayEntry =
              OverlayEntry(builder: (context) => const _ConsoleWidget());
          overlay.insert(overlayEntry);
        });
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