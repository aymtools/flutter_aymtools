import 'dart:async';

import 'package:async/async.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import 'stream_ext.dart';
import 'widget_ext.dart';

typedef OnDynamicLoadedNotifier<T> = void Function(T data);

class _LoadCounter<K, T> {
  final K keyForData;
  final void Function(K keyForData) remove;
  int count;

  int lastLoadTime = 0;
  T? last;

  _LoadCounter(this.keyForData, this.remove)
      : count = 0,
        lastLoadTime = 0;

  void minusOne() {
    if (--count <= 0) {
      remove(keyForData);
    }
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

class DynamicDataLoader<K, T> {
  static final Map<_RememberDynamicDataLoader, DynamicDataLoader> _loaders = {};

  static DynamicDataLoader<K, T> get<K, T>([String? loaderName]) {
    final key = _RememberDynamicDataLoader<T>(loaderName);
    final loader = _loaders[key];
    assert(loader != null, 'Cannot find loader  (<$K,$T> ${loaderName ?? ''})');
    assert(loader! is DynamicDataLoader<K, T>,
        'The found loader type does not match  (<$K,$T> ${loaderName ?? ''})');
    return loader! as DynamicDataLoader<K, T>;
  }

  static void makeLoader<K, T>(
    K Function(T data) makeKey,
    Future<List<T>> Function(List<K> ks) dataLoader, {
    String? loaderName,
    Stream<T>? otherSource,
    int loadInterval = 3000, // 加载间隔 单位毫秒
    int urgentLimitTime = 1000, // 距离下载数据时间内不触发紧急加载  单位毫秒
    int loaderSlices = 0, // 切片请求数量 <=0 为不限制 否则按照slices进行切片请求
  }) {
    final key = _RememberDynamicDataLoader<T>(loaderName);
    assert(!_loaders.containsKey(key),
        '<$K,$T> ${loaderName ?? ''} Loader existed');

    DynamicDataLoader<K, T> loader = DynamicDataLoader._(dataLoader, makeKey,
        urgentLimitTime: urgentLimitTime,
        loaderSlices: loaderSlices,
        otherSource: otherSource);

    _loaders[key] = loader;
  }

  final Future<List<T>> Function(List<K> ks) _dataLoader;
  final K Function(T data) _makeKey;
  final int _urgentLimitTime;
  final int _loadInterval;

  final int _loaderSlices;
  final Stream<T>? _otherSource;

  final Cancellable _cancellable;

  final Map<K, _LoadCounter<K, T>> _loadingDynamic = {};

  late Stream<T> _stream;

  late StreamController _streamController;
  late StreamController<T> _streamControllerUrgent;

  final Set<K> _urgentCache = {};

  DynamicDataLoader._(this._dataLoader, this._makeKey,
      {Stream<T>? otherSource,
      int loadInterval = 3000,
      int urgentLimitTime = 1000,
      int loaderSlices = 0})
      : _otherSource = otherSource,
        _loadInterval = loadInterval,
        _urgentLimitTime = urgentLimitTime,
        _loaderSlices = loaderSlices,
        _cancellable = Cancellable() {
    _initStream();
  }

  void dispose() {
    _cancellable.cancel();
  }

  _LoadCounter<K, T> _requiredLoadCounter(K keyForData) {
    final r = _loadingDynamic.putIfAbsent(
        keyForData, () => _LoadCounter(keyForData, _loadingDynamic.remove));
    r.count++;
    return r;
  }

  _LoadCounter<K, T>? _findLoadCounter(K keyForData) {
    return _loadingDynamic[keyForData];
  }

  _LoadCounter<K, T> _addLoaderCount(K keyForData, Cancellable cancellable) {
    var lc = _requiredLoadCounter(keyForData);

    _streamController.onResume?.call();

    cancellable.whenCancel.then((_) => lc.minusOne());
    return lc;
  }

  List<_LoadCounter<K, T>> _addLoadCounters(
      Iterable<K> ks, Cancellable cancellable) {
    if (ks.isEmpty) return <_LoadCounter<K, T>>[];

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

  void _addUrgentLoad(_LoadCounter<K, T> lc) {
    _urgentCache.add(lc.keyForData);
    _checkAndLoadUrgent();
  }

  Stream<T> loadData(K keyForData,
      {Cancellable? cancellable, bool urgent = false}) async* {
    if (keyForData == null) return;
    cancellable = _cancellable.makeCancellable(father: cancellable);
    yield* _loadDynamic(keyForData, cancellable, urgent);
  }

  Stream<T> _loadDynamic(
      K keyForData, Cancellable cancellable, bool urgent) async* {
    if (cancellable.isUnavailable) return;

    var lc = _addLoaderCount(keyForData, cancellable);

    ///紧急加载
    if (urgent == true) {
      /// 紧急加载动态数据
      if (lc.last != null &&
          DateTime.now().microsecondsSinceEpoch - lc.lastLoadTime <
              _urgentLimitTime) {
        /// 在队列中 距离上次加载不超过[urgentLimitTime]直接使用上次的数据
        yield lc.last!;
      } else if (!_streamControllerUrgent.isClosed) {
        _addUrgentLoad(lc);
      }
    }
    if (cancellable.isUnavailable) return;

    yield* _stream.where((event) => _makeKey(event) == keyForData);
  }

  void preloadDynamic(Iterable<K> keys, {Cancellable? cancellable}) async {
    if (keys.isEmpty) return;
    cancellable = _cancellable.makeCancellable(father: cancellable);
    if (cancellable.isUnavailable) return;
    _addLoadCounters(keys, cancellable);
  }

  void addOnDynamicLoadedNotifier(K keyForData,
      OnDynamicLoadedNotifier<T> notifier, Cancellable cancellable) {
    if (cancellable.isUnavailable) return;
    cancellable = _cancellable.makeCancellable(father: cancellable);
    _stream
        .where((event) => _makeKey(event) == keyForData)
        .bindCancellable(cancellable)
        .listen(notifier);
  }

  void addOnFirstLoadedNotifier(K keyForData,
      OnDynamicLoadedNotifier<T> notifier, Cancellable cancellable) {
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
        .listen((event) => otherWrapper.add(event));

    _stream = StreamGroup.mergeBroadcast([
      stream,
      _streamControllerUrgent.stream,
      otherWrapper.stream,
    ]);
  }

  _recordLastLoad(List<T> data) {
    if (data.isEmpty) return;
    var llt = DateTime.now().microsecondsSinceEpoch;
    for (var e in data) {
      final k = _makeKey(e);
      final lc = _findLoadCounter(k);
      if (lc == null) continue;
      lc.lastLoadTime = llt;
      lc.last = e;
    }
  }

  Stream<T> _createStream() {
    Duration period = Duration(seconds: _loadInterval);

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
        .where((e) => e.count > 0)
        .map((e) => e.keyForData)
        .toSet()
        .toList();

    final goOnOrPause = StreamTransformer<List<K>, List<K>>.fromHandlers(
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
        .transform<List<K>>(goOnOrPause);

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

  const DynamicLoadController(this.canLoad, {super.key, required super.child});

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
    final bool result = of(context).canLoad;
    return result;
  }
}

class DynamicLoadBuilder<K, T> extends StatefulWidget {
  ///指定加载器名字
  final String? loaderName;

  ///需要加载的数据 的key
  final K keyForData;

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
      : assert(keyForData != null, 'keyForData must not null');

  @override
  State<DynamicLoadBuilder> createState() => _DynamicLoadBuilderState<K, T>();
}

class _DynamicLoadBuilderState<K, T> extends State<DynamicLoadBuilder<K, T>>
    with CancellableState {
  Stream<T>? _stream;
  Cancellable? _cancellable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DynamicLoadBuilder<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyForData != oldWidget.keyForData) {
      _cancellable?.cancel();
      _cancellable = null;
      _loadData();
    }
  }

  _loadData() async {
    if (DynamicLoadController.maybeOf(context)?.canLoad == false) return;
    if (_cancellable?.isAvailable == true) return;
    if (widget.keyForData == null) return;

    final cancellable = makeCancellable();
    cancellable.onCancel.then((value) => _stream = null);
    _cancellable = cancellable;

    if (widget.delayedLoad > 0) {
      await Future.delayed(Duration(microseconds: widget.delayedLoad));
      if (cancellable.isUnavailable) return;
    }

    final loader = DynamicDataLoader.get<K, T>(widget.loaderName);
    _makeStream(cancellable, loader, widget.keyForData, widget.requestCount,
        widget.urgent, widget.otherSource);
  }

  void _makeStream(Cancellable cancellable, DynamicDataLoader<K, T> loader,
      K keyForData, int requestCount, bool urgent, Stream<T>? otherSource) {
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
            builder: (context, snapshot) =>
                widget.builder(context, snapshot.data, widget.child),
          );
  }
}
