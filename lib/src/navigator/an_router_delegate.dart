part of 'an_navigator.dart';

class AnRouterDelegate extends RouterDelegate<RouteSettings>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteSettings> {
  final List<Page<dynamic>> pages;
  final TransitionDelegate<dynamic> transitionDelegate;

  final String? initialRoute;
  final RouteFactory? onGenerateRoute;

  final RouteFactory? onUnknownRoute;

  final List<NavigatorObserver> observers;
  final String? restorationScopeId;
  final RouteListFactory onGenerateInitialRoutes;
  final bool reportsRouteUpdateToEngine;
  final Clip clipBehavior;
  final bool requestFocus;

  final Map<String, PageCreator>? pageCreators;

  final OnGeneratePage? onGeneratePage;

  final OnGeneratePageWrapper onGeneratePageWrapper;

  final OnPageConvertToRoute onPageConvertToRoute;

  final RoutePageFactory? onGenerateRoutePage;

  final OnGeneratePushPageInterceptor? onGeneratePushPageInterceptor;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  AnRouterDelegate({
    this.pages = const <Page<dynamic>>[],
    this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    this.initialRoute,
    this.onUnknownRoute,
    this.observers = const <NavigatorObserver>[],
    this.restorationScopeId,
    this.onGenerateInitialRoutes = Navigator.defaultGenerateInitialRoutes,
    this.reportsRouteUpdateToEngine = false,
    this.clipBehavior = Clip.hardEdge,
    this.requestFocus = true,
    this.pageCreators,
    this.onGeneratePage,
    this.onGeneratePageWrapper = _pageWrapper,
    this.onGenerateRoutePage,
    this.onPageConvertToRoute = _onPageConvertToRoute,
    this.onGenerateRoute,
    this.onGeneratePushPageInterceptor,
  });

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return AnNavigator(
      key: _navigatorKey,
      pages: pages,
      transitionDelegate: transitionDelegate,
      initialRoute: initialRoute,
      onUnknownRoute: onUnknownRoute,
      observers: observers,
      restorationScopeId: restorationScopeId,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      reportsRouteUpdateToEngine: reportsRouteUpdateToEngine,
      clipBehavior: clipBehavior,
      requestFocus: requestFocus,
      pageCreators: pageCreators,
      onGeneratePage: onGeneratePage,
      onGeneratePageWrapper: onGeneratePageWrapper,
      onGenerateRoutePage: onGenerateRoutePage,
      onPageConvertToRoute: onPageConvertToRoute,
      onGenerateRoute: onGenerateRoute,
      onGeneratePushPageInterceptor: onGeneratePushPageInterceptor,
    );
  }

  @override
  Future<void> setNewRoutePath(RouteSettings configuration) async {
    _navigatorKey.currentState
        ?.pushNamed(configuration.name!, arguments: configuration.arguments);
  }
}
