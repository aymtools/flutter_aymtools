import 'dart:async';

import 'package:async/async.dart';
import 'package:aymtools/src/widgets/widget_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import '../tools/stream_ext.dart';

typedef OnDynamicLoadedNotifier<T> = void Function(T data);

class _LoadCounter<T> {
  final Object keyForData;
  final void Function(Object keyForData) remove;
  final Duration? delayedDuration;
  int _count;

  int _lastLoadTime = 0;
  T? _last;
  Timer? _timer;

  _LoadCounter(this.keyForData, this.remove, this.delayedDuration)
      : _count = 0,
        _lastLoadTime = 0;

  void plusOne() {
    _timer?.cancel();
    _timer = null;
    _count++;
  }

  void minusOne() {
    if (--_count <= 0) {
      if (delayedDuration == null || delayedDuration == Duration.zero) {
        remove(keyForData);
      } else {
        _timer ??= Timer(delayedDuration!, () => remove(keyForData));
      }
    }
  }

  bool get isNeedLoad {
    return _count > 0 || _timer != null;
  }
}

class _RememberDynamicDataLoader<T> {
  final String? loaderName;

  _RememberDynamicDataLoader(this.loaderName);

  @override
  int get hashCode => Object.hashAll([T, loaderName]);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _RememberDynamicDataLoader<T> &&
            loaderName == other.loaderName);
  }
}

class DynamicDataLoader<T> {
  static final Map<_RememberDynamicDataLoader, DynamicDataLoader> _loaders = {};

  static DynamicDataLoader<T> get<T>([String? loaderName]) {
    final key = _RememberDynamicDataLoader<T>(loaderName);
    final loader = _loaders[key];
    assert(loader != null, 'Cannot find loader  (<$T> ${loaderName ?? ''})');
    assert(loader! is DynamicDataLoader<T>,
        'The found loader type does not match  (<$T> ${loaderName ?? ''})');
    return loader! as DynamicDataLoader<T>;
  }

  static DynamicDataLoader<T> makeLoader<K extends Object, T>(
    K Function(T data) makeKey,
    Future<List<T>> Function(List<K> ks) dataLoader, {
    String? loaderName,
    Stream<T>? otherSource,
    int loadInterval = 3000, // 加载间隔 单位毫秒
    int urgentLimitTime = 1000, // 距离下载数据时间内不触发紧急加载  单位毫秒
    int loaderSlices = 0, // 切片请求数量 <=0 为不限制 否则按照slices进行切片请求
    bool isRemembered = true, // 是否记录到缓存中 false时为独立控制
    int? delayedRemove, // 当计数器为0时是否延迟后移除 继续在队列中加载   单位毫秒
    int removedLoadTimes = 0, // 当计数器为0时在加载n次 继续在队列中加载
  }) {
    Duration? delayedRemoved = delayedRemove != null && delayedRemove > 0
        ? Duration(milliseconds: delayedRemove)
        : removedLoadTimes <= 0
            ? null
            : Duration(milliseconds: loadInterval * removedLoadTimes + 1);
    creator() => DynamicDataLoader._(
          (ks) => dataLoader(ks.whereType<K>().toList()),
          makeKey,
          (k) => k is K,
          urgentLimitTime: urgentLimitTime <= 0 ? 0 : urgentLimitTime,
          loaderSlices: loaderSlices,
          otherSource: otherSource,
          delayedRemoved: delayedRemoved,
        );

    DynamicDataLoader<T> loader;

    if (isRemembered) {
      final key = _RememberDynamicDataLoader<T>(loaderName);
      assert(!_loaders.containsKey(key),
          '<$T> ${loaderName ?? ''} Loader existed');
      loader = creator();
      _loaders[key] = loader;
    } else {
      loader = creator();
    }
    return loader;
  }

  final bool Function(Object key) _keyCheck;

