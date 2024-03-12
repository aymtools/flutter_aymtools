import 'dart:convert';

import 'package:aymtools/src/widgets/widget_ext.dart';
import 'package:cancellable/cancellable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class JsonNodes {
  final int maxLevel;
  final List<Node> nodes;

  const JsonNodes(this.maxLevel, this.nodes);
}

class Node {
  final int level;
  final NodeType type;
  final dynamic value;
  final String path;

  Node(this.level, this.type, this.value, this.path);
}

enum NodeType {
  listStart,
  listIndex,
  listEnd,
  mapStart,
  mapKey,
  mapEnd,
  value,
}

class JTreeNode {
  JTreeNode._();

  JTreeNode? _parent;

  JTreeNode get parent => _parent!;

  bool get isRoot => _parent == null;

  late final String path;
  late final List<JTreeNode> _children = [];

  bool get hasChild => _children.isEmpty;

  List<JTreeNode> get children => List.of(_children);

  factory JTreeNode.root() {
    final r = JTreeNode._();
    r.path = '';
    return r;
  }

  JTreeNode makeChild({required String path}) {
    final r = JTreeNode._();
    r._parent = this;
    r.path = path;
    return r;
  }

  String get absolutePath {
    JTreeNode? n = this;
    String r = '';
    do {
      r = '${n!.path}.$r';
      n = n._parent;
    } while (n != null);
    if (r.endsWith('.')) {
      r.substring(0, r.length - 1);
    }
    return r;
  }
}

int _maxLevel = -1;
late JTreeNode _node;

JsonNodes _parsing(dynamic json) {
  List<Node> result = [];
  _maxLevel = 0;
  _node = JTreeNode.root();
  if (json is String &&
      (json.trim().startsWith('{') || json.trim().startsWith('['))) {
    return _parsing(jsonDecode(json));
  } else if (isPrimitive(json)) {
    result.add(Node(_maxLevel, NodeType.value, json, _node.absolutePath));
  } else if (json is List) {
    result.add(Node(_maxLevel, NodeType.listStart, json, _node.absolutePath));
    result.addAll(_jlist(_maxLevel, json));
  } else if (json is Map) {
    result.add(Node(_maxLevel, NodeType.mapStart, json, _node.absolutePath));
    result.addAll(_jmap(_maxLevel, json as Map<String, dynamic>));
  }
  return JsonNodes(_maxLevel, result);
}

List<Node> _jp(int level, dynamic json) {
  // if (json == null) {
  //   return 'Null';
  // } else
  if (json is List) {
    return _jlist(level, json);
  } else if (json is Map) {
    return _jmap(level, json as Map<String, dynamic>);
  }

  List<Node> result = [];
  return result;
}

List<Node> _jmap(int level, Map<String, dynamic> json) {
  List<Node> result = [];
  level++;
  if (_maxLevel < level) {
    _maxLevel = level;
  }

  json.forEach((key, value) {
    _node = _node.makeChild(path: key);
    result.add(
        Node(level, NodeType.mapKey, MapEntry(key, value), _node.absolutePath));
    if (!isPrimitive(value)) {
      result.addAll(_jp(level, value));
    }
    _node = _node.parent;
  });
  if (result.isNotEmpty) {
    result.add(Node(level - 1, NodeType.mapEnd, '}', _node.absolutePath));
  }
  return result;
}

List<Node> _jlist(int level, List<dynamic> json) {
  List<Node> result = [];
  level++;
  if (_maxLevel < level) {
    _maxLevel = level;
  }

  if (json.isNotEmpty) {
    // result.add(LJN(level, JT.listStart, '['));
  }
  json.forEachIndexed((index, value) {
    _node = _node.makeChild(path: '[$index]');
    result.add(Node(
        level, NodeType.listIndex, MapEntry(index, value), _node.absolutePath));
    if (!isPrimitive(value)) {
      result.addAll(_jp(level, value));
    }
    _node = _node.parent;
  });
  if (result.isNotEmpty) {
    // result.insert(0, LJN(level, JT.listStart, '['));
    result.add(Node(level - 1, NodeType.listEnd, ']', _node.absolutePath));
  }
  return result;
}

bool isPrimitive(dynamic value) {
  return value is double || value is int || value is String || value is bool;
}

Future<JsonNodes> _defJsonParser(
        json, JsonNodes Function(dynamic json) parsing) =>
    compute(parsing, json);

class JsonView extends StatefulWidget {
  static Future<JsonNodes> Function(
      dynamic, JsonNodes Function(dynamic) parsing) jsonParser = _defJsonParser;

  final dynamic json;
  final bool sliver;

  final Widget Function(BuildContext context, JsonNodes nodes)? builder;

  const JsonView({super.key, required this.json})
      : sliver = false,
        builder = null;

