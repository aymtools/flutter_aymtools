import 'package:flutter/material.dart';

import 'interceptor_navigator.dart';

typedef PageCreator = Widget Function(BuildContext context, Object? argments);

typedef OnGeneratePage = Widget? Function(String name, Object? arguments);

typedef OnGeneratePageWrapper = Widget Function(
    String name, Object? arguments, Widget page);

typedef OnPageConvertToRoute = Page<dynamic> Function(
    String name, Object? arguments, Widget page);

typedef OnGeneratePushPageInterceptor = List<RoutePushInterceptor>? Function(
    Route<dynamic> route);

Page<T> _onPageConvertToRoute<T>(String name, Object? arguments, Widget page) =>
    MaterialPage(child: page, name: name, arguments: arguments);

Widget _pageWrapper<T>(String name, Object? arguments, Widget page) => page;

class AnNavigator extends Navigator {
  const AnNavigator({
    super.key,
    super.pages = const <Page<dynamic>>[],
    super.onPopPage,
    super.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    super.initialRoute,
    super.onUnknownRoute,
    super.observers = const <NavigatorObserver>[],
    super.restorationScopeId,
    super.onGenerateInitialRoutes,
    super.reportsRouteUpdateToEngine = false,
    super.clipBehavior = Clip.hardEdge,
    super.requestFocus = true,
    this.pageCreators,
    this.onGeneratePage,
    this.onGeneratePageWrapper = _pageWrapper,
    this.onGenerateRoutePage,
    this.onPageConvertToRoute = _onPageConvertToRoute,
    RouteFactory? onGenerateRoute,
    this.onGeneratePushPageInterceptor,
  })  : _onGenerateRoute = onGenerateRoute,
        assert(key is GlobalKey),
        _navigatorKey = key as GlobalKey<NavigatorState>,
        super(onGenerateRoute: null);

  @override
  NavigatorState createState() => AnNavigatorState();

  final Map<String, PageCreator>? pageCreators;

  final OnGeneratePage? onGeneratePage;

  final OnGeneratePageWrapper onGeneratePageWrapper;

  final OnPageConvertToRoute onPageConvertToRoute;

  final RoutePageFactory? onGenerateRoutePage;

  final OnGeneratePushPageInterceptor? onGeneratePushPageInterceptor;
  final RouteFactory? _onGenerateRoute;

  final GlobalKey<NavigatorState> _navigatorKey;

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

  @override
  RouteFactory get onGenerateRoute {
    return (RouteSettings settings) {
      Route<dynamic>? route;

      if (_onGenerateRoute != null) {
        route = _onGenerateRoute!(settings);
      }

      if (route == null && settings.name?.isNotEmpty == true) {
        String name = settings.name!;
        Object? arguments = settings.arguments;

        if (onGenerateRoutePage != null) {
          final page = onGenerateRoutePage!(name, arguments);
          if (page != null) {
            route = page.createRoute(_navigatorKey.currentState!.context);
          }
        }

        if (route == null) {
          Widget? page = onGeneratePage?.call(name, arguments);
          if (page == null &&
              pageCreators != null &&
              pageCreators!.isNotEmpty) {
            final builder = pageCreators![name];
            if (builder != null) {
              page = Builder(builder: (context) => builder(context, arguments));
            }
          }
          if (page != null) {
            page = onGeneratePageWrapper(name, arguments, page);

            return onPageConvertToRoute
                .call(name, arguments, page)
                .createRoute(_navigatorKey.currentState!.context);
          }
        }
      }
      return null;
    };
  }
}

class AnNavigatorState extends NavigatorState with InterceptorNavigatorState {
  @override
  AnNavigator get widget => super.widget as AnNavigator;

  @override
  List<RoutePushInterceptor>? generatePushPageInterceptor(Route route) {
    return widget.onGeneratePushPageInterceptor?.call(route);
  }
}