  final Future<List<T>> Function(List<Object> ks) _dataLoader;
  final Object Function(T data) _makeKey;
  final int _urgentLimitTime;
  final int _loadInterval;

  final int _loaderSlices;
  final Stream<T>? _otherSource;
  final Duration? delayedRemoved;

  final Cancellable _cancellable;

  final Map<Object, _LoadCounter<T>> _loadingDynamic = {};

  late Stream<T> _stream;

  late StreamController _streamController;
  late StreamController<T> _streamControllerUrgent;

  final Set<Object> _urgentCache = {};

  DynamicDataLoader._(this._dataLoader, this._makeKey, this._keyCheck,
      {Stream<T>? otherSource,
      int loadInterval = 3000,
      int urgentLimitTime = 1000,
      int loaderSlices = 0,
      this.delayedRemoved,
      Cancellable? disposeCancellable})
      : _otherSource = otherSource,
        _loadInterval = loadInterval,
        _urgentLimitTime = urgentLimitTime,
        _loaderSlices = loaderSlices,
        _cancellable = disposeCancellable?.makeCancellable(infectious: true) ??
            Cancellable() {
    _initStream();
  }

  void dispose() {
    _cancellable.cancel();
  }

  _LoadCounter<T> _requiredLoadCounter(Object keyForData) {
    final r = _loadingDynamic.putIfAbsent(keyForData,
        () => _LoadCounter(keyForData, _loadingDynamic.remove, delayedRemoved));
    r.plusOne();
    return r;
  }

  _LoadCounter<T>? _findLoadCounter(Object keyForData) {
    return _loadingDynamic[keyForData];
  }

  _LoadCounter<T> _addLoaderCount(Object keyForData, Cancellable cancellable) {
    var lc = _requiredLoadCounter(keyForData);

    _streamController.onResume?.call();

    cancellable.whenCancel.then((_) => lc.minusOne());
    return lc;
  }

  List<_LoadCounter<T>> _addLoadCounters(
      Iterable<Object> ks, Cancellable cancellable) {
    if (ks.isEmpty) return <_LoadCounter<T>>[];

    var result = ks.map(_requiredLoadCounter);
    _streamController.onResume?.call();
    cancellable.whenCancel.then((_) {
      for (var lc in result) {
        lc.minusOne();
      }
    });
    return result.toList();
  }

  void _checkAndLoadUrgent() {
    Future.microtask(() {
      if (_urgentCache.isEmpty) return;
      final loads = _urgentCache.toList();
      _urgentCache.clear();
      _dataLoader(loads).then((value) {
        _recordLastLoad(value);
        return value;
      }).then((value) {
        for (var element in value) {
          _streamControllerUrgent.add(element);
        }
      });
    });
  }

  void _addUrgentLoad(_LoadCounter<T> lc) {
    _urgentCache.add(lc.keyForData);
    _checkAndLoadUrgent();
  }

  Stream<T> loadData(Object? keyForData,
      {Cancellable? cancellable, bool urgent = false}) async* {
    if (keyForData == null) return;
    assert(_keyCheck(keyForData),
        'DynamicDataLoader does not support this type (${keyForData.runtimeType}) of Key loading');
    cancellable = _cancellable.makeCancellable(father: cancellable);
    yield* _loadDynamic(keyForData, cancellable, urgent);
  }

  Stream<T> _loadDynamic(
      Object keyForData, Cancellable cancellable, bool urgent) async* {
    if (cancellable.isUnavailable) return;

    var lc = _addLoaderCount(keyForData, cancellable);

    ///紧急加载
    if (urgent == true) {
      /// 紧急加载动态数据
      if (_urgentLimitTime <= 0) {
        _addUrgentLoad(lc);
      } else if (lc._last != null &&
          DateTime.now().millisecondsSinceEpoch - lc._lastLoadTime <
              _urgentLimitTime) {
        /// 在队列中 距离上次加载不超过[urgentLimitTime]直接使用上次的数据
        yield lc._last!;
      } else if (!_streamControllerUrgent.isClosed) {
        _addUrgentLoad(lc);
      }
    }
    if (cancellable.isUnavailable) return;

    yield* _stream.where((event) => _makeKey(event) == keyForData);
  }

