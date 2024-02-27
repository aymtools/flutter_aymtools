part of 'an_console.dart';
//
// /// Special version of a [Stack], that doesn't layout and render the first
// /// [skipCount] children.
// ///
// /// The first [skipCount] children are considered "offstage".
// class _Theater extends MultiChildRenderObjectWidget {
//   const _Theater({
//     this.clipBehavior = Clip.hardEdge,
//     required super.children,
//   });
//
//   final Clip clipBehavior;
//
//   @override
//   _TheaterElement createElement() => _TheaterElement(this);
//
//   @override
//   _RenderTheater createRenderObject(BuildContext context) {
//     return _RenderTheater(
//       textDirection: Directionality.of(context),
//       clipBehavior: clipBehavior,
//     );
//   }
//
//   @override
//   void updateRenderObject(BuildContext context, _RenderTheater renderObject) {
//     renderObject
//       ..textDirection = Directionality.of(context)
//       ..clipBehavior = clipBehavior;
//   }
//
// }
//
// class _TheaterElement extends MultiChildRenderObjectElement {
//   _TheaterElement(_Theater super.widget);
//
//   @override
//   _RenderTheater get renderObject => super.renderObject as _RenderTheater;
//
//   @override
//   void insertRenderObjectChild(RenderBox child, IndexedSlot<Element?> slot) {
//     super.insertRenderObjectChild(child, slot);
//     final _TheaterParentData parentData =
//         child.parentData! as _TheaterParentData;
//     parentData.overlayEntry =
//         ((widget as _Theater).children[slot.index] as _OverlayEntryWidget)
//             .entry;
//     assert(parentData.overlayEntry != null);
//   }
//
//   @override
//   void moveRenderObjectChild(RenderBox child, IndexedSlot<Element?> oldSlot,
//       IndexedSlot<Element?> newSlot) {
//     super.moveRenderObjectChild(child, oldSlot, newSlot);
//     assert(() {
//       final _TheaterParentData parentData =
//           child.parentData! as _TheaterParentData;
//       return parentData.overlayEntry ==
//           ((widget as _Theater).children[newSlot.index] as _OverlayEntryWidget)
//               .entry;
//     }());
//   }
//
//   @override
//   void debugVisitOnstageChildren(ElementVisitor visitor) {
//     final _Theater theater = widget as _Theater;
//     assert(children.length >= theater.skipCount);
//     children.skip(theater.skipCount).forEach(visitor);
//   }
// }
//
// // A `RenderBox` that sizes itself to its parent's size, implements the stack
// // layout algorithm and renders its children in the given `theater`.
// mixin _RenderTheaterMixin on RenderBox {
//   _RenderTheater get theater;
//
//   Iterable<RenderBox> _childrenInPaintOrder();
//
//   Iterable<RenderBox> _childrenInHitTestOrder();
//
//   @override
//   void setupParentData(RenderBox child) {
//     if (child.parentData is! StackParentData) {
//       child.parentData = StackParentData();
//     }
//   }
//
//   @override
//   bool get sizedByParent => true;
//
//   @override
//   void performLayout() {
//     final Iterator<RenderBox> iterator = _childrenInPaintOrder().iterator;
//     // Same BoxConstraints as used by RenderStack for StackFit.expand.
//     final BoxConstraints nonPositionedChildConstraints =
//         BoxConstraints.tight(constraints.biggest);
//     final Alignment alignment = theater._resolvedAlignment;
//
//     while (iterator.moveNext()) {
//       final RenderBox child = iterator.current;
//       final StackParentData childParentData =
//           child.parentData! as StackParentData;
//       if (!childParentData.isPositioned) {
//         child.layout(nonPositionedChildConstraints, parentUsesSize: true);
//         childParentData.offset =
//             alignment.alongOffset(size - child.size as Offset);
//       } else {
//         assert(child is! _RenderDeferredLayoutBox,
//             'all _RenderDeferredLayoutBoxes must be non-positioned children.');
//         RenderStack.layoutPositionedChild(
//             child, childParentData, size, alignment);
//       }
//       assert(child.parentData == childParentData);
//     }
//   }
//
//   @override
//   bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
//     final Iterator<RenderBox> iterator = _childrenInHitTestOrder().iterator;
//     bool isHit = false;
//     while (!isHit && iterator.moveNext()) {
//       final RenderBox child = iterator.current;
//       final StackParentData childParentData =
//           child.parentData! as StackParentData;
//       final RenderBox localChild = child;
//       bool childHitTest(BoxHitTestResult result, Offset position) =>
//           localChild.hitTest(result, position: position);
//       isHit = result.addWithPaintOffset(
//           offset: childParentData.offset,
//           position: position,
//           hitTest: childHitTest);
//     }
//     return isHit;
//   }
//
//   @override
//   void paint(PaintingContext context, Offset offset) {
//     for (final RenderBox child in _childrenInPaintOrder()) {
//       final StackParentData childParentData =
//           child.parentData! as StackParentData;
//       context.paintChild(child, childParentData.offset + offset);
//     }
//   }
// }
//
// class _TheaterParentData extends StackParentData {
//   // The OverlayEntry that directly created this child. This field is null for
//   // children that are created by an OverlayPortal.
//   OverlayEntry? overlayEntry;
//
//   // _overlayStateMounted is set to null in _OverlayEntryWidgetState's dispose
//   // method. This property is only accessed during layout, paint and hit-test so
//   // the `value!` should be safe.
//   Iterator<RenderBox>? get paintOrderIterator => overlayEntry
//       ?._overlayEntryStateNotifier.value!._paintOrderIterable.iterator;
//
//   Iterator<RenderBox>? get hitTestOrderIterator => overlayEntry
//       ?._overlayEntryStateNotifier.value!._hitTestOrderIterable.iterator;
//
//   void visitChildrenOfOverlayEntry(RenderObjectVisitor visitor) =>
//       overlayEntry?._overlayEntryStateNotifier.value!._paintOrderIterable
//           .forEach(visitor);
// }
//
// class _RenderTheater extends RenderBox
//     with
//         ContainerRenderObjectMixin<RenderBox, StackParentData>,
//         _RenderTheaterMixin {
//   _RenderTheater({
//     List<RenderBox>? children,
//     required TextDirection textDirection,
//     int skipCount = 0,
//     Clip clipBehavior = Clip.hardEdge,
//   })  : assert(skipCount >= 0),
//         _textDirection = textDirection,
//         _skipCount = skipCount,
//         _clipBehavior = clipBehavior {
//     addAll(children);
//   }
//
//   @override
//   _RenderTheater get theater => this;
//
//   @override
//   void setupParentData(RenderBox child) {
//     if (child.parentData is! _TheaterParentData) {
//       child.parentData = _TheaterParentData();
//     }
//   }
//
//   @override
//   void attach(PipelineOwner owner) {
//     super.attach(owner);
//     RenderBox? child = firstChild;
//     while (child != null) {
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       final Iterator<RenderBox>? iterator = childParentData.paintOrderIterator;
//       if (iterator != null) {
//         while (iterator.moveNext()) {
//           iterator.current.attach(owner);
//         }
//       }
//       child = childParentData.nextSibling;
//     }
//   }
//
//   static void _detachChild(RenderObject child) => child.detach();
//
//   @override
//   void detach() {
//     super.detach();
//     RenderBox? child = firstChild;
//     while (child != null) {
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       childParentData.visitChildrenOfOverlayEntry(_detachChild);
//       child = childParentData.nextSibling;
//     }
//   }
//
//   @override
//   void redepthChildren() => visitChildren(redepthChild);
//
//   Alignment? _alignmentCache;
//
//   Alignment get _resolvedAlignment =>
//       _alignmentCache ??= AlignmentDirectional.topStart.resolve(textDirection);
//
//   void _markNeedResolution() {
//     _alignmentCache = null;
//     markNeedsLayout();
//   }
//
//   TextDirection get textDirection => _textDirection;
//   TextDirection _textDirection;
//
//   set textDirection(TextDirection value) {
//     if (_textDirection == value) {
//       return;
//     }
//     _textDirection = value;
//     _markNeedResolution();
//   }
//
//   int get skipCount => _skipCount;
//   int _skipCount;
//
//   set skipCount(int value) {
//     if (_skipCount != value) {
//       _skipCount = value;
//       markNeedsLayout();
//     }
//   }
//
//   /// {@macro flutter.material.Material.clipBehavior}
//   ///
//   /// Defaults to [Clip.hardEdge], and must not be null.
//   Clip get clipBehavior => _clipBehavior;
//   Clip _clipBehavior = Clip.hardEdge;
//
//   set clipBehavior(Clip value) {
//     if (value != _clipBehavior) {
//       _clipBehavior = value;
//       markNeedsPaint();
//       markNeedsSemanticsUpdate();
//     }
//   }
//
//   // Adding/removing deferred child does not affect the layout of other children,
//   // or that of the Overlay, so there's no need to invalidate the layout of the
//   // Overlay.
//   //
//   // When _skipMarkNeedsLayout is true, markNeedsLayout does not do anything.
//   bool _skipMarkNeedsLayout = false;
//
//   void _addDeferredChild(_RenderDeferredLayoutBox child) {
//     assert(!_skipMarkNeedsLayout);
//     _skipMarkNeedsLayout = true;
//
//     adoptChild(child);
//     // When child has never been laid out before, mark its layout surrogate as
//     // needing layout so it's reachable via tree walk.
//     child._layoutSurrogate.markNeedsLayout();
//     _skipMarkNeedsLayout = false;
//   }
//
//   void _removeDeferredChild(_RenderDeferredLayoutBox child) {
//     assert(!_skipMarkNeedsLayout);
//     _skipMarkNeedsLayout = true;
//     dropChild(child);
//     _skipMarkNeedsLayout = false;
//   }
//
//   @override
//   void markNeedsLayout() {
//     if (_skipMarkNeedsLayout) {
//       return;
//     }
//     super.markNeedsLayout();
//   }
//
//   RenderBox? get _firstOnstageChild {
//     if (skipCount == super.childCount) {
//       return null;
//     }
//     RenderBox? child = super.firstChild;
//     for (int toSkip = skipCount; toSkip > 0; toSkip--) {
//       final StackParentData childParentData =
//           child!.parentData! as StackParentData;
//       child = childParentData.nextSibling;
//       assert(child != null);
//     }
//     return child;
//   }
//
//   RenderBox? get _lastOnstageChild =>
//       skipCount == super.childCount ? null : lastChild;
//
//   @override
//   double computeMinIntrinsicWidth(double height) {
//     return RenderStack.getIntrinsicDimension(_firstOnstageChild,
//         (RenderBox child) => child.getMinIntrinsicWidth(height));
//   }
//
//   @override
//   double computeMaxIntrinsicWidth(double height) {
//     return RenderStack.getIntrinsicDimension(_firstOnstageChild,
//         (RenderBox child) => child.getMaxIntrinsicWidth(height));
//   }
//
//   @override
//   double computeMinIntrinsicHeight(double width) {
//     return RenderStack.getIntrinsicDimension(_firstOnstageChild,
//         (RenderBox child) => child.getMinIntrinsicHeight(width));
//   }
//
//   @override
//   double computeMaxIntrinsicHeight(double width) {
//     return RenderStack.getIntrinsicDimension(_firstOnstageChild,
//         (RenderBox child) => child.getMaxIntrinsicHeight(width));
//   }
//
//   @override
//   double? computeDistanceToActualBaseline(TextBaseline baseline) {
//     assert(!debugNeedsLayout);
//     double? result;
//     RenderBox? child = _firstOnstageChild;
//     while (child != null) {
//       assert(!child.debugNeedsLayout);
//       final StackParentData childParentData =
//           child.parentData! as StackParentData;
//       double? candidate = child.getDistanceToActualBaseline(baseline);
//       if (candidate != null) {
//         candidate += childParentData.offset.dy;
//         if (result != null) {
//           result = math.min(result, candidate);
//         } else {
//           result = candidate;
//         }
//       }
//       child = childParentData.nextSibling;
//     }
//     return result;
//   }
//
//   @override
//   Size computeDryLayout(BoxConstraints constraints) {
//     assert(constraints.biggest.isFinite);
//     return constraints.biggest;
//   }
//
//   @override
//   // The following uses sync* because concurrent modifications should be allowed
//   // during layout.
//   Iterable<RenderBox> _childrenInPaintOrder() sync* {
//     RenderBox? child = _firstOnstageChild;
//     while (child != null) {
//       yield child;
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       final Iterator<RenderBox>? innerIterator =
//           childParentData.paintOrderIterator;
//       if (innerIterator != null) {
//         while (innerIterator.moveNext()) {
//           yield innerIterator.current;
//         }
//       }
//       child = childParentData.nextSibling;
//     }
//   }
//
//   @override
//   // The following uses sync* because hit testing should be lazy.
//   Iterable<RenderBox> _childrenInHitTestOrder() sync* {
//     RenderBox? child = _lastOnstageChild;
//     int childLeft = childCount - skipCount;
//     while (child != null) {
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       final Iterator<RenderBox>? innerIterator =
//           childParentData.hitTestOrderIterator;
//       if (innerIterator != null) {
//         while (innerIterator.moveNext()) {
//           yield innerIterator.current;
//         }
//       }
//       yield child;
//       childLeft -= 1;
//       child = childLeft <= 0 ? null : childParentData.previousSibling;
//     }
//   }
//
//   final LayerHandle<ClipRectLayer> _clipRectLayer =
//       LayerHandle<ClipRectLayer>();
//
//   @override
//   void paint(PaintingContext context, Offset offset) {
//     if (clipBehavior != Clip.none) {
//       _clipRectLayer.layer = context.pushClipRect(
//         needsCompositing,
//         offset,
//         Offset.zero & size,
//         super.paint,
//         clipBehavior: clipBehavior,
//         oldLayer: _clipRectLayer.layer,
//       );
//     } else {
//       _clipRectLayer.layer = null;
//       super.paint(context, offset);
//     }
//   }
//
//   @override
//   void dispose() {
//     _clipRectLayer.layer = null;
//     super.dispose();
//   }
//
//   @override
//   void visitChildren(RenderObjectVisitor visitor) {
//     RenderBox? child = firstChild;
//     while (child != null) {
//       visitor(child);
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       childParentData.visitChildrenOfOverlayEntry(visitor);
//       child = childParentData.nextSibling;
//     }
//   }
//
//   @override
//   void visitChildrenForSemantics(RenderObjectVisitor visitor) {
//     RenderBox? child = _firstOnstageChild;
//     while (child != null) {
//       visitor(child);
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       childParentData.visitChildrenOfOverlayEntry(visitor);
//       child = childParentData.nextSibling;
//     }
//   }
//
//   @override
//   Rect? describeApproximatePaintClip(RenderObject child) {
//     switch (clipBehavior) {
//       case Clip.none:
//         return null;
//       case Clip.hardEdge:
//       case Clip.antiAlias:
//       case Clip.antiAliasWithSaveLayer:
//         return Offset.zero & size;
//     }
//   }
//
//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(IntProperty('skipCount', skipCount));
//     properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
//   }
//
//   @override
//   List<DiagnosticsNode> debugDescribeChildren() {
//     final List<DiagnosticsNode> offstageChildren = <DiagnosticsNode>[];
//     final List<DiagnosticsNode> onstageChildren = <DiagnosticsNode>[];
//
//     int count = 1;
//     bool onstage = false;
//     RenderBox? child = firstChild;
//     final RenderBox? firstOnstageChild = _firstOnstageChild;
//     while (child != null) {
//       final _TheaterParentData childParentData =
//           child.parentData! as _TheaterParentData;
//       if (child == firstOnstageChild) {
//         onstage = true;
//         count = 1;
//       }
//
//       if (onstage) {
//         onstageChildren.add(
//           child.toDiagnosticsNode(
//             name: 'onstage $count',
//           ),
//         );
//       } else {
//         offstageChildren.add(
//           child.toDiagnosticsNode(
//             name: 'offstage $count',
//             style: DiagnosticsTreeStyle.offstage,
//           ),
//         );
//       }
//
//       int subcount = 1;
//       childParentData.visitChildrenOfOverlayEntry((RenderObject renderObject) {
//         final RenderBox child = renderObject as RenderBox;
//         if (onstage) {
//           onstageChildren.add(
//             child.toDiagnosticsNode(
//               name: 'onstage $count - $subcount',
//             ),
//           );
//         } else {
//           offstageChildren.add(
//             child.toDiagnosticsNode(
//               name: 'offstage $count - $subcount',
//               style: DiagnosticsTreeStyle.offstage,
//             ),
//           );
//         }
//         subcount += 1;
//       });
//
//       child = childParentData.nextSibling;
//       count += 1;
//     }
//
//     return <DiagnosticsNode>[
//       ...onstageChildren,
//       if (offstageChildren.isNotEmpty)
//         ...offstageChildren
//       else
//         DiagnosticsNode.message(
//           'no offstage children',
//           style: DiagnosticsTreeStyle.offstage,
//         ),
//     ];
//   }
// }
