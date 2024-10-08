import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

import 'first.dart';
import 'home.dart';
import 'pageview.dart';
import 'second.dart';

void main() {
  runApp(const MyApp());
}

final routes = <String, WidgetBuilder>{
  '/': (context) => const MyHomePage(title: 'aymtools'),
  '/first': (_) => const FistPage(),
  '/second': (_) => const SecondPage(),
  '/pageView': (_) => const PageViewExample(),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'Aymtools Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
          // AnConsole.instance.navigatorObserver,
        ],
        routes: routes,
      ),
    );
  }
}