  void preloadDynamic(Iterable<Object> keys, {Cancellable? cancellable}) async {
    if (keys.isEmpty) return;
    assert(() {
      for (var element in keys) {
        assert(_keyCheck(element),
            'DynamicDataLoader does not support this type (${element.runtimeType}) of Key loading');
      }
      return true;
    }());
    cancellable = _cancellable.makeCancellable(father: cancellable);
    if (cancellable.isUnavailable) return;
    _addLoadCounters(keys, cancellable);
  }

  void addOnDynamicLoadedNotifier(Object keyForData,
      OnDynamicLoadedNotifier<T> notifier, Cancellable cancellable) {
    assert(_keyCheck(keyForData),
        'DynamicDataLoader does not support this type (${keyForData.runtimeType}) of Key loading');
    if (cancellable.isUnavailable) return;
    cancellable = _cancellable.makeCancellable(father: cancellable);
    _stream
        .where((event) => _makeKey(event) == keyForData)
        .bindCancellable(cancellable)
        .listen(notifier);
  }

  void addOnFirstLoadedNotifier(Object keyForData,
      OnDynamicLoadedNotifier<T> notifier, Cancellable cancellable) {
    assert(_keyCheck(keyForData),
        'DynamicDataLoader does not support this type (${keyForData.runtimeType}) of Key loading');
    cancellable = _cancellable.makeCancellable(father: cancellable);
    onceNotifier(T data) {
      if (cancellable.isAvailable) notifier(data);
      cancellable.cancel();
    }

    addOnDynamicLoadedNotifier(keyForData, onceNotifier, cancellable);
  }

  void _initStream() {
    var stream = _createStream();

    _streamControllerUrgent = StreamController();

    _cancellable
        .makeCancellable()
        .whenCancel
        .then((value) => _streamControllerUrgent.close());

    StreamController<T> otherWrapper = StreamController();
    _otherSource
        ?.bindCancellable(_cancellable)
        .onData(_recordLastLoadValue)
        .listen((event) => otherWrapper.add(event));

    _stream = StreamGroup.mergeBroadcast([
      stream,
      _streamControllerUrgent.stream,
      otherWrapper.stream,
    ]);
  }

  _recordLastLoadValue(T data) {
    var llt = DateTime.now().millisecondsSinceEpoch;
    final k = _makeKey(data);
    final lc = _findLoadCounter(k);
    if (lc == null) return;
    lc._lastLoadTime = llt;
    lc._last = data;
  }

  _recordLastLoad(List<T> data) {
    if (data.isEmpty) return;
    var llt = DateTime.now().millisecondsSinceEpoch;
    for (var e in data) {
      final k = _makeKey(e);
      final lc = _findLoadCounter(k);
      if (lc == null) continue;
      lc._lastLoadTime = llt;
      lc._last = e;
    }
  }