  const JsonView.sliver({super.key, required this.json})
      : sliver = true,
        builder = null;

  const JsonView.custom(
      {super.key,
      required this.json,
      required this.sliver,
      required Widget Function(BuildContext context, JsonNodes nodes)
          this.builder});

  @override
  State<JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> with CancellableState {
  late LinkedScrollControllerGroup _controllers = LinkedScrollControllerGroup();

  late Future<JsonNodes> jsonNodes;
  dynamic jsonStr;
  Cancellable? parseJsonCancellable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseJson(widget.json);
  }

  @override
  void didUpdateWidget(covariant JsonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.json != oldWidget.json) {
      // _controllers
      _controllers = LinkedScrollControllerGroup();
      _parseJson(widget.json);
    }
  }

  _parseJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == this.jsonStr) return;
    this.jsonStr = jsonStr;
    parseJsonCancellable?.cancel();
    parseJsonCancellable = makeCancellable();
    jsonNodes = JsonView.jsonParser(jsonStr, _parsing)
        .bindCancellable(parseJsonCancellable!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JsonNodes>(
        future: jsonNodes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final r = Center(
              child:
                  Text(snapshot.error?.toString() ?? 'computeJsonView error'),
            );
            return widget.sliver ? SliverToBoxAdapter(child: r) : r;
          } else if (snapshot.hasData) {
            final data = snapshot.requireData;
            if (widget.builder != null) {
              return widget.builder!(context, data);
            }
            return _buildJsonV(data);
            // return JsonView.map(snapshot.data!);
          } else {
            const r = Center(child: CircularProgressIndicator());
            return widget.sliver ? const SliverToBoxAdapter(child: r) : r;
          }
        });
  }

  Widget _buildJsonV(JsonNodes jsonNodes) {
    int maxLevel = jsonNodes.maxLevel;
    double defWidth = MediaQuery.of(context).size.width;
    if (defWidth < 400) {
      defWidth = defWidth * 2;
    }

    Widget itemBuilder(BuildContext context, int index) {
      final node = jsonNodes.nodes[index];
      return _JsonNodeBuilder(
          node: node,
          controllers: _controllers,
          maxLevel: maxLevel,
          defWidth: defWidth);
    }

    return widget.sliver
        ? SliverList(
            key: ValueKey(widget.json),
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: jsonNodes.nodes.length,
            ),
          )
        : ListView.builder(
            itemBuilder: itemBuilder,
            itemCount: jsonNodes.nodes.length,
          );
  }
}

class _JsonNodeBuilder extends StatefulWidget {
  final Node node;
  final LinkedScrollControllerGroup controllers;
  final int maxLevel;
  final double defWidth;

  const _JsonNodeBuilder(
      {super.key,
      required this.node,
      required this.controllers,
      required this.maxLevel,
      required this.defWidth});

  @override
  State<_JsonNodeBuilder> createState() => _JsonNodeBuilderState();
}

class _JsonNodeBuilderState extends State<_JsonNodeBuilder> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controllers.addAndGet();
  }

  @override
  void didUpdateWidget(covariant _JsonNodeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllers != oldWidget.controllers) {
      _controller = widget.controllers.addAndGet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    Widget result;
    switch (node.type) {
      case NodeType.listStart:
        result = const Text('[');
        break;
      case NodeType.listIndex:
        MapEntry<int, dynamic> data = node.value;
        final value = data.value;
        result = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('[${data.key}]'),
            const Text(' : '),
            if (isPrimitive(value))
              Expanded(child: Text(value is String ? '"$value"' : '$value')),
            if (value is Map) const Text('{'),
            if (value is List) const Text('['),
          ],
        );
        break;
      case NodeType.listEnd:
        result = const Text(']');
        break;
      case NodeType.mapStart:
        result = const Text('{');
        break;
      case NodeType.mapKey:
        MapEntry<String, dynamic> data = node.value;
        final value = data.value;
        result = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${data.key}"'),
            const Text(' : '),
            if (isPrimitive(value))
              Expanded(child: Text(value is String ? '"$value"' : '$value')),
            if (value is Map) Text('{${value.isEmpty ? '}' : ''}'),
            if (value is List) Text('[${value.isEmpty ? ']' : ''}'),
          ],
        );
        break;
      case NodeType.mapEnd:
        result = const Text('}');
        break;
      case NodeType.value:
        final value = node.value;
        result = Text(value is String ? '"$value"' : '$value');
        break;
    }
    return SingleChildScrollView(
      key: ValueKey(_controller),
      scrollDirection: Axis.horizontal,
      controller: _controller,
      child: SizedBox(
        width: widget.defWidth,
        child: Padding(
          padding: EdgeInsets.only(left: 12.0 * node.level),
          child: result,
        ),
      ),
    );
  }
}
