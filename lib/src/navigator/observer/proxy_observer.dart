import 'package:aymtools/src/tools/expando_ext.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

Expando<Set<ProxyNavigatorObserver>> _proxy = Expando();

class ProxyManagerNavigatorObserver extends NavigatorObserver {
  final Set<ProxyNavigatorObserver> _willAdd = {};
  final Set<ProxyNavigatorObserver> _willRemove = {};

  @mustCallSuper
  @override
  void didPop(Route route, Route? previousRoute) {
    _cleanObserver();
    super.didPop(route, previousRoute);
    _observers?.forEach((element) => element.didPop(route, previousRoute));
  }

  @mustCallSuper
  @override
  void didPush(Route route, Route? previousRoute) {
    _cleanObserver();
    super.didPush(route, previousRoute);
    _observers?.forEach((element) => element.didPush(route, previousRoute));
  }

  @mustCallSuper
  @override
  void didRemove(Route route, Route? previousRoute) {
    _cleanObserver();
    super.didRemove(route, previousRoute);
    _observers?.forEach((element) => element.didRemove(route, previousRoute));
  }

  @mustCallSuper
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _cleanObserver();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _observers?.forEach((element) =>
        element.didReplace(newRoute: newRoute, oldRoute: oldRoute));
  }

  @mustCallSuper
  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _cleanObserver();
    super.didStartUserGesture(route, previousRoute);
    _observers?.forEach(
        (element) => element.didStartUserGesture(route, previousRoute));
  }

  @mustCallSuper
  @override
  void didStopUserGesture() {
    _cleanObserver();
    super.didStopUserGesture();
    _observers?.forEach((element) => element.didStopUserGesture());
  }

  void addObserver(ProxyNavigatorObserver observer) {
    final nav = navigator;
    assert(observer.navigator == null || observer.navigator == navigator);
    if (nav == null) {
      _willAdd.add(observer);
    } else {
      final observers =
          _proxy.getOrPut(nav, defaultValue: () => <ProxyNavigatorObserver>{});
      observers.add(observer);
    }
  }

  void removeObserver(ProxyNavigatorObserver observer) {
    final nav = navigator;
    assert(nav != null);

    observer._navigatorProxy = null;
    _willAdd.remove(observer);
    if (nav == null) {
      _willRemove.add(observer);
    } else {
      _observers?.remove(observer);
    }
  }

  _cleanObserver() {
    if (_willAdd.isEmpty && _willRemove.isEmpty) {
      return;
    }
    final nav = navigator!;
    final observers =
        _proxy.getOrPut(nav, defaultValue: () => <ProxyNavigatorObserver>{});
    if (_willAdd.isNotEmpty) {
      observers.addAll(_willAdd);
      _willAdd.clear();
    }
    if (_willRemove.isNotEmpty) {
      observers.removeAll(_willRemove);
      _willRemove.clear();
    }
  }

  Set<ProxyNavigatorObserver>? get _observers {
    final nav = navigator!;
    return _proxy[nav];
  }

  static ProxyManagerNavigatorObserver? maybe(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    var navigator = _of(context, rootNavigator: rootNavigator);
    if (navigator == null) return null;

    do {
      var observers = navigator!.widget.observers;
      var pmnos = observers.whereType<ProxyManagerNavigatorObserver>();
      if (pmnos.isNotEmpty) {
        assert(pmnos.length == 1,
            'ProxyManagerNavigatorObserver only one in Navigator');
        return pmnos.single;
      }
      navigator = _of(navigator.context, checkThis: false);
    } while (navigator != null && rootNavigator != true);
    return null;
  }

  static ProxyManagerNavigatorObserver of(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    final observer = maybe(context, rootNavigator: rootNavigator);
    assert(observer != null);
    return observer!;
  }

  static NavigatorState? _of(
    BuildContext context, {
    bool checkThis = true,
    bool rootNavigator = false,
  }) {
    NavigatorState? navigator;
    if (checkThis &&
        context is StatefulElement &&
        context.state is NavigatorState) {
      navigator = context.state as NavigatorState;
    }
    if (rootNavigator) {
      navigator =
          context.findRootAncestorStateOfType<NavigatorState>() ?? navigator;
    } else {
      navigator =
          navigator ?? context.findAncestorStateOfType<NavigatorState>();
    }
    return navigator;
  }
}

mixin ProxyNavigatorObserver on NavigatorObserver {
  NavigatorState? _navigatorProxy;

  @override
  NavigatorState? get navigator => super.navigator ?? _navigatorProxy!;
}
