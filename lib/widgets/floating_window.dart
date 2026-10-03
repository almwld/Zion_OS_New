import 'package:flutter/material.dart';
import 'window_compositor.dart';

class FloatingWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final void Function(Size size, Offset position) onChanged;
  final int windowId;
  final VoidCallback? onFocus;
  final Size initialSize;
  final Offset initialPosition;

  const FloatingWindow({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    required this.onChanged,
    required this.windowId,
    this.onFocus,
    this.initialSize = const Size(350, 500),
    this.initialPosition = const Offset(50, 100),
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  static const double _minWidth = 240;
  static const double _minHeight = 180;
  static const double _snapThreshold = 28;
  late Offset _position;
  late Size _size;
  Size? _restoreSize;
  Offset? _restorePosition;
  bool _isMinimized = false;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = Size(
      widget.initialSize.width < _minWidth ? _minWidth : widget.initialSize.width,
      widget.initialSize.height < _minHeight ? _minHeight : widget.initialSize.height,
    );
  }

  Offset _clampPosition(BuildContext context, Offset position, {Size? size}) {
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final currentSize = size ?? _size;
    final maxX = (screen.width - currentSize.width).clamp(0.0, double.infinity).toDouble();
    final maxY = (screen.height - currentSize.height).clamp(0.0, double.infinity).toDouble();
    return Offset(
      position.dx.clamp(0.0, maxX).toDouble(),
      position.dy.clamp(0.0, maxY).toDouble(),
    );
  }

  Size _clampSize(BuildContext context, Size size) {
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width.clamp(_minWidth, double.infinity).toDouble();
    final maxHeight = screen.height.clamp(_minHeight, double.infinity).toDouble();
    return Size(
      size.width.clamp(_minWidth, maxWidth).toDouble(),
      size.height.clamp(_minHeight, maxHeight).toDouble(),
    );
  }

  void _resize(BuildContext context, double width, double height) {
    _size = _clampSize(context, Size(width, height));
    _position = _clampPosition(context, _position);
  }

  void _toggleMaximize(BuildContext context) {
    widget.onFocus?.call();
    final screen = MediaQuery.sizeOf(context);
    setState(() {
      if (_isMaximized) {
        _size = _restoreSize ?? _clampSize(context, const Size(350, 500));
        _position = _clampPosition(context, _restorePosition ?? const Offset(50, 100), size: _size);
        _isMaximized = false;
      } else {
        _restoreSize = _size;
        _restorePosition = _position;
        _position = Offset(0, safeTop + 6);
        _size = Size(screen.width, (screen.height - safeTop - 6).clamp(_minHeight, screen.height));
        _isMaximized = true;
      }
      widget.onChanged(_size, _position);
    });
  }

  void _snapToEdge(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final x = _position.dx;
    final y = _position.dy;
    WindowSnapVisual? target;
    if (y <= _snapThreshold) {
      target = WindowSnapVisual.maximize;
    } else if (x <= _snapThreshold) {
      target = WindowSnapVisual.left;
    } else if (x + _size.width >= screen.width - _snapThreshold) {
      target = WindowSnapVisual.right;
    }
    if (target == null) return;
    setState(() {
      if (target == WindowSnapVisual.maximize) {
        _restoreSize = _size;
        _restorePosition = _position;
        _position = Offset(0, safeTop + 6);
        _size = Size(screen.width, (screen.height - safeTop - 6).clamp(_minHeight, screen.height));
        _isMaximized = true;
      } else {
        if (_isMaximized) _isMaximized = false;
        final half = screen.width / 2;
        _position = target == WindowSnapVisual.left ? Offset.zero : Offset(half, 0);
        _size = Size(half, screen.height);
      }
      widget.onChanged(_size, _position);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return Positioned(
        left: _position.dx,
        top: _position.dy,
        child: GestureDetector(
          onTap: () {
            widget.onFocus?.call();
            setState(() {
              _isMinimized = false;
              widget.onChanged(_size, _position);
            });
          },
          child: Container(
            width: 120,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00BCD4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.window, color: Color(0xFF00BCD4), size: 16),
                Expanded(
                  child: Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                IconButton(icon: const Icon(Icons.close, size: 14, color: Colors.red), onPressed: widget.onClose),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: WindowCompositor(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _size.width,
            height: _size.height,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              borderRadius: BorderRadius.circular(_isMaximized ? 0 : 16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.3), blurRadius: 12)],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                GestureDetector(
                  onDoubleTap: () => _toggleMaximize(context),
                  onPanStart: (_) => widget.onFocus?.call(),
                  onPanUpdate: (details) {
                    if (_isMaximized) return;
                    setState(() {
                      _position = _clampPosition(context, _position + details.delta);
                    });
                  },
                  onPanEnd: (_) {
                    _snapToEdge(context);
                    if (!_isMaximized) widget.onChanged(_size, _position);
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x2600BCD4),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_isMaximized ? 0 : 16),
                        topRight: Radius.circular(_isMaximized ? 0 : 16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.title, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isMinimized = true;
                            widget.onChanged(_size, _position);
                          }),
                          child: const Icon(Icons.horizontal_rule, color: Color(0xFF00BCD4), size: 18),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _toggleMaximize(context),
                          child: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square, color: const Color(0xFF00BCD4), size: 15),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(Icons.close, color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(_isMaximized ? 0 : 16),
                      bottomRight: Radius.circular(_isMaximized ? 0 : 16),
                    ),
                    child: widget.child,
                  ),
                ),
                if (!_isMaximized) ...[
                  Positioned(
                    top: 2,
                    left: 2,
                    child: _ResizeHandle(
                      alignment: Alignment.topLeft,
                      cursor: SystemMouseCursors.resizeUpLeft,
                      onDrag: (d) => setState(() {
                        final old = _size;
                        final next = _clampSize(context, Size(old.width - d.dx, old.height - d.dy));
                        _position += Offset(old.width - next.width, old.height - next.height);
                        _size = next;
                        _position = _clampPosition(context, _position, size: _size);
                      }),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _ResizeHandle(
                      alignment: Alignment.topRight,
                      cursor: SystemMouseCursors.resizeUpRight,
                      onDrag: (d) => setState(() {
                        final old = _size;
                        final next = _clampSize(context, Size(old.width + d.dx, old.height - d.dy));
                        _position += Offset(0, old.height - next.height);
                        _size = next;
                        _position = _clampPosition(context, _position, size: _size);
                      }),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: _ResizeHandle(
                      alignment: Alignment.bottomLeft,
                      cursor: SystemMouseCursors.resizeDownLeft,
                      onDrag: (d) => setState(() {
                        final old = _size;
                        final next = _clampSize(context, Size(old.width - d.dx, old.height + d.dy));
                        _position += Offset(old.width - next.width, 0);
                        _size = next;
                        _position = _clampPosition(context, _position, size: _size);
                      }),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: _ResizeHandle(
                      alignment: Alignment.bottomRight,
                      cursor: SystemMouseCursors.resizeDownRight,
                      onDrag: (d) => setState(() => _resize(context, _size.width + d.dx, _size.height + d.dy)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum WindowSnapVisual { left, right, maximize }

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.alignment, required this.cursor, required this.onDrag});
  final Alignment alignment;
  final MouseCursor cursor;
  final ValueChanged<Offset> onDrag;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta),
        onPanEnd: (_) {},
        child: const SizedBox(width: 18, height: 18),
      ),
    ),
  );
}
