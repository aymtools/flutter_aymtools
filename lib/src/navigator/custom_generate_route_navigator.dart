// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';
//
// mixin CustomGenerateRoutePageNavigatorState on NavigatorState {
//   Widget? generateRoutePageContent<T>(String name, Object? arguments);
//
//   Page<T?> convertPageContentToRoute<T>(String name, Object? arguments,
//       Widget pageContent);
//
//   Page<T?>? generateRoutePage<T>(String name, Object? arguments);
//
//   RouteSettings _routeSettings(String name, Object? arguments) {
//     RouteSettings? result;
//
//     final pw = generateRoutePageContent(name, arguments);
//     if (pw != null) {
//       result = convertPageContentToRoute(name, arguments, pw);
//       assert(result.name != null, 'RouteSettings name must not null');
//       return result;
//     }
//
//     result = generateRoutePage(name, arguments);
//
//     if (result == null) {
//       return RouteSettings(
//         name: name,
//         arguments: arguments,
//       );
//     }
//     assert(result != null &&
//         result.name != null, 'RouteSettings name must not null');
//     return result;
//   }
//
//   Route<T?>? _routeNamed<T>(String name,
//       {required Object? arguments, bool allowNull = false}) {
//     final RouteSettings settings = _routeSettings(name, arguments);
//     if (settings is Page<T>) {
//       return settings.createRoute(context);
//     }
//
//     if (allowNull && widget.onGenerateRoute == null) {
//       return null;
//     }
//     assert(() {
//       if (widget.onGenerateRoute == null) {
//         throw FlutterError(
//           'Navigator.onGenerateRoute was null, but the route named "$name" was referenced.\n'
//               'To use the Navigator API with named routes (pushNamed, pushReplacementNamed, or '
//               'pushNamedAndRemoveUntil), the Navigator must be provided with an '
//               'onGenerateRoute handler.\n'
//               'The Navigator was:\n'
//               '  $this',
//         );
//       }
//       return true;
//     }());
//
//     Route<T?>? route = widget.onGenerateRoute!(settings) as Route<T?>?;
//     if (route == null && !allowNull) {
//       assert(() {
//         if (widget.onUnknownRoute == null) {
//           throw FlutterError.fromParts(<DiagnosticsNode>[
//             ErrorSummary(
//                 'Navigator.onGenerateRoute returned null when requested to build route "$name".'),
//             ErrorDescription(
//               'The onGenerateRoute callback must never return null, unless an onUnknownRoute '
//                   'callback is provided as well.',
//             ),
//             DiagnosticsProperty<NavigatorState>('The Navigator was', this,
//                 style: DiagnosticsTreeStyle.errorProperty),
//           ]);
//         }
//         return true;
//       }());
//       route = widget.onUnknownRoute!(settings) as Route<T?>?;
//       assert(() {
//         if (route == null) {
//           throw FlutterError.fromParts(<DiagnosticsNode>[
//             ErrorSummary(
//                 'Navigator.onUnknownRoute returned null when requested to build route "$name".'),
//             ErrorDescription(
//                 'The onUnknownRoute callback must never return null.'),
//             DiagnosticsProperty<NavigatorState>('The Navigator was', this,
//                 style: DiagnosticsTreeStyle.errorProperty),
//           ]);
//         }
//         return true;
//       }());
//     }
//     assert(route != null || allowNull);
//     return route;
//   }
//
//   @override
//   Future<T?> pushNamed<T extends Object?>(String routeName, {
//     Object? arguments,
//   }) {
//     // this.pushNamed(routeName);
//     // this.pushNamedAndRemoveUntil(newRouteName, (route) => false);
//     // this.popAndPushNamed(routeName); //用pushNamed
//     // this.pushReplacementNamed(routeName);
//
//     return push<T?>(_routeNamed<T>(routeName, arguments: arguments)!);
//   }
//
//   @override
//   Future<T?> pushNamedAndRemoveUntil<T extends Object?>(String newRouteName,
//       RoutePredicate predicate, {
//         Object? arguments,
//       }) {
//     return pushAndRemoveUntil<T?>(
//         _routeNamed<T>(newRouteName, arguments: arguments)!, predicate);
//   }
//
//   @override
//   Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
//       String routeName, {
//         TO? result,
//         Object? arguments,
//       }) {
//     return pushReplacement<T?, TO>(
//         _routeNamed<T>(routeName, arguments: arguments)!,
//         result: result);
//   }
//
//   static List<Route<dynamic>> defaultGenerateInitialRoutes(
//       NavigatorState navigatorState, String initialRouteName) {
//     if (navigatorState is! CustomGenerateRoutePageNavigatorState) {
//       return Navigator.defaultGenerateInitialRoutes(
//           navigatorState, initialRouteName);
//     }
//     final navigator = navigatorState as CustomGenerateRoutePageNavigatorState;
//
//     final List<Route<dynamic>?> result = <Route<dynamic>?>[];
//     if (initialRouteName.startsWith('/') && initialRouteName.length > 1) {
//       initialRouteName = initialRouteName.substring(1); // strip leading '/'
//       assert(Navigator.defaultRouteName == '/');
//       List<String>? debugRouteNames;
//       assert(() {
//         debugRouteNames = <String>[Navigator.defaultRouteName];
//         return true;
//       }());
//       result.add(navigator._routeNamed<dynamic>(Navigator.defaultRouteName,
//           arguments: null, allowNull: true));
//       final List<String> routeParts = initialRouteName.split('/');
//       if (initialRouteName.isNotEmpty) {
//         String routeName = '';
//         for (final String part in routeParts) {
//           routeName += '/$part';
//           assert(() {
//             debugRouteNames!.add(routeName);
//             return true;
//           }());
//           result.add(navigator._routeNamed<dynamic>(routeName,
//               arguments: null, allowNull: true));
//         }
//       }
//       if (result.last == null) {
//         assert(() {
//           FlutterError.reportError(
//             FlutterErrorDetails(
//               exception: 'Could not navigate to initial route.\n'
//                   'The requested route name was: "/$initialRouteName"\n'
//                   'There was no corresponding route in the app, and therefore the initial route specified will be '
//                   'ignored and "${Navigator
//                   .defaultRouteName}" will be used instead.',
//             ),
//           );
//           return true;
//         }());
//         result.clear();
//       }
//     } else if (initialRouteName != Navigator.defaultRouteName) {
//       // If initialRouteName wasn't '/', then we try to get it with allowNull:true, so that if that fails,
//       // we fall back to '/' (without allowNull:true, see below).
//       result.add(navigator._routeNamed<dynamic>(initialRouteName,
//           arguments: null, allowNull: true));
//     }
//     // Null route might be a result of gap in initialRouteName
//     //
//     // For example, routes = ['A', 'A/B/C'], and initialRouteName = 'A/B/C'
//     // This should result in result = ['A', null,'A/B/C'] where 'A/B' produces
//     // the null. In this case, we want to filter out the null and return
//     // result = ['A', 'A/B/C'].
//     result.removeWhere((Route<dynamic>? route) => route == null);
//     if (result.isEmpty) {
//       result.add(navigator._routeNamed<dynamic>(Navigator.defaultRouteName,
//           arguments: null));
//     }
//     return result.cast<Route<dynamic>>();
//   }
// }
