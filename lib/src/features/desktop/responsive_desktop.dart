import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/utils/responsive_helper.dart';
import '../settings/main_settings.dart';
import '../wifi/zion_wifi_panel.dart';
import '../si/advanced_si_control_panel.dart';
import '../windows/advanced_file_explorer.dart';
import '../windows/advanced_web_browser.dart';
import '../windows/advanced_text_editor.dart';
import '../network/network_analyzer.dart';
import '../network_infra/network_infrastructure_center.dart';
import '../network_control/network_control_center.dart';
import '../system/process_manager.dart';
import '../system/system_monitor.dart';
import '../resources/resources_center.dart';
import '../performance/performance_monitor.dart';
import '../security/vulnerability_scanner.dart';
import '../security_center/security_center.dart';
import '../encryption/encryption_center.dart';
import '../scheduler/task_scheduler.dart';
import '../packages/package_manager.dart';
import '../backup/backup_manager.dart';
import '../logs/log_viewer.dart';
import '../storage/disk_usage_analyzer.dart';
import '../reports/report_generator.dart';
import '../analytics/analytics_center.dart';
import '../business/business_analytics.dart';
import '../predictive_analytics/predictive_analytics_center.dart';
import '../cloud/cloud_center.dart';
import '../blockchain/blockchain_center.dart';
import '../integration/integration_center.dart';
import '../ai_control/ai_control_center.dart';
import '../predictive/predictive_center.dart';
import '../container/container_manager.dart';
import '../robotics/robotics_center.dart';
import '../energy/energy_center.dart';
import '../smart_city/smart_city_center.dart';
import '../geospatial/geospatial_center.dart';
import '../productivity/productivity_center.dart';
import '../developer/developer_center.dart';
import '../learning/learning_center.dart';
import '../docs/docs_center.dart';
import '../help/help_center.dart';
import '../info/info_center.dart';
import '../games/games_center.dart';
import '../media/media_center.dart';
import '../ar/ar_center.dart';
import '../qr/qr_scanner.dart';
import '../boot/boot_center.dart';
import '../power/power_management.dart';
import '../cleaner/system_cleaner.dart';
import '../maintenance/maintenance_center.dart';
import '../quality/quality_assurance.dart';
import '../governance/governance_center.dart';
import '../notifications/advanced_notification_center.dart';
import '../communication/communication_center.dart';
import '../store/app_store.dart';
import '../simulation/simulation_center.dart';
import '../automation/automation_center.dart';
import '../../../features/terminal/terminal_screen.dart';

class ResponsiveDesktop extends StatefulWidget {
  const ResponsiveDesktop({super.key});

  @override
  State<ResponsiveDesktop> createState() => _ResponsiveDesktopState();
}

class _ResponsiveDesktopState extends State<ResponsiveDesktop> {
  final List<DesktopWindow> _windows = [];
  int _nextWindowId = 1;
  DateTime _currentTime = DateTime.now();
  bool _menuOpen = false;
  int? _draggingWindowId;
  Offset? _dragStart;
  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  void _openWindow(String title, Widget content, {Size size = const Size(850, 650)}) {
    setState(() {
      _windows.add(DesktopWindow(
        id: _nextWindowId++,
        title: title,
        content: content,
        position: Offset(50 + (_windows.length % 5) * 30, 50 + (_windows.length % 5) * 30),
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
      if (index != -1) _windows[index].isMinimized = true;
    });
  }

  void _restoreWindow(int id) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index != -1) _windows[index].isMinimized = false;
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
    _dragStart = startPosition;
  }

  void _updateDragging(Offset newPosition) {
    if (_draggingWindowId != null && _dragStart != null) {
      final index = _windows.indexWhere((w) => w.id == _draggingWindowId);
      if (index != -1 && !_windows[index].isMaximized) {
        setState(() {
          _windows[index].position += newPosition - _dragStart!;
          _dragStart = newPosition;
        });
      }
    }
  }

