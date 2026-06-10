import 'package:flutter/material.dart';
import '../settings/zion_settings.dart';
import '../wifi/zion_wifi_panel.dart';
import '../si/si_control_panel.dart';
import '../windows/zion_file_manager.dart';
import '../windows/zion_browser.dart';
import '../windows/zion_text_editor.dart';
import '../../../cosmic_terminal.dart';

class GlassDesktop extends StatefulWidget {
  const GlassDesktop({super.key});

  @override
  State<GlassDesktop> createState() => _GlassDesktopState();
}

class _GlassDesktopState extends State<GlassDesktop> {
  final List<DesktopWindow> _windows = [];
  int _nextWindowId = 1;
  DateTime _currentTime = DateTime.now();
  bool _menuOpen = false;
  Offset? _draggingOffset;
  int? _draggingWindowId;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
        _updateTime();
      }
    });
  }

  void _openWindow(String title, Widget content, {Size size = const Size(800, 600)}) {
    setState(() {
      _windows.add(DesktopWindow(
        id: _nextWindowId++,
        title: title,
        content: content,
        position: Offset(50 + _windows.length * 30, 50 + _windows.length * 30),
        size: size,
        isMinimized: false,
        isMaximized: false,
      ));
    });
  }

  void _closeWindow(int id) {
    setState(() => _windows.removeWhere((w) => w.id == id));
  }

  void _minimizeWindow(int id) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index != -1) {
        _windows[index].isMinimized = true;
      }
    });
  }

  void _restoreWindow(int id) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index != -1) {
        _windows[index].isMinimized = false;
      }
    });
  }

  void _maximizeWindow(int id) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index != -1) {
        _windows[index].isMaximized = !_windows[index].isMaximized;
        if (_windows[index].isMaximized) {
          _windows[index].savedSize = _windows[index].size;
          _windows[index].savedPosition = _windows[index].position;
          _windows[index].size = const Size(double.infinity, double.infinity);
          _windows[index].position = Offset.zero;
        } else {
          _windows[index].size = _windows[index].savedSize;
          _windows[index].position = _windows[index].savedPosition;
        }
      }
    });
  }

  void _bringToFront(int id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index != -1 && index != _windows.length - 1) {
      setState(() {
        final window = _windows.removeAt(index);
        _windows.add(window);
      });
    }
  }

  void _startDragging(int id, Offset startPosition) {
    _draggingWindowId = id;
    _draggingOffset = startPosition;
  }

  void _updateDragging(Offset newPosition) {
    if (_draggingWindowId != null && _draggingOffset != null) {
      final index = _windows.indexWhere((w) => w.id == _draggingWindowId);
      if (index != -1 && !_windows[index].isMaximized) {
        setState(() {
          _windows[index].position += newPosition - _draggingOffset!;
          _draggingOffset = newPosition;
        });
      }
    }
  }

  void _stopDragging() {
    _draggingWindowId = null;
    _draggingOffset = null;
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          _buildDesktopIcons(),
          ..._windows.where((w) => !w.isMinimized).map((w) => _buildWindow(w)),
          if (_menuOpen) _buildStartMenu(),
          _buildTaskbar(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00FF41), Colors.black],
        ),
      ),
      child: const Center(
        child: Text(
          'ZION OS\nv3.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, shadows: [
            Shadow(color: Color(0xFF00FF41), blurRadius: 10),
          ]),
        ),
      ),
    );
  }

  Widget _buildDesktopIcons() {
    final icons = [
      {'icon': Icons.terminal, 'label': 'Terminal', 'widget': const CosmicTerminal()},
      {'icon': Icons.wifi, 'label': 'WiFi', 'widget': const ZionWifiPanel()},
      {'icon': Icons.psychology, 'label': 'SI Agent', 'widget': const SIControlPanel()},
      {'icon': Icons.folder, 'label': 'Files', 'widget': const ZionFileManager()},
      {'icon': Icons.public, 'label': 'Browser', 'widget': const ZionBrowser()},
      {'icon': Icons.edit, 'label': 'Editor', 'widget': const ZionTextEditor()},
      {'icon': Icons.settings, 'label': 'Settings', 'widget': const ZionSettings()},
    ];

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Wrap(
              spacing: 30,
              runSpacing: 30,
              children: icons.map((icon) => GestureDetector(
                onTap: () => _openWindow(icon['label'] as String, icon['widget'] as Widget),
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00FF41), width: 1),
                      ),
                      child: Icon(icon['icon'] as IconData, color: const Color(0xFF00FF41), size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(icon['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindow(DesktopWindow w) {
    return Positioned(
      left: w.position.dx,
      top: w.position.dy,
      child: GestureDetector(
        onTap: () => _bringToFront(w.id),
        onPanStart: (details) => _startDragging(w.id, details.localPosition),
        onPanUpdate: (details) => _updateDragging(details.localPosition),
        onPanEnd: (_) => _stopDragging(),
        child: Container(
          width: w.isMaximized ? MediaQuery.of(context).size.width - 40 : w.size.width,
          height: w.isMaximized ? MediaQuery.of(context).size.height - 100 : w.size.height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(w.isMaximized ? 0 : 12),
            border: Border.all(color: const Color(0xFF00FF41), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildTitleBar(w),
              Expanded(child: w.content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(DesktopWindow w) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF41).withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w.isMaximized ? 0 : 12),
          topRight: Radius.circular(w.isMaximized ? 0 : 12),
        ),
        border: Border(bottom: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Row(
            children: [
              _buildWindowButton(Colors.red, () => _closeWindow(w.id)),
              const SizedBox(width: 8),
              _buildWindowButton(Colors.amber, () => _minimizeWindow(w.id)),
              const SizedBox(width: 8),
              _buildWindowButton(Colors.green, () => _maximizeWindow(w.id)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              w.title,
              style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            onPressed: () => _closeWindow(w.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowButton(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildStartMenu() {
    final menuItems = [
      {'icon': Icons.terminal, 'title': 'Terminal', 'widget': const CosmicTerminal()},
      {'icon': Icons.wifi, 'title': 'WiFi', 'widget': const ZionWifiPanel()},
      {'icon': Icons.psychology, 'title': 'SI Agent', 'widget': const SIControlPanel()},
      {'icon': Icons.folder, 'title': 'File Manager', 'widget': const ZionFileManager()},
      {'icon': Icons.public, 'title': 'Browser', 'widget': const ZionBrowser()},
      {'icon': Icons.edit, 'title': 'Text Editor', 'widget': const ZionTextEditor()},
      {'icon': Icons.settings, 'title': 'Settings', 'widget': const ZionSettings()},
    ];

    return Positioned(
      bottom: 70,
      left: 16,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00FF41)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF00FF41),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zion User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('zion@os', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            ...menuItems.map((item) => ListTile(
              leading: Icon(item['icon'] as IconData, color: const Color(0xFF00FF41)),
              title: Text(item['title'] as String, style: const TextStyle(color: Colors.white)),
              onTap: () {
                _toggleMenu();
                _openWindow(item['title'] as String, item['widget'] as Widget);
              },
            )),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Exit', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskbar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(top: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 60, height: 50,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00FF41), Colors.black])),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _windows.map((w) => GestureDetector(
                    onTap: () => w.isMinimized ? _restoreWindow(w.id) : _bringToFront(w.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: Center(
                        child: Text(
                          w.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            _buildSystemTray(),
            _buildClock(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: const [
          Icon(Icons.battery_full, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Icon(Icons.wifi, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Icon(Icons.volume_up, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(_currentTime), style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text(_formatDate(_currentTime), style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime time) => '${time.day}/${time.month}/${time.year}';
}

class DesktopWindow {
  final int id;
  final String title;
  final Widget content;
  Offset position;
  Size size;
  Size savedSize;
  Offset savedPosition;
  bool isMinimized;
  bool isMaximized;

  DesktopWindow({
    required this.id,
    required this.title,
    required this.content,
    required this.position,
    required this.size,
    required this.isMinimized,
    required this.isMaximized,
  }) : savedSize = size, savedPosition = position;
}
