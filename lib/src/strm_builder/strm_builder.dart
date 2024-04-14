import 'package:flutter/material.dart';

part 'strm_ext.dart';

class _Token<T> {
  Type typeOf() => T;

  bool isNullable() => typeOf() == _Token<T?>().typeOf();
}

typedef StrmWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot, Widget? child);

class StrmBuilderConfiguration extends StatelessWidget {
  final Widget Function(BuildContext context) builderLoading;
  final Widget Function(BuildContext context, Object error,
      StackTrace? stackTrace, void Function()? retry) builderLoadErr;

  final Widget Function(BuildContext context, Widget loadingWidget)
      builderSliverLoading;
  final Widget Function(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
      void Function()? retry,
      Widget loadErrWidget) builderSliverLoadErr;

  final Widget child;

  const StrmBuilderConfiguration(
      {super.key,
      required this.builderLoading,
      required this.builderLoadErr,
      required this.builderSliverLoading,
      required this.builderSliverLoadErr,
      required this.child});

  StrmBuilderConfiguration.sliverFillViewport(
      {super.key,
      required this.builderLoading,
      required this.builderLoadErr,
      required this.child})
      : builderSliverLoading = builderSliverFillViewportLoading(),
        builderSliverLoadErr = builderSliverFillViewportLoadError();

  StrmBuilderConfiguration.sliverFillRemaining(
      {super.key,
      required this.builderLoading,
      required this.builderLoadErr,
      required this.child})
      : builderSliverLoading = builderSliverFillRemainingLoading(),
        builderSliverLoadErr = builderSliverFillRemainingLoadError();

  StrmBuilderConfiguration.sliverToBoxAdapter(
      {super.key,
      required this.builderLoading,
      required this.builderLoadErr,
      required this.child})
      : builderSliverLoading = builderSliverToBoxAdapterLoading(),
        builderSliverLoadErr = builderSliverToBoxAdapterLoadError();

  static Widget Function(BuildContext, Widget)
      builderSliverFillViewportLoading() {
    return (_, loading) => SliverFillViewport(
        delegate: SliverChildListDelegate(<Widget>[loading]));
  }

  static Widget Function(
          BuildContext, Object, StackTrace?, void Function()?, Widget)
      builderSliverFillViewportLoadError() {
    return (_, __, ___, ____, loadError) => SliverFillViewport(
        delegate: SliverChildListDelegate(<Widget>[loadError]));
  }

  static Widget Function(BuildContext, Widget)
      builderSliverFillRemainingLoading() {
    return (_, loading) => SliverFillRemaining(child: loading);
  }

  static Widget Function(
          BuildContext, Object, StackTrace?, void Function()?, Widget)
      builderSliverFillRemainingLoadError() {
    return (_, __, ___, ____, loadError) =>
        SliverFillRemaining(child: loadError);
  }

  static Widget Function(BuildContext, Widget)
      builderSliverToBoxAdapterLoading() {
    return (_, loading) => SliverToBoxAdapter(child: loading);
  }

  static Widget Function(
          BuildContext, Object, StackTrace?, void Function()?, Widget)
      builderSliverToBoxAdapterLoadError() {
    return (_, __, ___, ____, loadError) =>
        SliverToBoxAdapter(child: loadError);
  }

  @override
  Widget build(BuildContext context) {
    return _StrmBuilderConfiguration(
      builderLoading: builderLoading,
      builderLoadErr: builderLoadErr,
      builderSliverLoading: builderSliverLoading,
      builderSliverLoadErr: builderSliverLoadErr,
      child: child,
    );
  }

  static Widget getLoading(BuildContext context) {
    return _StrmBuilderConfiguration.of(context).builderLoading(context);
  }

  static Widget getLoadError(BuildContext context,
      {required Object error, StackTrace? stackTrace, void Function()? retry}) {
    return _StrmBuilderConfiguration.of(context)
        .builderLoadErr(context, error, stackTrace, retry);
  }

  static Widget getSliverLoading(BuildContext context) {
    final config = _StrmBuilderConfiguration.of(context);
    return config.builderSliverLoading(context, config.builderLoading(context));
  }

  static Widget getSliverLoadError(BuildContext context,
      {required Object error, StackTrace? stackTrace, void Function()? retry}) {
    final config = _StrmBuilderConfiguration.of(context);
    return config.builderSliverLoadErr(context, error, stackTrace, retry,
        config.builderLoadErr(context, error, stackTrace, retry));
  }
}

class _StrmBuilderConfiguration extends InheritedWidget {
  final Widget Function(BuildContext context) builderLoading;
  final Widget Function(BuildContext context, Object error,
      StackTrace? stackTrace, void Function()? retry) builderLoadErr;

  final Widget Function(BuildContext context, Widget loadingWidget)
      builderSliverLoading;
  final Widget Function(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
      void Function()? retry,
      Widget loadErrWidget) builderSliverLoadErr;

  const _StrmBuilderConfiguration({
    super.key,
    required Widget child,
    required this.builderLoading,
    required this.builderLoadErr,
    required this.builderSliverLoading,
    required this.builderSliverLoadErr,
  }) : super(child: child);

