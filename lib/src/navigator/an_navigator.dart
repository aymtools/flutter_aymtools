import 'package:flutter/material.dart';

import 'custom_generate_route_navigator.dart';
import 'interceptor_navigator.dart';

Page<T> _onPageWidgetConvertRoute<T>(
    Widget page, String name, Object? arguments) {
  return MaterialPage(child: page, name: name, arguments: arguments);
}

class AnNavigator extends Navigator {
  const AnNavigator({
    super.key,
    super.pages = const <Page<dynamic>>[],
    super.onPopPage,
    super.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    super.initialRoute,
    super.onGenerateRoute,
    super.onUnknownRoute,
    super.observers = const <NavigatorObserver>[],
    super.restorationScopeId,
    super.onGenerateInitialRoutes = CustomGenerateRoutePageNavigatorState.defaultGenerateInitialRoutes,
    super.reportsRouteUpdateToEngine = false,
    super.clipBehavior = Clip.hardEdge,
    super.requestFocus = true,
    this.onGenerateRoutePage,
    this.onGeneratePushPageInterceptor,
    this.onGenerateRoutePageWidget,
    this.onPageWidgetConvertRoute = _onPageWidgetConvertRoute,
  });

  @override
  NavigatorState createState() => AnNavigatorState();

  final RoutePageFactory? onGenerateRoutePage;

  final Widget? Function(String name, Object? arguments)?
      onGenerateRoutePageWidget;

  final Page<dynamic> Function(
          Widget pageWidget, String name, Object? arguments)
      onPageWidgetConvertRoute;

  final List<RoutePushInterceptor>? Function(Route<dynamic> route)?
      onGeneratePushPageInterceptor;

  static NavigatorState of(BuildContext context,
          {bool rootNavigator = false}) =>
      Navigator.of(context, rootNavigator: rootNavigator);

  static AnNavigatorState ofAn(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnNavigatorState? navigator;
    if (context is StatefulElement && context.state is AnNavigatorState) {
      navigator = context.state as AnNavigatorState;
    }
    if (rootNavigator) {
      navigator =
          context.findRootAncestorStateOfType<AnNavigatorState>() ?? navigator;
    } else {
      navigator =
          navigator ?? context.findAncestorStateOfType<AnNavigatorState>();
    }

    assert(() {
      if (navigator == null) {
        throw FlutterError(
          'AnNavigator operation requested with a context that does not include a AnNavigator.\n'
          'The context used to push or pop routes from the AnNavigator must be that of a '
          'widget that is a descendant of a AnNavigator widget.',
        );
      }
      return true;
    }());
    return navigator!;
  }
}

class AnNavigatorState extends NavigatorState
    with CustomGenerateRoutePageNavigatorState, InterceptorNavigatorState {
  @override
  AnNavigator get widget => super.widget as AnNavigator;

  @override
  Page<T?>? generateRoutePage<T>(String name, Object? arguments) {
    return widget.onGenerateRoutePage?.call(name, arguments) as Page<T?>?;
  }

  @override
  Widget? generateRoutePageWidget<T>(String name, Object? arguments) {
    return widget.onGenerateRoutePageWidget?.call(name, arguments);
  }

  @override
  Page<T?> convertPageWidgetToRoute<T>(
      Widget pageWidget, String name, Object? arguments) {
    return widget.onPageWidgetConvertRoute.call(pageWidget, name, arguments)
        as Page<T?>;
  }

  @override
  List<RoutePushInterceptor>? generatePushPageInterceptor(Route route) {
    return widget.onGeneratePushPageInterceptor?.call(route);
  }
}
