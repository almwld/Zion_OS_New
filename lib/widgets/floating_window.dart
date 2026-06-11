import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FloatingWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final Size initialSize;
  final Offset initialPosition;
  final int windowId;
  
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
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = widget.initialSize;
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
              border: Border.all(color: const Color(0xFF00BCD4), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.window, color: Color(0xFF00BCD4), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.red),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title bar (draggable)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                    _position = Offset(
                      _position.dx.clamp(0, MediaQuery.of(context).size.width - _size.width),
                      _position.dy.clamp(0, MediaQuery.of(context).size.height - _size.height - 50),
                    );
                  });
                },
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      // Window controls
                      GestureDetector(
                        onTap: () => setState(() => _isMinimized = true),
                        child: const Icon(Icons.horizontal_rule, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _size = (_size.width > 300) ? const Size(350, 500) : const Size(800, 600);
                        }),
                        child: const Icon(Icons.crop_square, color: Color(0xFF00BCD4), size: 14),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Colors.red, size: 18),
                      ),
                      const Expanded(child: SizedBox()),
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Expanded(child: SizedBox()),
                      // Resize handle (bottom-right corner) - but placed in title bar for simplicity
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            double newWidth = (_size.width + details.delta.dx).clamp(250.0, 600.0);
                            double newHeight = (_size.height + details.delta.dy).clamp(300.0, 700.0);
                            _size = Size(newWidth, newHeight);
                          });
                        },
                        child: const Icon(Icons.drag_handle, color: Colors.white54, size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
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
