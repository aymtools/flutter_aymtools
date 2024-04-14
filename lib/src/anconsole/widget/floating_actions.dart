import 'package:aymtools/src/widgets/multi_child_separated.dart';
import 'package:flutter/material.dart';

class FloatingActions extends StatefulWidget {
  final Widget child;
  final bool initShowFloating;
  final Widget Function(BuildContext) floatingActionsBuilder;

  const FloatingActions(
      {super.key,
      required this.child,
      this.initShowFloating = true,
      required this.floatingActionsBuilder});

  factory FloatingActions.bottomRight({
    Key? key,
    required Widget child,
    bool initShowFloating = true,
    required List<Widget> actions,
    double actionSeparatorSize = 10,
    double positionedBottom = 44,
    double positionedRight = 24,
  }) {
    return FloatingActions(
        key: key,
        initShowFloating: initShowFloating,
        floatingActionsBuilder: (_) => Positioned(
              bottom: positionedBottom,
              right: positionedRight,
              child: Align(
                alignment: Alignment.bottomRight,
                child: ColumnSeparated.separatorSize(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  separatorSize: actionSeparatorSize,
                  children: actions,
                ),
              ),
              //value ? child! : SizedBox.shrink(),
            ),
        child: child);
  }

  factory FloatingActions.topRight({
    Key? key,
    required Widget child,
    bool initShowFloating = true,
    required List<Widget> actions,
    double actionSeparatorSize = 10,
    double positionedTop = 44,
    double positionedRight = 24,
  }) {
    return FloatingActions(
        key: key,
        initShowFloating: initShowFloating,
        floatingActionsBuilder: (_) => Positioned(
              top: positionedTop,
              right: positionedRight,
              child: Align(
                alignment: Alignment.topRight,
                child: ColumnSeparated.separatorSize(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  separatorSize: actionSeparatorSize,
                  children: actions,
                ),
              ),
              //value ? child! : SizedBox.shrink(),
            ),
        child: child);
  }

  @override
  State<FloatingActions> createState() => _FloatingActionsState();
}

class _FloatingActionsState extends State<FloatingActions> {
  double position = 0.0;
  double sensitivityFactor = 20.0;

  late ValueNotifier<bool> showFloating =
      ValueNotifier(widget.initShowFloating);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification.metrics.axis == Axis.horizontal) return false;
            if (notification.metrics.pixels - position >= sensitivityFactor) {
              position = notification.metrics.pixels;
              showFloating.value = false;
            } else if (position - notification.metrics.pixels >=
                sensitivityFactor) {
              position = notification.metrics.pixels;
              showFloating.value = true;
            }
            return false;
          },
          child: widget.child,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: showFloating,
          builder: (context, value, child) => value
              ? widget.floatingActionsBuilder(context)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
