import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:aymtools/aymtools.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ListenableBuilder extends StatefulWidget {
  final List<Listenable> listeners;
  final Widget Function(
      BuildContext context, List<Listenable> listeners, Widget? child) builder;
  final Widget? child;

  final bool Function(List<Listenable> listeners, List<Listenable> oldListeners)
      shouldUpdate;

  const ListenableBuilder(
      {super.key,
      required this.listeners,
      required this.builder,
      this.child,
      this.shouldUpdate = _areListsEqual});

  @override
  State<ListenableBuilder> createState() => _ListenableBuilderState();

  factory ListenableBuilder.one({
    Key? key,
    required Listenable listenable,
    required Widget Function(
            BuildContext context, Listenable listeners, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder(
          key: key,
          listeners: [listenable],
          child: child,
          shouldUpdate: (l1, l2) => l1.single == l2.single,
          builder: (context, _, child) => builder(context, listenable, child));

  factory ListenableBuilder.two({
    Key? key,
    required Listenable listenable,
    required Listenable listenable2,
    required Widget Function(BuildContext context, Listenable listeners,
            Listenable listeners2, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder(
          key: key,
          listeners: [listenable, listenable2],
          child: child,
          builder: (context, _, child) =>
              builder(context, listenable, listenable2, child));

  factory ListenableBuilder.three({
    Key? key,
    required Listenable listenable,
    required Listenable listenable2,
    required Listenable listenable3,
    required Widget Function(BuildContext context, Listenable listeners,
            Listenable listenable2, Listenable listenable3, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder(
          key: key,
          listeners: [listenable],
          child: child,
          shouldUpdate: (l1, l2) => l1.single == l2.single,
          builder: (context, _, child) =>
              builder(context, listenable, listenable2, listenable3, child));

  static const ListenableBuilderNotifierCompanion notifier =
      ListenableBuilderNotifierCompanion._();

  static const ListenableBuilderValueCompanion value =
      ListenableBuilderValueCompanion._();
}

class _ListenableBuilderState extends State<ListenableBuilder>
    with CancellableState {
  late Cancellable cancellable;
  late Listenable _curl;

  void _changer() {
    try {
      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    cancellable = makeCancellable();
    _curl = Listenable.merge(widget.listeners);
    _curl.addCListener(cancellable, _changer);
  }

  @override
  void didUpdateWidget(covariant ListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_areListsEqual(widget.listeners, oldWidget.listeners)) {
      cancellable.cancel();
      cancellable = makeCancellable();
      _curl = Listenable.merge(widget.listeners);
      _curl.addCListener(cancellable, _changer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.listeners, widget.child);
  }
}

bool _areListsEqual(List a, List b) {
  if (a.length != b.length) {
    return false;
  }

  for (var item in a) {
    if (!b.contains(item)) {
      return false;
    }
  }

  return true;
}

class ListenableBuilderNotifierCompanion {
  const ListenableBuilderNotifierCompanion._();
}

extension ListenableBuilderNotifierFactory
    on ListenableBuilderNotifierCompanion {
  ListenableBuilder one<T extends ChangeNotifier>({
    Key? key,
    required T changeNotifier,
    required Widget Function(
            BuildContext context, T changeNotifier, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.one(
          key: key,
          listenable: changeNotifier,
          builder: (context, _, child) =>
              builder(context, changeNotifier, child),
          child: child);

  ListenableBuilder two<T extends ChangeNotifier, T2 extends ChangeNotifier>({
    Key? key,
    required T listenable,
    required T2 listenable2,
    required Widget Function(
            BuildContext context, T value, T2 value2, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.two(
          key: key,
          listenable: listenable,
          listenable2: listenable2,
          builder: (context, _, __, child) =>
              builder(context, listenable, listenable2, child),
          child: child);

  ListenableBuilder three<T extends ChangeNotifier, T2 extends ChangeNotifier,
          T3 extends ChangeNotifier>({
    Key? key,
    required T listenable,
    required T2 listenable2,
    required T3 listenable3,
    required Widget Function(
            BuildContext context, T value, T2 value2, T3 value3, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.three(
          key: key,
          listenable: listenable,
          listenable2: listenable2,
          listenable3: listenable3,
          builder: (context, _, __, ___, child) =>
              builder(context, listenable, listenable2, listenable3, child),
          child: child);
}

class ListenableBuilderValueCompanion {
  const ListenableBuilderValueCompanion._();
}

extension ListenableBuilderValueFactory on ListenableBuilderValueCompanion {
  ListenableBuilder one<T>({
    Key? key,
    required ValueListenable<T> listenable,
    required Widget Function(BuildContext context, T value, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.one(
          key: key,
          listenable: listenable,
          builder: (context, _, child) =>
              builder(context, listenable.value, child),
          child: child);

  ListenableBuilder two<T, T2>({
    Key? key,
    required ValueListenable<T> listenable,
    required ValueListenable<T2> listenable2,
    required Widget Function(
            BuildContext context, T value, T2 value2, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.two(
          key: key,
          listenable: listenable,
          listenable2: listenable2,
          builder: (context, _, __, child) =>
              builder(context, listenable.value, listenable2.value, child),
          child: child);

  ListenableBuilder three<T, T2, T3>({
    Key? key,
    required ValueListenable<T> listenable,
    required ValueListenable<T2> listenable2,
    required ValueListenable<T3> listenable3,
    required Widget Function(
            BuildContext context, T value, T2 value2, T3 value3, Widget? child)
        builder,
    Widget? child,
  }) =>
      ListenableBuilder.three(
          key: key,
          listenable: listenable,
          listenable2: listenable2,
          listenable3: listenable3,
          builder: (context, _, __, ___, child) => builder(context,
              listenable.value, listenable2.value, listenable3.value, child),
          child: child);
}