  Stream<T> _createStream() {
    if (_loadInterval <= 0) {
      return StreamController<T>().stream;
    }

    Duration period = Duration(milliseconds: _loadInterval);

    late StreamController controller;
    Stopwatch watch = Stopwatch();
    onListen() {
      void sendEvent(_) {
        watch.reset();
        controller.add(null);
      }

      Timer timer = Timer.periodic(period, sendEvent);
      controller
        ..onCancel = () {
          timer.cancel();
          return Future.value(null);
        }
        ..onPause = () {
          watch.stop();
          timer.cancel();
        }
        ..onResume = () {
          if (watch.isRunning || timer.isActive) return;
          Duration elapsed = watch.elapsed;
          watch.start();
          timer = Timer(period - elapsed, () {
            timer = Timer.periodic(period, sendEvent);
            sendEvent(null);
          });
        };
    }

    controller = StreamController(
        onListen: onListen,
        onPause: null,
        onResume: null,
        onCancel: null,
        sync: true);

    _cancellable
        .makeCancellable()
        .whenCancel
        .then((value) => controller.close());
    _streamController = controller;

    getKs() => _loadingDynamic.values
        .where((e) => e.isNeedLoad)
        .map((e) => e.keyForData)
        .toSet()
        .toList();

    final goOnOrPause =
        StreamTransformer<List<Object>, List<Object>>.fromHandlers(
            handleData: (data, sink) {
      if (data.isNotEmpty) {
        sink.add(data);
      } else {
        controller.onPause?.call();
      }
    });

    var loadKeys = controller.stream
        .skipWhile((_) => _cancellable.isUnavailable)
        .map((_) => getKs())
        .transform<List<Object>>(goOnOrPause);

    if (_loaderSlices > 0) {
      loadKeys = loadKeys
          .slices(_loaderSlices) //超过 [loaderSlices] 个请求需要拆分
          .expand((element) => element);
    }

    return loadKeys
        .asyncMap((event) => _dataLoader(event).catchError((err) => <T>[]))
        .onData(_recordLastLoad)
        .expand((event) => event);
  }
}

class DynamicLoadController extends InheritedWidget {
  final bool canLoad;

  const DynamicLoadController({bool? canLoad, super.key, required super.child})
      : canLoad = canLoad ?? true;

  @override
  bool updateShouldNotify(covariant DynamicLoadController oldWidget) {
    return canLoad != oldWidget.canLoad;
  }

  static DynamicLoadController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DynamicLoadController>();
  }

  static DynamicLoadController of(BuildContext context) {
    final DynamicLoadController? result = maybeOf(context);
    assert(result != null, 'No DynamicLoadController found in context');
    return result!;
  }

  static bool isCanLoad(BuildContext context, {bool listen = false}) {
    final bool result = maybeOf(context)?.canLoad ?? true;
    return result;
  }
}

Widget Function(BuildContext context, T? data, Widget? child) _builder<T>(
        Widget Function(BuildContext context, T data, Widget? child) builder) =>
    (BuildContext context, T? data, Widget? child) =>
        builder(context, data as T, child);

class DynamicLoadBuilder<T> extends StatefulWidget {
  ///指定加载器名字
  final String? loaderName;

  ///需要加载的数据 的key
  final Object? keyForData;

  final Widget? child;

  final T? initData;

  /// 另一个提供数据的源
  final Stream<T>? otherSource;

  ///构建widget
  final Widget Function(BuildContext context, T? data, Widget? child) builder;

  /// 数据刷新次数 <0：为无限次 =0：为不加载
  final int requestCount;

  /// 对于数据是否是急迫的刷新
  final bool urgent;

  /// 延迟加载 单位毫秒
  final int delayedLoad;

  ///对于 首次加载成功后回执行回调
  final void Function(T data)? onFirstLoaded;

  ///对于 加载成功后 执行回调
  final void Function(T data)? onLoadedNotifier;

  const DynamicLoadBuilder(
      {super.key,
      this.initData,
      this.keyForData,
      required this.builder,
      this.child,
      this.requestCount = -1,
      this.urgent = false,
      this.onFirstLoaded,
      this.onLoadedNotifier,
      this.loaderName,
      this.otherSource,
      this.delayedLoad = 0})
      : assert(!(keyForData == null && initData == null),
            'keyForData or initData must not null');

  const DynamicLoadBuilder.key(
      {super.key,
      required this.keyForData,
      required this.builder,
      this.child,
      this.requestCount = -1,
      this.urgent = false,
      this.onFirstLoaded,
      this.onLoadedNotifier,
      this.loaderName,
      this.otherSource,
      this.delayedLoad = 0})
      : initData = null;

