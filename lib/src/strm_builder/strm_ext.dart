part of 'strm_builder.dart';

class StrmBuilderCompanion {
  const StrmBuilderCompanion._();
}

class StrmBuilderConfigurationCompanion {
  const StrmBuilderConfigurationCompanion._();
}

const StrmImpl Strm = StrmImpl._();

class StrmImpl {
  const StrmImpl._();

  final StrmBuilderCompanion Builder = const StrmBuilderCompanion._();

  final StrmBuilderLoaderCompanion Loader =
      const StrmBuilderLoaderCompanion._();

  final StrmBuilderUpdatingCompanion Updater =
      const StrmBuilderUpdatingCompanion._();
  final StrmBuilderConfigurationCompanion Config =
      const StrmBuilderConfigurationCompanion._();
}

extension StrmBuilderImpl on StrmImpl {
  Widget builder<T>({
    Key? key,
    T? initialData,
    required Stream<T> stream,
    required AsyncWidgetBuilder<T> builder,
  }) =>
      StrmBuilder<T>(
          key: key,
          initialData: initialData,
          stream: stream,
          builder: (context, snapshot, _) => builder(context, snapshot));

  Widget config({
    Key? key,
    required Widget Function(BuildContext context) builderLoading,
    required Widget Function(BuildContext context, Object error,
            StackTrace? stackTrace, void Function()? retry)
        builderLoadErr,
    required Widget Function(BuildContext context, Widget loadingWidget)
        builderSliverLoading,
    required Widget Function(
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
            void Function()? retry,
            Widget loadErrWidget)
        builderSliverLoadErr,
    required Widget child,
  }) =>
      StrmBuilderConfiguration(
          key: key,
          builderLoading: builderLoading,
          builderLoadErr: builderLoadErr,
          builderSliverLoading: builderSliverLoading,
          builderSliverLoadErr: builderSliverLoadErr,
          child: child);
}

extension StrmBuilderCompanionImpl on StrmBuilderCompanion {
  Widget child<T>(
          {Key? key,
          T? initialData,
          required Stream<T> stream,
          required StrmWidgetBuilder<T> builder,
          Widget? child}) =>
      StrmBuilder(
        key: key,
        initialData: initialData,
        stream: stream,
        builder: builder,
        child: child,
      );
}

extension StrmLoaderCompanionImpl on StrmBuilderLoaderCompanion {

}

extension StrmUpdatingCompanionImpl on StrmBuilderUpdatingCompanion {}

extension StrmWithListenableCompanionImpl
    on StrmBuilderWithListenableCompanion {}

main() {}
