import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import '../../security/core/security_core.dart';
import 'terminal_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalTab {
  _TerminalTab({
    required this.id,
    required this.name,
    required this.service,
    required this.terminal,
    required this.controller,
  });

  final int id;
  String name;
  final TerminalService service;
  final Terminal terminal;
  final TerminalController controller;
  StreamSubscription<String>? outputSubscription;
  bool connected = false;
}

class _TerminalScreenState extends State<TerminalScreen> {
  final List<_TerminalTab> _tabs = <_TerminalTab>[];
  int _selectedIndex = 0;
  int _nextId = 1;
  bool _starting = false;
  double _fontSize = 13;

  _TerminalTab? get _selectedTab =>
      _tabs.isEmpty ? null : _tabs[_selectedIndex.clamp(0, _tabs.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_createTab(autoStart: false));
    });
  }

  static const int _maxSessions = 8;

  Future<_TerminalTab?> _createTab({bool autoStart = true}) async {
    if (_tabs.length >= _maxSessions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الوصول إلى الحد الأقصى: 8 جلسات PTY.')),
        );
      }
      return null;
    }
    final security = context.read<SecurityCore>();
    final id = _nextId++;
    final terminal = Terminal(maxLines: 10000);
    final controller = TerminalController();
    final service = TerminalService(security);
    final tab = _TerminalTab(
      id: id,
      name: 'shell-$id',
      service: service,
      terminal: terminal,
      controller: controller,
    );

    terminal.onOutput = service.write;
    terminal.onResize = (width, height, _, __) {
      unawaited(service.resizeInteractive(rows: height, cols: width));
    };
    tab.outputSubscription = service.output.listen(terminal.write);

    setState(() {
      _tabs.add(tab);
      _selectedIndex = _tabs.length - 1;
    });

    if (autoStart) {
      setState(() => _starting = true);
      tab.connected = await service.startInteractive();
      if (mounted) setState(() => _starting = false);
    }
    return tab;
  }

  Future<void> _closeTab(int index) async {
    if (index < 0 || index >= _tabs.length) return;
    final tab = _tabs.removeAt(index);
    await tab.outputSubscription?.cancel();
    await tab.service.dispose();
    tab.controller.dispose();
    tab.terminal.dispose();

    if (!mounted) return;
    if (_tabs.isEmpty) {
      setState(() {});
      await _createTab();
      return;
    }
    setState(() {
      _selectedIndex = _selectedIndex.clamp(0, _tabs.length - 1);
    });
  }

  Future<void> _toggleSelected() async {
    final tab = _selectedTab;
    if (tab == null) return;
    if (tab.service.isInteractiveRunning) {
      await tab.service.stopInteractive();
      if (mounted) setState(() => tab.connected = false);
    } else {
      setState(() => _starting = true);
      final connected = await tab.service.startInteractive();
      if (mounted) {
        setState(() {
          tab.connected = connected;
          _starting = false;
        });
      }
    }
  }

  void _sendRaw(String value) {
    _selectedTab?.service.write(value);
  }

  void _clear() {
    final terminal = _selectedTab?.terminal;
    if (terminal == null) return;
    terminal.eraseDisplay();
    terminal.setCursor(0, 0);
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      unawaited(tab.outputSubscription?.cancel());
      unawaited(tab.service.dispose());
      tab.controller.dispose();
      tab.terminal.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = _selectedTab;
    return Scaffold(
      backgroundColor: const Color(0xFF090B0A),
      appBar: AppBar(
        title: const Text('Zion OS Terminal'),
        actions: [
          IconButton(
            tooltip: _tabs.length >= _maxSessions
                ? 'الحد الأقصى 8 جلسات'
                : 'جلسة جديدة',
            icon: const Icon(Icons.add),
            onPressed: _starting || _tabs.length >= _maxSessions
                ? null
                : () => unawaited(_createTab()),
          ),
          IconButton(
            tooltip: tab?.service.isInteractiveRunning == true
                ? 'إيقاف shell'
                : 'تشغيل shell',
            icon: Icon(
              tab?.service.isInteractiveRunning == true
                  ? Icons.stop_circle
                  : Icons.play_arrow,
            ),
            onPressed: tab == null || _starting ? null : _toggleSelected,
          ),
          IconButton(
            tooltip: 'مسح الشاشة',
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
          ),
          PopupMenuButton<double>(
            tooltip: 'حجم الخط',
            icon: const Icon(Icons.text_fields),
            onSelected: (value) => setState(() => _fontSize = value),
            itemBuilder: (context) => [
              for (final size in [10.0, 12.0, 13.0, 15.0, 17.0, 20.0])
                PopupMenuItem(
                  value: size,
                  child: Text('${size.toInt()} px'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _SessionBar(
            tabs: _tabs,
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
            onClose: _closeTab,
          ),
          if (tab != null)
            Expanded(
              child: TerminalView(
                tab.terminal,
                controller: tab.controller,
                autofocus: true,
                backgroundOpacity: 1,
                cursorType: TerminalCursorType.block,
                textStyle: TerminalStyle(
                  fontSize: _fontSize,
                  fontFamily: 'monospace',
                ),
                simulateScroll: true,
              ),
            )
          else
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          _StatusBar(tab: tab),
          _ExtraKeys(onSend: _sendRaw),
        ],
      ),
    );
  }
}

class _SessionBar extends StatelessWidget {
  const _SessionBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    required this.onClose,
  });

  final List<_TerminalTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Future<void> Function(int) onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelect(index),
            child: Container(
              constraints: const BoxConstraints(minWidth: 105),
              padding: const EdgeInsets.only(left: 10, right: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1B241D)
                    : const Color(0xFF0F130F),
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? Colors.greenAccent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    size: 14,
                    color: tab.connected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tab.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 14,
                    onPressed: () => unawaited(onClose(index)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.tab});

  final _TerminalTab? tab;

  @override
  Widget build(BuildContext context) {
    final connected = tab?.service.isInteractiveRunning == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFF111511),
      child: Row(
        children: [
          Icon(
            connected ? Icons.circle : Icons.circle_outlined,
            size: 9,
            color: connected ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              connected
                  ? 'Native PTY • /system/bin/sh • VT/xterm • 10,000 scrollback'
                  : 'PTY unavailable / stopped',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          if (tab != null)
            Text(
              tab!.name,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Color(0xFF91A995),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExtraKeys extends StatelessWidget {
  const _ExtraKeys({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    const keys = <MapEntry<String, String>>[
      MapEntry('ESC', '\x1b'),
      MapEntry('TAB', '\t'),
      MapEntry('CTRL-C', '\x03'),
      MapEntry('CTRL-D', '\x04'),
      MapEntry('ALT', '\x1b'),
      MapEntry('←', '\x1b[D'),
      MapEntry('↑', '\x1b[A'),
      MapEntry('↓', '\x1b[B'),
      MapEntry('→', '\x1b[C'),
      MapEntry('HOME', '\x1b[H'),
      MapEntry('END', '\x1b[F'),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          itemCount: keys.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final item = keys[index];
            return Material(
              color: const Color(0xFF171B18),
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () => onSend(item.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: Text(
                      item.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFB7C7BA),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
