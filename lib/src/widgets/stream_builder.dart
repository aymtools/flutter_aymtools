import 'package:flutter/material.dart';

typedef StrmWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot, Widget? child);

class StrmBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  const StrmBuilder({
    super.key,
    this.initialData,
    required super.stream,
    required this.builder,
    this.child,
  });

  final StrmWidgetBuilder<T> builder;
  final T? initialData;
  final Widget? child;

  @override
  AsyncSnapshot<T> initial() => initialData == null
      ? AsyncSnapshot<T>.nothing()
      : AsyncSnapshot<T>.withData(ConnectionState.none, initialData as T);

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(
      AsyncSnapshot<T> current, Object error, StackTrace stackTrace) {
    return AsyncSnapshot<T>.withError(
        ConnectionState.active, error, stackTrace);
  }

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) =>
      builder(context, currentSummary, child);

  factory StrmBuilder.notNull({
    Key? key,
    required T initialData,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget? child)
        builder,
    Widget Function(BuildContext context, Object? error, StackTrace? stackTrace,
            Widget? child)?
        builderErr,
    Widget? child,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      initialData: initialData,
      stream: stream,
      child: child,
      builder: (context, snapshot, child) {
        if (builderErr != null && snapshot.hasError) {
          return builderErr(
              context, snapshot.error, snapshot.stackTrace, child);
        }
        final data = snapshot.hasData ? snapshot.requireData : initialData;
        return builder(context, data, child);
      },
    );
  }

  factory StrmBuilder.notNullAC({
    Key? key,
    required T initialData,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget child)
        builder,
    Widget Function(BuildContext context, Object? error, StackTrace? stackTrace,
            Widget child)?
        builderErr,
    required Widget child,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      initialData: initialData,
      stream: stream,
      child: child,
      builder: (context, snapshot, child) {
        if (builderErr != null && snapshot.hasError) {
          return builderErr(
              context, snapshot.error, snapshot.stackTrace, child!);
        }
        final data = snapshot.hasData ? snapshot.requireData : initialData;
        return builder(context, data, child!);
      },
    );
  }

  factory StrmBuilder.loading({
    Key? key,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget? child)
        builder,
    required Widget Function(BuildContext context, Widget? child)
        builderLoading,
    required Widget Function(BuildContext context, Object? error,
            StackTrace? stackTrace, Widget? child)
        builderErr,
    Widget? child,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      stream: stream,
      child: child,
      builder: (context, snapshot, child) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builderLoading(context, child);
        }
        if (snapshot.hasError) {
          return builderErr(
              context, snapshot.error, snapshot.stackTrace, child);
        }
        final data = snapshot.requireData;
        return builder(context, data, child);
      },
    );
  }

  factory StrmBuilder.loadingNNC({
    Key? key,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget child)
        builder,
    required Widget Function(BuildContext context, Widget child) builderLoading,
    required Widget Function(BuildContext context, Object? error,
            StackTrace? stackTrace, Widget child)
        builderErr,
    Widget? child,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      stream: stream,
      child: child,
      builder: (context, snapshot, child) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builderLoading(context, child!);
        }
        if (snapshot.hasError) {
          return builderErr(
              context, snapshot.error, snapshot.stackTrace, child!);
        }
        final data = snapshot.requireData;
        return builder(context, data, child!);
      },
    );
  }
}

class _Token<T> {
  Type typeOf() => T;

  bool isNullable() => typeOf() == _Token<T?>().typeOf();
}

typedef StreamWidgetBuilder1<T> = Widget Function(
    BuildContext context, T data, Widget? child);
