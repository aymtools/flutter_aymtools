// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
//
// mixin ReversedHandlePopRouteObserverWidgetsBinding on WidgetsBinding {
//   final List<WidgetsBindingObserver> _observers = [];
//
//   @override
//   Future<void> handlePopRoute() async {
//     for (final WidgetsBindingObserver observer
//         in List<WidgetsBindingObserver>.of(_observers.reversed)) {
//       if (await observer.didPopRoute()) {
//         return;
//       }
//     }
//     SystemNavigator.pop();
//   }
//
//   @override
//   void addObserver(WidgetsBindingObserver observer) {
//     super.addObserver(observer);
//     _observers.add(observer);
//   }
//
//   @override
//   bool removeObserver(WidgetsBindingObserver observer) {
//     _observers.remove(observer);
//     return super.removeObserver(observer);
//   }
// }
