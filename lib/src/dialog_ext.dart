import 'dart:ui';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<T?> showCDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Cancellable? cancellable,
  bool barrierDismissible = true,
  Color? barrierColor = Colors.black54,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  assert(debugCheckHasMaterialLocalizations(context));
  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return Future.value(null);
  }
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    settings: routeSettings,
    themes: themes,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior:
        traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));

  return navigator.push<T>(route).whenComplete(() => cancellable?.release());
}

Future<T?> showCCupertinoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Cancellable? cancellable,
  String? barrierLabel,
  bool useRootNavigator = true,
  bool barrierDismissible = false,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return Future.value(null);
  }
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

  final route = CupertinoDialogRoute<T>(
    builder: builder,
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor:
        CupertinoDynamicColor.resolve(kCupertinoModalBarrierColor, context),
    settings: routeSettings,
    anchorPoint: anchorPoint,
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));
  return navigator.push<T>(route).whenComplete(() => cancellable?.release());
}

Future<T?> showCGeneralDialog<T extends Object?>({
  required BuildContext context,
  required RoutePageBuilder pageBuilder,
  Cancellable? cancellable,
  bool barrierDismissible = false,
  String? barrierLabel,
  Color barrierColor = const Color(0x80000000),
  Duration transitionDuration = const Duration(milliseconds: 200),
  RouteTransitionsBuilder? transitionBuilder,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  assert(!barrierDismissible || barrierLabel != null);

  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return Future.value(null);
  }
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final route = RawDialogRoute<T>(
    pageBuilder: pageBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transitionBuilder: transitionBuilder,
    settings: routeSettings,
    anchorPoint: anchorPoint,
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));
  return navigator.push<T>(route).whenComplete(() => cancellable?.release());
}

Future<T?> showCModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Cancellable? cancellable,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return Future.value(null);
  }
  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);

  final route = ModalBottomSheetRoute<T>(
    builder: builder,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    isScrollControlled: isScrollControlled,
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint:
        localizations.scrimOnTapHint(localizations.bottomSheetLabel),
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    isDismissible: isDismissible,
    modalBarrierColor:
        barrierColor ?? Theme.of(context).bottomSheetTheme.modalBarrierColor,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    settings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    useSafeArea: useSafeArea,
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));
  return navigator.push(route).whenComplete(() => cancellable?.release());
}

PersistentBottomSheetController<T> showCBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Cancellable? cancellable,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  bool? enableDrag,
  AnimationController? transitionAnimationController,
}) {
  assert(debugCheckHasScaffold(context));
  assert(
      cancellable == null || cancellable.isAvailable, 'cancellable cannot use');

  final result = Scaffold.of(context).showBottomSheet<T>(
    builder,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    enableDrag: enableDrag,
    transitionAnimationController: transitionAnimationController,
  );
  result.closed.then((value) => cancellable?.release());
  cancellable?.onCancel.then((value) => result.close());
  return result;
}

void showCAboutDialog({
  required BuildContext context,
  Cancellable? cancellable,
  String? applicationName,
  String? applicationVersion,
  Widget? applicationIcon,
  String? applicationLegalese,
  List<Widget>? children,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  showCDialog<void>(
    context: context,
    cancellable: cancellable,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext context) {
      return AboutDialog(
        applicationName: applicationName,
        applicationVersion: applicationVersion,
        applicationIcon: applicationIcon,
        applicationLegalese: applicationLegalese,
        children: children,
      );
    },
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
  );
}

Future<T?> showCCupertinoModalPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Cancellable? cancellable,
  ImageFilter? filter,
  Color barrierColor = kCupertinoModalBarrierColor,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  bool semanticsDismissible = false,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return Future.value(null);
  }
  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);

  final route = CupertinoModalPopupRoute<T>(
    builder: builder,
    filter: filter,
    barrierColor: CupertinoDynamicColor.resolve(barrierColor, context),
    barrierDismissible: barrierDismissible,
    semanticsDismissible: semanticsDismissible,
    settings: routeSettings,
    anchorPoint: anchorPoint,
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));
  return navigator.push(route).whenComplete(() => cancellable?.release());
}

void showCLicensePage({
  required BuildContext context,
  Cancellable? cancellable,
  String? applicationName,
  String? applicationVersion,
  Widget? applicationIcon,
  String? applicationLegalese,
  bool useRootNavigator = false,
}) {
  cancellable = cancellable?.makeCancellable(infectious: true);
  if (cancellable?.isUnavailable == true) {
    return;
  }
  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  final route = MaterialPageRoute<void>(
    builder: (BuildContext context) => LicensePage(
      applicationName: applicationName,
      applicationVersion: applicationVersion,
      applicationIcon: applicationIcon,
      applicationLegalese: applicationLegalese,
    ),
  );
  cancellable?.onCancel.then((value) => route.navigator?.removeRoute(route));
  navigator.push(route).whenComplete(() => cancellable?.release());
}
