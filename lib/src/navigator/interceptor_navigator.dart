import 'package:flutter/widgets.dart';

typedef RoutePushInterceptorInvoker<T> = Future<T?> Function(
    NavigatorState navigator,
    Route<T> route,
    RoutePushInterceptorProcess<T> next);

typedef RoutePageFactory = Page<dynamic>? Function(
    String name, Object? arguments);

abstract class RoutePushInterceptor<T> {
  Future<T?> invoke(NavigatorState navigator, Route<T> route,
      RoutePushInterceptorProcess<T> next);

  RoutePushInterceptor();

  factory RoutePushInterceptor.invoker(RoutePushInterceptorInvoker<T> r) =>
      _RoutePushInterceptorFun<T>(r);
}

abstract class RouteInterceptor implements RoutePushInterceptor {
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
      Route<T> newRoute,
      {TO? result});

  Future<T?> pushAndRemoveUntil<T extends Object?>(
      Route<T> newRoute, RoutePredicate predicate);

  void replace<T extends Object?>(
      {required Route oldRoute, required Route<T> newRoute});
}

class _RoutePushInterceptorFun<T> implements RoutePushInterceptor<T> {
  final RoutePushInterceptorInvoker<T> invoker;

  _RoutePushInterceptorFun(this.invoker);

  @override
  Future<T?> invoke(NavigatorState navigator, Route<T> route,
      RoutePushInterceptorProcess<T> next) {
    return invoker.call(navigator, route, next);
  }
}

abstract class RoutePushInterceptorProcess<T> {
  Future<T?> process(Route<T> route);

  RoutePushInterceptorProcess._();

  factory RoutePushInterceptorProcess._invoker(
          NavigatorState navigator,
          RoutePushInterceptor<T> interceptor,
          RoutePushInterceptorProcess<T> next) =>
      _RoutePushInterceptorProcessInvoker<T>(navigator, interceptor, next);

  factory RoutePushInterceptorProcess._null() =>
      _RoutePushInterceptorProcessNull<T>();
}

class _RoutePushInterceptorProcessInvoker<T>
    extends RoutePushInterceptorProcess<T> {
  final NavigatorState _navigator;
  final RoutePushInterceptor<T> _runner;
  final RoutePushInterceptorProcess<T> _next;

  _RoutePushInterceptorProcessInvoker(this._navigator, this._runner, this._next)
      : super._();

  @override
  Future<T?> process(Route<T> route) =>
      _runner.invoke(_navigator, route, _next);
}

class _RoutePushInterceptorProcessNull<T>
    implements RoutePushInterceptorProcess<T> {
  @override
  Future<T?> process(Route<T> route) {
    throw UnimplementedError();
  }
}

mixin InterceptorNavigatorState on NavigatorState {
  Future<T?> _makeInterceptors<T extends Object?>(
      Route<T> route, Future<T?> Function(Route<T> route) call) {
    var list = generatePushPageInterceptor(route);
    if (list == null || list.isEmpty) {
      return call(route);
    }
    f(_, r, ___) => call(r);
    final x = RoutePushInterceptor<T>.invoker(f);
    final listR = <RoutePushInterceptor<T>>[];
    RoutePushInterceptorProcess<T> p = RoutePushInterceptorProcess<T>._invoker(
        this, x, RoutePushInterceptorProcess._null());
    for (var element in listR.reversed) {
      p = RoutePushInterceptorProcess<T>._invoker(this, element, p);
    }
    return p.process(route);
  }

  @override
  Future<T?> push<T extends Object?>(Route<T> route) =>
      _makeInterceptors(route, (r) => super.push(r));

  @override
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
          Route<T> newRoute,
          {TO? result}) =>
      _makeInterceptors(
          newRoute, (r) => super.pushReplacement(r, result: result));

  @override
  Future<T?> pushAndRemoveUntil<T extends Object?>(
          Route<T> newRoute, RoutePredicate predicate) =>
      _makeInterceptors(
          newRoute, (r) => super.pushAndRemoveUntil(r, predicate));

  @override
  void replace<T extends Object?>(
      {required Route oldRoute, required Route<T> newRoute}) {
    _makeInterceptors(newRoute, (route) {
      super.replace(oldRoute: oldRoute, newRoute: newRoute);
      return Future<T?>(() => null);
    });
  }

  @override
  void pop<T extends Object?>([T? result]) {
    super.pop(result);
  }

  @override
  void removeRoute(Route route) {
    super.removeRoute(route);
  }

  @override
  void removeRouteBelow(Route anchorRoute) {
    super.removeRouteBelow(anchorRoute);
  }

  @override
  void replaceRouteBelow<T extends Object?>(
      {required Route anchorRoute, required Route<T> newRoute}) {
    super.replaceRouteBelow(anchorRoute: anchorRoute, newRoute: newRoute);
  }

  List<RoutePushInterceptor>? generatePushPageInterceptor(Route route);
}