  static _StrmBuilderConfiguration of(BuildContext context) {
    final _StrmBuilderConfiguration? result =
        context.dependOnInheritedWidgetOfExactType<_StrmBuilderConfiguration>();
    assert(result != null, 'No _StrmBuilderConfiguration found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_StrmBuilderConfiguration old) {
    return builderLoading != old.builderLoadErr ||
        builderLoadErr != old.builderLoadErr ||
        builderSliverLoading != old.builderSliverLoading ||
        builderSliverLoadErr != old.builderSliverLoadErr;
  }
}

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
    Widget? Function(BuildContext context, Object error, StackTrace? stackTrace,
            Widget? child)?
        builderErr,
    Widget? child,
    bool? useSliver,
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
        if (snapshot.hasError) {
          if (builderErr != null) {
            Widget? err = builderErr(
                context, snapshot.error!, snapshot.stackTrace, child);
            if (err != null) return err;
          } else if (useSliver != null) {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }

        final data = snapshot.hasData ? snapshot.requireData : initialData;
        return builder(context, data, child);
      },
    );
  }

  factory StrmBuilder.notNullNC({
    Key? key,
    required T initialData,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data) builder,
    Widget? Function(
            BuildContext context, Object error, StackTrace? stackTrace)?
        builderErr,
    bool? useSliver,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      initialData: initialData,
      stream: stream,
      builder: (context, snapshot, child) {
        if (snapshot.hasError) {
          if (builderErr != null) {
            Widget? err =
                builderErr(context, snapshot.error!, snapshot.stackTrace);
            if (err != null) return err;
          }
          if (useSliver != null) {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }

        final data = snapshot.hasData ? snapshot.requireData : initialData;
        return builder(context, data);
      },
    );
  }

  factory StrmBuilder.notNullAC({
    Key? key,
    required T initialData,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget child)
        builder,
    Widget? Function(BuildContext context, Object error, StackTrace? stackTrace,
            Widget child)?
        builderErr,
    required Widget child,
    bool? useSliver,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      initialData: initialData,
      stream: stream,
      child: child,
      builder: (context, snapshot, _) {
        if (snapshot.hasError) {
          if (builderErr != null) {
            Widget? err = builderErr(
                context, snapshot.error!, snapshot.stackTrace, child);
            if (err != null) return err;
          }
          if (useSliver != null) {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }
        final data = snapshot.hasData ? snapshot.requireData : initialData;
        return builder(context, data, child);
      },
    );
  }

  factory StrmBuilder.loading({
    Key? key,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget? child)
        builder,
    Widget Function(BuildContext context, Widget? child)? builderLoading,
    Widget Function(BuildContext context, Object? error, StackTrace? stackTrace,
            Widget? child)?
        builderErr,
    Widget? child,
    bool useSliver = false,
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
          if (builderLoading != null) {
            return builderLoading(context, child);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoading(context)
                : StrmBuilderConfiguration.getLoading(context);
          }
        }
        if (snapshot.hasError) {
          if (builderErr != null) {
            return builderErr(
                context, snapshot.error, snapshot.stackTrace, child);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }
        final data = snapshot.requireData;
        return builder(context, data, child);
      },
    );
  }

  factory StrmBuilder.loadingNC({
    Key? key,
    required Stream<T> stream,
    required Widget Function(
      BuildContext context,
      T data,
    ) builder,
    Widget Function(BuildContext context)? builderLoading,
    Widget Function(
      BuildContext context,
      Object? error,
      StackTrace? stackTrace,
    )? builderErr,
    bool useSliver = false,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      stream: stream,
      builder: (context, snapshot, child) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (builderLoading != null) {
            return builderLoading(context);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoading(context)
                : StrmBuilderConfiguration.getLoading(context);
          }
        }
        if (snapshot.hasError) {
          if (builderErr != null) {
            return builderErr(context, snapshot.error, snapshot.stackTrace);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }
        final data = snapshot.requireData;
        return builder(context, data);
      },
    );
  }

  factory StrmBuilder.loadingAC({
    Key? key,
    required Stream<T> stream,
    required Widget Function(BuildContext context, T data, Widget child)
        builder,
    Widget Function(BuildContext context, Widget child)? builderLoading,
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace,
            Widget child)?
        builderErr,
    required Widget child,
    bool useSliver = false,
  }) {
    assert(() {
      return !_Token<T>().isNullable();
    }(), '$T must not Nullable');
    return StrmBuilder<T>(
      key: key,
      stream: stream,
      child: child,
      builder: (context, snapshot, _) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (builderLoading != null) {
            return builderLoading(context, child);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoading(context)
                : StrmBuilderConfiguration.getLoading(context);
          }
        }
        if (snapshot.hasError) {
          if (builderErr != null) {
            return builderErr(
                context, snapshot.error!, snapshot.stackTrace, child);
          } else {
            return useSliver
                ? StrmBuilderConfiguration.getSliverLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace)
                : StrmBuilderConfiguration.getLoadError(context,
                    error: snapshot.error!, stackTrace: snapshot.stackTrace);
          }
        }
        final data = snapshot.requireData;
        return builder(context, data, child);
      },
    );
  }

  static const StrmBuilderWithListenableCompanion withListenable =
      StrmBuilderWithListenableCompanion._();

  static const StrmBuilderLoaderCompanion loader =
      StrmBuilderLoaderCompanion._();

  static const StrmBuilderUpdatingCompanion updater =
      StrmBuilderUpdatingCompanion._();
}

class StrmBuilderLoaderCompanion {
  const StrmBuilderLoaderCompanion._();
}

class StrmBuilderUpdatingCompanion {
  const StrmBuilderUpdatingCompanion._();
}

class StrmBuilderWithListenableCompanion {
  const StrmBuilderWithListenableCompanion._();
}
