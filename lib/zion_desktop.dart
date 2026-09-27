import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'features/terminal/terminal_screen.dart';
import 'src/features/dashboard/si_control_panel.dart';
import 'src/features/wifi/zion_wifi_panel.dart';

class ZionDesktop extends StatefulWidget {
  const ZionDesktop({super.key});

  @override
  State<ZionDesktop> createState() => _ZionDesktopState();
}

class _ZionDesktopState extends State<ZionDesktop> {
  final List<DesktopWindow> _windows = [];
  int _nextWindowId = 1;
  DateTime _currentTime = DateTime.now();

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
      ));
    });
  }

  void _closeWindow(int id) {
    setState(() => _windows.removeWhere((w) => w.id == id));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMatrixRain(),
          _buildDesktopIcons(),
          ..._windows.map((w) => _buildWindow(w)),
          _buildTaskbar(),
        ],
      ),
    );
  }

  Widget _buildMatrixRain() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade900.withOpacity(0.3), Colors.black],
        ),
      ),
      child: const Center(
        child: Text(
          'ZION OS\nv2.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.green, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
      ),
    );
  }

  Widget _buildDesktopIcons() {
    final icons = [
      {'icon': Icons.terminal, 'label': 'Terminal', 'color': Colors.green, 'widget': const TerminalScreen()},
      {'icon': Icons.wifi, 'label': 'WiFi', 'color': Colors.blue, 'widget': const ZionWifiPanel()},
      {'icon': Icons.psychology, 'label': 'SI Agent', 'color': Colors.purple, 'widget': const SIControlPanel()},
      {'icon': Icons.security, 'label': 'Security', 'color': Colors.red, 'widget': const Center(child: Text('Security Panel', style: TextStyle(color: Colors.white)))},
      {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.grey, 'widget': const Center(child: Text('Settings', style: TextStyle(color: Colors.white)))},
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
                        border: Border.all(color: icon['color'] as Color, width: 1),
                      ),
                      child: Icon(icon['icon'] as IconData, color: icon['color'] as Color, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(icon['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
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
        child: Container(
          width: w.size.width,
          height: w.size.height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
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
        color: Colors.green.withOpacity(0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.green.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          Expanded(child: Text(w.title, style: const TextStyle(color: Colors.white, fontSize: 12))),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white), onPressed: () => _closeWindow(w.id)),
        ],
      ),
    );
  }

  Widget _buildTaskbar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border(top: BorderSide(color: Colors.green.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            _buildStartButton(),
            const Spacer(),
            _buildSystemTray(),
            _buildClock(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () => _openWindow('Start Menu', Container(
        width: 280,
        color: Colors.black,
        child: Column(
          children: [
            ListTile(title: const Text('Terminal', style: TextStyle(color: Colors.white)), onTap: () => _openWindow('Terminal', const TerminalScreen())),
            ListTile(title: const Text('WiFi Panel', style: TextStyle(color: Colors.white)), onTap: () => _openWindow('WiFi', const ZionWifiPanel())),
            ListTile(title: const Text('SI Agent', style: TextStyle(color: Colors.white)), onTap: () => _openWindow('SI Agent', const SIControlPanel())),
            const Divider(color: Colors.green),
            ListTile(title: const Text('Exit', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(context)),
          ],
        ),
      ), size: const Size(280, 300)),
      child: Container(
        width: 60, height: 48,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green, Colors.green.shade900])),
        child: const Icon(Icons.menu, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSystemTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.battery_full, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Icon(Icons.wifi, color: Colors.white, size: 18),
          const SizedBox(width: 8),
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
          Text(_formatDate(_currentTime), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
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
  final Size size;
  DesktopWindow({required this.id, required this.title, required this.content, required this.position, required this.size});
}
