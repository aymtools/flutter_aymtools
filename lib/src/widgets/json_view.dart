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

  Node(this.level, this.type, this.value);
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

int _maxLevel = -1;

JsonNodes _parsing(dynamic json) {
  List<Node> result = [];
  _maxLevel = 0;
  if (json is String &&
      (json.trim().startsWith('{') || json.trim().startsWith('['))) {
    return _parsing(jsonDecode(json));
  } else if (isPrimitive(json)) {
    result.add(Node(_maxLevel, NodeType.value, json));
  } else if (json is List) {
    result.add(Node(_maxLevel, NodeType.listStart, json));
    result.addAll(_jlist(_maxLevel, json));
  } else if (json is Map) {
    result.add(Node(_maxLevel, NodeType.mapStart, json));
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
  _maxLevel <= level;

  json.forEach((key, value) {
    result.add(Node(level, NodeType.mapKey, MapEntry(key, value)));
    if (!isPrimitive(value)) {
      result.addAll(_jp(level, value));
    }
  });
  if (result.isNotEmpty) {
    result.add(Node(level - 1, NodeType.mapEnd, '}'));
  }
  return result;
}

List<Node> _jlist(int level, List<dynamic> json) {
  List<Node> result = [];
  level++;
  _maxLevel <= level;

  if (json.isNotEmpty) {
    // result.add(LJN(level, JT.listStart, '['));
  }
  json.forEachIndexed((index, value) {
    result.add(Node(level, NodeType.listIndex, MapEntry(index, value)));
    if (!isPrimitive(value)) {
      result.addAll(_jp(level, value));
    }
  });
  if (result.isNotEmpty) {
    // result.insert(0, LJN(level, JT.listStart, '['));
    result.add(Node(level - 1, NodeType.listEnd, ']'));
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

  const JsonView({super.key, required this.json});

  @override
  State<JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<JsonView> with CancellableState {
  late final LinkedScrollControllerGroup _controllers =
      LinkedScrollControllerGroup();

  late Future<JsonNodes> jsonNodes;
  String? jsonStr;
  Cancellable? parseJsonCancellable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseJson(widget.json);
  }

  _parseJson(dynamic jsonStr) {
    if (jsonStr == null || jsonStr == this.jsonStr) return;
    parseJsonCancellable?.cancel();
    parseJsonCancellable = makeCancellable();
    jsonNodes = JsonView.jsonParser(jsonStr, _parsing)
        .bindCancellable(parseJsonCancellable!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    child = FutureBuilder<JsonNodes>(
        future: jsonNodes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child:
                  Text(snapshot.error?.toString() ?? 'computeJsonView error'),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.requireData;
            return _buildJsonV(data);
            // return JsonView.map(snapshot.data!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
    return Scaffold(
      body: SafeArea(child: child),
    );
  }

  Widget _buildJsonV(JsonNodes jsonNodes) {
    int maxLevel = jsonNodes.maxLevel;
    double defWidth = MediaQuery.of(context).size.width * 2;
    return ListView.builder(
      itemBuilder: (context, index) {
        final node = jsonNodes.nodes[index];
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
                  Expanded(
                      child: Text(value is String ? '"$value"' : '$value')),
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
                  Expanded(
                      child: Text(value is String ? '"$value"' : '$value')),
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
          scrollDirection: Axis.horizontal,
          controller: _controllers.addAndGet(),
          child: SizedBox(
            width: maxLevel * 12 + defWidth,
            child: Padding(
              padding: EdgeInsets.only(left: 12.0 * node.level),
              child: result,
            ),
          ),
        );
      },
      itemCount: jsonNodes.nodes.length,
    );
  }
}
