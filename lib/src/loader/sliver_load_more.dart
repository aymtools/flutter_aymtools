import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef LoadMoreEnd = void Function(bool loadOk, [bool loadFinish]);
typedef LoadMoreCallback = void Function(LoadMoreEnd);

enum LoadMoreStatus {
  readyToLoad,
  loading,
  success,
  failure,
}

class LoadMoreController {
  final ValueNotifier<LoadMoreStatus> _status =
      ValueNotifier<LoadMoreStatus>(LoadMoreStatus.readyToLoad);

  LoadMoreCallback? _loadingCallback;

  LoadMoreStatus get loadMoreStatus => _status.value;

  set loadingCallBack(LoadMoreCallback callback) {
    _loadingCallback = callback;
  }

  void callLoadMore() {
    var state = _status.value;
    if (state == LoadMoreStatus.readyToLoad ||
        state == LoadMoreStatus.failure) {
      _status.value = LoadMoreStatus.loading;
      _loadingCallback?.call(loadEnd);
    }
  }

  void loadEnd(bool loadOk, [bool loadFinish = false]) {
    if (_status.value != LoadMoreStatus.loading) {
      return;
    }
    if (loadOk) {
      if (loadFinish) {
        _status.value = LoadMoreStatus.success;
      } else {
        _status.value = LoadMoreStatus.readyToLoad;
      }
    } else {
      _status.value = LoadMoreStatus.failure;
    }
  }

  set loadTask(Future Function() task) {
    loadingCallBack = (LoadMoreEnd loadEnd) {
      task
          .call()
          .then((value) => loadEnd(true, false))
          .catchError((err) => loadEnd(false));
    };
  }
}

typedef BuildFailWidget = Widget Function(VoidCallback retry);

class SliverLoadMore extends StatefulWidget {
  final Widget readyToLoad;
  final Widget loading;
  final BuildFailWidget loadedFail;
  final Widget loadedFinish;

  SliverLoadMore({
    super.key,
    required this.loading,
    required this.loadedFail,
    Widget? loadedFinish,
    Widget? readyToLoad,
  })  : loadedFinish = loadedFinish ?? Container(),
        readyToLoad = readyToLoad ?? loading;

  @override
  State<SliverLoadMore> createState() => _SliverLoadMoreState();
}

class _SliverLoadMoreState extends State<SliverLoadMore> {
  LoadMoreController? _controller;

  late VoidCallback _refreshState;

  @override
  void initState() {
    super.initState();
    _refreshState = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var controller = context
        .findAncestorStateOfType<SliverLoadMoreControllerState>()
        ?._controller;
    if (controller == _controller) {
      return;
    }
    if (_controller != null) {
      _controller?._status.removeListener(_refreshState);
    }
    _controller = controller;
    _controller?._status.addListener(_refreshState);
  }

  @override
  Widget build(BuildContext context) {
    var state = context
            .findAncestorStateOfType<SliverLoadMoreControllerState>()
            ?._controller
            .loadMoreStatus ??
        LoadMoreStatus.success;
    Widget result;
    switch (state) {
      case LoadMoreStatus.readyToLoad:
        result = widget.loading;
        break;
      case LoadMoreStatus.loading:
        result = widget.loading;
        break;
      case LoadMoreStatus.success:
        result = widget.loadedFinish;
        break;
      case LoadMoreStatus.failure:
        result = widget.loadedFail.call(_controller!.callLoadMore);
        break;
    }
    return _SliverLoadMoreAdapter(child: result);
  }
}

class _SliverLoadMoreAdapter extends SliverToBoxAdapter {
  @override
  SingleChildRenderObjectElement createElement() {
    return _SliverLoadMoreAdapterElement(this);
  }

  const _SliverLoadMoreAdapter({super.child});
}

class _SliverLoadMoreAdapterElement extends SingleChildRenderObjectElement {
  _SliverLoadMoreAdapterElement(SingleChildRenderObjectWidget widget)
      : super(widget);
}

///paintExtent 已经在屏幕上绘制了多少  maxPaintExtent完全绘制需要多大空间   return true触发加载更多 false不触发加载
typedef CheckCanLoadMore = bool Function(
    double paintExtent, double maxPaintExtent);

//除以2是为了更方便的触发刷新信息，否则比较难以触发
bool _defCheckCanLoadMore(double p, double m) => p >= m / 2;

class SliverLoadMoreController extends StatefulWidget {
  final Widget child;
  final LoadMoreController? controller;
  final CheckCanLoadMore _canLoadMore;

  const SliverLoadMoreController(
      {super.key,
      required this.child,
      this.controller,
      CheckCanLoadMore? canLoadMore})
      : _canLoadMore = canLoadMore ?? _defCheckCanLoadMore;

  @override
  SliverLoadMoreControllerState createState() =>
      SliverLoadMoreControllerState();
}

class SliverLoadMoreControllerState extends State<SliverLoadMoreController>
    with LoadMoreController {
  late LoadMoreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? this;
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      _checkCanLoadMore(context);
    });
  }

  @override
  void didUpdateWidget(covariant SliverLoadMoreController oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller = widget.controller ?? this;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: _handlerScrollEnd,
      child: widget.child,
    );
  }

  bool _handlerScrollEnd(ScrollEndNotification noti) {
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      final context = noti.context;
      if (context == null) return;
      _checkCanLoadMore(context);
    });

    return false;
  }

  void _checkCanLoadMore(BuildContext context) {
    _SliverLoadMoreAdapterElement? find = _findSLMAE(context as Element);
    if (find == null) {
      return;
    }
    var render = find.renderObject as RenderSliverToBoxAdapter;
    if (render.geometry?.visible == true) {
      if (widget._canLoadMore(
          render.geometry!.paintExtent, render.geometry!.maxPaintExtent)) {
        _controller.callLoadMore();
      }
    }
  }

  _SliverLoadMoreAdapterElement? _findSLMAE(Element? element) {
    if (element == null) return null;
    if (element is _SliverLoadMoreAdapterElement) {
      return element;
    }
    _SliverLoadMoreAdapterElement? target;
    element.visitChildElements((e) => target ??= _findSLMAE(e));
    return target;
  }
}
