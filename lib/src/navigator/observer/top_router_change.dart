import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

abstract class NavigatorTopRouteChangeObserver extends NavigatorObserver {
  @mustCallSuper
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.isCurrent == true) {
      onTopRouteChange(previousRoute!);
    }
  }

  @mustCallSuper
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.isCurrent == true) onTopRouteChange(route);
  }

  @mustCallSuper
  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute?.isCurrent == true) onTopRouteChange(previousRoute!);
  }

  @mustCallSuper
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.isCurrent == true) onTopRouteChange(newRoute!);
  }

  void onTopRouteChange(Route route);
}

// class TopRouteObserver extends NavigatorTopRouteChangeObserver {
//   static final WeakMap<NavigatorState, Route> _topPage = WeakMap();
//
//   @override
//   void onTopRouteChange(Route route) {
//     final nav = navigator;
//     if (nav == null ) return;
//     _topPage[nav]
//   }
// }
