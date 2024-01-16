import 'package:flutter/material.dart';

import 'custom_generate_route_navigator.dart';
import 'interceptor_navigator.dart';

typedef PageContentCreator = Widget Function(
    BuildContext context, Object? argments);
typedef OnGeneratePageContent = Widget? Function(
    String name, Object? arguments);
typedef PageContentWrapper = Widget Function(
    String name, Object? arguments, Widget pageContent);
typedef PageContentConvertRoute = Page<dynamic> Function(
    String name, Object? arguments, Widget pageContent);

typedef OnGeneratePushPageInterceptor = List<RoutePushInterceptor>? Function(
    Route<dynamic> route);

Page<T> _onPageContentConvertRoute<T>(
        String name, Object? arguments, Widget page) =>
    MaterialPage(child: page, name: name, arguments: arguments);

Widget _pageContentWrapper<T>(String name, Object? arguments, Widget page) =>
    page;

class AnNavigator extends Navigator {
  const AnNavigator({
    super.key,
    super.pages = const <Page<dynamic>>[],
    super.onPopPage,
    super.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    super.initialRoute,
    RouteFactory? onGenerateRoute,
    super.onUnknownRoute,
    super.observers = const <NavigatorObserver>[],
    super.restorationScopeId,
    super.onGenerateInitialRoutes,
    super.reportsRouteUpdateToEngine = false,
    super.clipBehavior = Clip.hardEdge,
    super.requestFocus = true,
    this.onGenerateRoutePage,
    this.onGeneratePushPageInterceptor,
    this.pageContentCreator,
    this.onGeneratePageContent,
    this.onPageContentWrapper = _pageContentWrapper,
    this.onPageContentConvertRoute = _onPageContentConvertRoute,
  })  : _onGenerateRoute = onGenerateRoute,
        assert(key is GlobalKey),
        _navigatorKey = key as GlobalKey<NavigatorState>,
        super(onGenerateRoute: null);

  @override
  NavigatorState createState() => AnNavigatorState();

  final Map<String, PageContentCreator>? pageContentCreator;

  final OnGeneratePageContent? onGeneratePageContent;

  final PageContentWrapper onPageContentWrapper;

  final PageContentConvertRoute onPageContentConvertRoute;

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
  RouteFactory? get onGenerateRoute {
    return (RouteSettings settings) {
      String name = settings.name!;
      Object? arguments = settings.arguments;
      Widget? pageContent;
      if (pageContentCreator != null && pageContentCreator!.isNotEmpty) {
        final builder = pageContentCreator![name];
        if (builder != null) {
          pageContent =
              Builder(builder: (context) => builder(context, arguments));
        }
      }
      pageContent ??= onGeneratePageContent?.call(name, arguments);

      if (pageContent != null) {
        pageContent = onPageContentWrapper(name, arguments, pageContent);
      }
      final BuildContext navigatorStateContext =
          _navigatorKey.currentState!.context;

      if (pageContent != null) {
        return onPageContentConvertRoute
            .call(name, arguments, pageContent)
            .createRoute(navigatorStateContext);
      }
      if (onGenerateRoutePage != null) {
        final page = onGenerateRoutePage!(name, arguments);
        if (page != null) {
          return page.createRoute(navigatorStateContext);
        }
      }
      if (_onGenerateRoute != null) {
        return _onGenerateRoute!(settings);
      }
      return null;
    };
  }
}

class AnNavigatorState extends NavigatorState with InterceptorNavigatorState {
  @override
  AnNavigator get widget => super.widget as AnNavigator;

  //
  // @override
  // Page<T?>? generateRoutePage<T>(String name, Object? arguments) {
  //   return widget.onGenerateRoutePage?.call(name, arguments) as Page<T?>?;
  // }
  //
  // @override
  // Widget? generateRoutePageContent<T>(String name, Object? arguments) {
  //   Widget? pageContent;
  //   if (widget.pageContentCreator != null &&
  //       widget.pageContentCreator!.isNotEmpty) {
  //     final builder = widget.pageContentCreator![name];
  //     if (builder != null) {
  //       pageContent =
  //           Builder(builder: (context) => builder(context, arguments));
  //     }
  //   }
  //   pageContent ??= widget.onGeneratePageContent?.call(name, arguments);
  //
  //   if (pageContent != null) {
  //     pageContent = wrapperPageContent(name, arguments, pageContent);
  //   }
  //
  //   return pageContent;
  // }
  //
  // Widget wrapperPageContent(
  //     String name, Object? arguments, Widget pageContent) {
  //   return widget.onPageContentWrapper(name, arguments, pageContent);
  // }
  //
  // @override
  // Page<T?> convertPageContentToRoute<T>(
  //     String name, Object? arguments, Widget pageContent) {
  //   return widget.onPageContentConvertRoute.call(name, arguments, pageContent)
  //       as Page<T?>;
  // }

  @override
  List<RoutePushInterceptor>? generatePushPageInterceptor(Route route) {
    return widget.onGeneratePushPageInterceptor?.call(route);
  }
}