  DynamicLoadBuilder.value(
      {super.key,
      required T this.initData,
      required Widget Function(BuildContext context, T data, Widget? child)
          builder,
      this.child,
      this.requestCount = -1,
      this.urgent = false,
      this.onFirstLoaded,
      this.onLoadedNotifier,
      this.loaderName,
      this.otherSource,
      this.delayedLoad = 0})
      : keyForData = null,
        builder = _builder(builder);

  @override
  State<DynamicLoadBuilder> createState() => _DynamicLoadBuilderState<T>();
}

class _DynamicLoadBuilderState<T> extends State<DynamicLoadBuilder<T>>
    with CancellableState {
  late Object? _k;
  Stream<T>? _stream;
  Cancellable? _cancellable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DynamicLoadBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loaderName != oldWidget.loaderName) {
      _reload();
    } else if (widget.keyForData != oldWidget.keyForData ||
        widget.initData != oldWidget.initData) {
      final loader = DynamicDataLoader.get<T>(widget.loaderName);
      final next = widget.initData ??
          (widget.initData == null
              ? null
              : loader._makeKey(widget.initData as T));
      if (_k != next) {
        _reload();
      }
    }
  }

  _reload() {
    _cancellable?.cancel();
    _cancellable = null;
    _loadData();
  }

  _loadData() async {
    if (DynamicLoadController.maybeOf(context)?.canLoad == false) return;
    if (_cancellable?.isAvailable == true) return;
    if (widget.keyForData == null && widget.initData == null) return;

    final cancellable = makeCancellable();
    cancellable.onCancel.then((value) => _stream = null);
    _cancellable = cancellable;

    if (widget.delayedLoad > 0) {
      await Future.delayed(Duration(milliseconds: widget.delayedLoad));
      if (cancellable.isUnavailable) return;
    }

    final loader = DynamicDataLoader.get<T>(widget.loaderName);

    _k = widget.keyForData ?? loader._makeKey(widget.initData as T);

    _makeStream(cancellable, loader, _k!, widget.requestCount, widget.urgent,
        widget.otherSource);
  }

  void _makeStream(
      Cancellable cancellable,
      DynamicDataLoader<T> loader,
      Object keyForData,
      int requestCount,
      bool urgent,
      Stream<T>? otherSource) {
    if (cancellable.isUnavailable) return;

    // 处于延迟加载时 进行延迟加载从处理
    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        scheduleMicrotask(() => _makeStream(cancellable, loader, keyForData,
            requestCount, urgent, otherSource));
      });
      return;
    }

    if (requestCount == 0) {
    } else if (requestCount < 0) {
      _stream =
          loader.loadData(keyForData, cancellable: cancellable, urgent: urgent);
    } else {
      _stream = loader
          .loadData(keyForData, cancellable: cancellable, urgent: urgent)
          .take(requestCount);
    }
    if (otherSource != null) {
      if (_stream == null) {
        _stream = otherSource;
      } else {
        _stream = StreamGroup.merge(<Stream<T>>[
          _stream!,
          otherSource,
        ]);
      }
    }

    if (_stream != null) {
      if (widget.onLoadedNotifier != null) {
        _stream?.bindCancellable(cancellable).listen(widget.onLoadedNotifier);
      }
      if (widget.onFirstLoaded != null) {
        final c = cancellable.makeCancellable();
        onceNotifier(T data) {
          if (c.isUnavailable) widget.onFirstLoaded?.call(data);
          c.cancel();
        }

        _stream?.bindCancellable(c).listen(onceNotifier);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _stream == null
        ? widget.builder(context, widget.initData, widget.child)
        : StreamBuilder<T>(
            initialData: widget.initData,
            stream: _stream,
            builder: (context, snapshot) => widget.builder(
                context, snapshot.data ?? widget.initData, widget.child),
          );
  }
}
