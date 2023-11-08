import 'package:flutter/foundation.dart';

Future<R> compute0<R>(R Function() callback, {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'compute0' : callback.toString();
  return compute<dynamic, R>((message) => callback(), 0,
      debugLabel: debugLabel);
}

const compute1 = compute;

Future<R> compute2<Q, Q1, R>(
    R Function(Q p0, Q1 p1) callback, Q param, Q1 param1,
    {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'computeX' : callback.toString();

  return compute<List<dynamic>, R>((p) => callback(p[0], p[1]), [param, param1],
      debugLabel: debugLabel);
}

Future<R> compute3<P, P2, P3, R>(
    R Function(P p0, P2 p2, P3 p3) callback, P param, P2 param2, P3 param3,
    {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'computeX' : callback.toString();

  return compute<List<dynamic>, R>(
      (p) => callback(p[0], p[1], p[2]), [param, param2, param3],
      debugLabel: debugLabel);
}

Future<R> compute4<P, P2, P3, P4, R>(
    R Function(P p0, P2 p2, P3 p3, P4 p4) callback,
    P param,
    P2 param2,
    P3 param3,
    P4 param4,
    {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'computeX' : callback.toString();

  return compute<List<dynamic>, R>(
      (p) => callback(p[0], p[1], p[2], p[3]), [param, param2, param3, param4],
      debugLabel: debugLabel);
}

Future<R> compute5<P, P2, P3, P4, P5, R>(
    R Function(P p0, P2 p2, P3 p3, P4 p4, P5 p5) callback,
    P param,
    P2 param2,
    P3 param3,
    P4 param4,
    P5 param5,
    {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'computeX' : callback.toString();

  return compute<List<dynamic>, R>(
      (p) => callback(p[0], p[1], p[2], p[3], p[4]),
      [param, param2, param3, param4, param5],
      debugLabel: debugLabel);
}
