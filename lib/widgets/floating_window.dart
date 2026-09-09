import 'package:flutter/material.dart';

class FloatingWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final int windowId;
  final Size initialSize;
  final Offset initialPosition;

  const FloatingWindow({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    required this.windowId,
    this.initialSize = const Size(350, 500),
    this.initialPosition = const Offset(50, 100),
  });

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

class _FloatingWindowState extends State<FloatingWindow> {
  late Offset _position;
  late Size _size;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = widget.initialSize;
  }

  Offset _clampPosition(BuildContext context, Offset position) {
    final screen = MediaQuery.sizeOf(context);
    final maxX = (screen.width - _size.width).clamp(0.0, double.infinity).toDouble();
    final maxY = (screen.height - _size.height - 50).clamp(0.0, double.infinity).toDouble();
    return Offset(
      position.dx.clamp(0.0, maxX).toDouble(),
      position.dy.clamp(0.0, maxY).toDouble(),
    );
  }

  void _resize(BuildContext context, double width, double height) {
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width.clamp(250.0, 600.0).toDouble();
    final maxHeight = (screen.height - 50).clamp(300.0, 700.0).toDouble();
    _size = Size(
      width.clamp(250.0, maxWidth).toDouble(),
      height.clamp(300.0, maxHeight).toDouble(),
    );
    _position = _clampPosition(context, _position);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return Positioned(
        left: _position.dx,
        top: _position.dy,
        child: GestureDetector(
          onTap: () => setState(() => _isMinimized = false),
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
                Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
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
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _size.width,
          height: _size.height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.3), blurRadius: 12)],
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (details) => setState(() {
                  _position = _clampPosition(context, _position + details.delta);
                }),
                child: Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0x2600BCD4),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      GestureDetector(onTap: () => setState(() => _isMinimized = true), child: const Icon(Icons.horizontal_rule, color: Color(0xFF00BCD4), size: 18)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _resize(context, _size.width > 300 ? 350 : 600, _size.height > 500 ? 500 : 600)),
                        child: const Icon(Icons.crop_square, color: Color(0xFF00BCD4), size: 14),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close, color: Colors.red, size: 18)),
                      const Expanded(child: SizedBox()),
                      Flexible(child: Text(widget.title, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12), overflow: TextOverflow.ellipsis)),
                      const Expanded(child: SizedBox()),
                      GestureDetector(
                        onPanUpdate: (details) => setState(() => _resize(context, _size.width + details.delta.dx, _size.height + details.delta.dy)),
                        child: const Icon(Icons.drag_handle, color: Colors.white54, size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