  void _stopDragging() {
    _draggingWindowId = null;
    _dragStart = null;
  }

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.isMobile(context) ? 40.0 : 48.0;
    final fontSize = ResponsiveHelper.isMobile(context) ? 10.0 : 12.0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          _buildDesktopIcons(iconSize),
          ..._windows.where((w) => !w.isMinimized).map((w) => _buildWindow(w)),
          if (_menuOpen) _buildStartMenu(),
          _buildTaskbar(iconSize, fontSize),
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
          'ZION OS\nv3.3',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, shadows: [
            Shadow(color: Color(0xFF00FF41), blurRadius: 10),
          ]),
        ),
      ),
    );
  }

  Widget _buildDesktopIcons(double iconSize) {
    final icons = [
      {'icon': Icons.terminal, 'label': 'Terminal', 'route': '/terminal', 'color': Colors.green},
      {'icon': Icons.wifi, 'label': 'WiFi', 'route': '/wifi', 'color': Colors.blue},
      {'icon': Icons.psychology, 'label': 'SI Agent', 'route': '/si_agent', 'color': Colors.purple},
      {'icon': Icons.folder, 'label': 'Files', 'route': '/file_manager', 'color': Colors.orange},
      {'icon': Icons.public, 'label': 'Browser', 'route': '/browser', 'color': Colors.teal},
      {'icon': Icons.edit, 'label': 'Editor', 'route': '/editor', 'color': Colors.pink},
      {'icon': Icons.settings, 'label': 'Settings', 'route': '/settings', 'color': Colors.grey},
      {'icon': Icons.network_check, 'label': 'Network', 'route': '/network_analyzer', 'color': Colors.cyan},
      {'icon': Icons.security, 'label': 'Security', 'route': '/security', 'color': Colors.red},
      {'icon': Icons.analytics, 'label': 'Hardware', 'route': '/hardware', 'color': Colors.purple},
    ];

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Wrap(
                spacing: 30,
                runSpacing: 30,
                children: icons.map((icon) => _DesktopIcon(
                  icon: icon['icon'] as IconData,
                  label: icon['label'] as String,
                  color: icon['color'] as Color,
                  iconSize: iconSize,
                  onTap: () => _openWindow(icon['label'] as String, _getWidgetForRoute(icon['route'] as String)),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getWidgetForRoute(String route) {
    switch (route) {
      case '/terminal': return const TerminalScreen();
      case '/wifi': return const ZionWifiPanel();
      case '/si_agent': return const AdvancedSIControlPanel();
      case '/file_manager': return const AdvancedFileExplorer();
      case '/browser': return const AdvancedWebBrowser();
      case '/editor': return const AdvancedTextEditor();
      case '/settings': return const MainSettings();
      case '/network_analyzer': return const NetworkAnalyzer();
      case '/security': return const SecurityCenter();
      case '/hardware': return const Center(child: Text('Hardware Center', style: TextStyle(color: Colors.white)));
      default: return const Center(child: Text('Coming Soon', style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildWindow(DesktopWindow w) {
    return Positioned(
      left: w.position.dx.clamp(0, MediaQuery.of(context).size.width - 100),
      top: w.position.dy.clamp(0, MediaQuery.of(context).size.height - 100),
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
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(w.isMaximized ? 0 : 12),
                  bottomRight: Radius.circular(w.isMaximized ? 0 : 12),
                ),
                child: w.content,
              )),
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
      child: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  Widget _buildStartMenu() {
    return Positioned(
      bottom: 70,
      left: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
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
              ListTile(
                leading: const Icon(Icons.terminal, color: Colors.green),
                title: const Text('Terminal', style: TextStyle(color: Colors.white)),
                onTap: () => _openWindow('Terminal', const TerminalScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () => _openWindow('Settings', const MainSettings()),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Exit', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskbar(double iconSize, double fontSize) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: ResponsiveHelper.isMobile(context) ? 40 : 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(top: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: ResponsiveHelper.isMobile(context) ? 50 : 60,
                height: ResponsiveHelper.isMobile(context) ? 40 : 50,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00FF41), Colors.black])),
                child: Icon(Icons.menu, color: Colors.white, size: ResponsiveHelper.isMobile(context) ? 20 : 24),
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
                      height: ResponsiveHelper.isMobile(context) ? 40 : 50,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
                      ),
                      child: Center(
                        child: Text(
                          w.title,
                          style: TextStyle(color: Colors.white, fontSize: ResponsiveHelper.isMobile(context) ? 10 : 12),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            _buildSystemTray(iconSize.toDouble()),
            _buildClock(fontSize.toDouble()),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTray(double iconSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.battery_full, color: Colors.white, size: iconSize),
          SizedBox(width: ResponsiveHelper.isMobile(context) ? 4 : 8),
          Icon(Icons.wifi, color: Colors.white, size: iconSize),
          SizedBox(width: ResponsiveHelper.isMobile(context) ? 4 : 8),
          Icon(Icons.volume_up, color: Colors.white, size: iconSize),
        ],
      ),
    );
  }

  Widget _buildClock(double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(_currentTime), style: TextStyle(color: Colors.white, fontSize: fontSize)),
          Text(_formatDate(_currentTime), style: TextStyle(color: Colors.white70, fontSize: fontSize - 2)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime time) => '${time.day}/${time.month}/${time.year}';
}

class _DesktopIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;
  final VoidCallback onTap;

  const _DesktopIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1),
            ),
            child: Icon(icon, color: color, size: iconSize * 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: iconSize * 0.15),
          ),
        ],
      ),
    );
  }
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
