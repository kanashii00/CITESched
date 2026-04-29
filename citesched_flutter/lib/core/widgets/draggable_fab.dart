import 'package:flutter/material.dart';

/// A wrapper widget that makes its child draggable within a Stack.
class DraggableFab extends StatefulWidget {
  final Widget child;

  const DraggableFab({
    super.key,
    required this.child,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  final GlobalKey _childKey = GlobalKey();
  Offset? _offset;
  Size _childSize = const Size(56, 56);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialOffset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  void _ensureInitialOffset() {
    if (_offset != null) return;
    final size = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    _offset = Offset(
      size.width - _childSize.width - 16,
      size.height - _childSize.height - safeBottom - 16,
    );
  }

  void _measureChild() {
    final renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final measuredSize = renderObject.size;
    if (!mounted || measuredSize == _childSize) return;

    final oldSize = _childSize;
    final oldOffset = _offset;
    setState(() {
      _childSize = measuredSize;
      if (oldOffset != null) {
        _offset = _clampOffset(oldOffset, previousSize: oldSize);
      }
    });
  }

  Offset _clampOffset(Offset desired, {Size? previousSize}) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final safeTop = media.padding.top + 8;
    final safeBottom = media.padding.bottom + 8;
    final fabSize = previousSize ?? _childSize;

    const minX = 8.0;
    final maxX = screen.width - fabSize.width - 8;
    final minY = safeTop;
    final maxY = screen.height - fabSize.height - safeBottom;

    return Offset(
      desired.dx.clamp(minX, maxX),
      desired.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialOffset();
    final currentOffset = _clampOffset(_offset!);

    if (currentOffset != _offset) {
      _offset = currentOffset;
    }

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: _offset!.dx,
            top: _offset!.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _offset = _clampOffset(
                    Offset(
                      _offset!.dx + details.delta.dx,
                      _offset!.dy + details.delta.dy,
                    ),
                  );
                });
              },
              child: KeyedSubtree(
                key: _childKey,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
