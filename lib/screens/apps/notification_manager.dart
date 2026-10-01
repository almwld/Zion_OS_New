import 'package:flutter/material.dart';
import '../../features/notifications/notification_daemon.dart';

class NotificationManagerApp extends StatefulWidget {
  const NotificationManagerApp({super.key});
  @override
  State<NotificationManagerApp> createState() => _NotificationManagerAppState();
}

class _NotificationManagerAppState extends State<NotificationManagerApp> {
  late final NotificationDaemon _daemon;
  bool _showRead = true;
  bool _showUnread = true;
  String _selectedFilter = 'all';
  static const _filters = <String>['all','system','security','update','info','success','warning','error'];

  @override
  void initState() {
    super.initState();
    _daemon = NotificationDaemon();
    _daemon.addListener(_changed);
    _init();
  }

  Future<void> _init() async {
    await _daemon.init();
    if (mounted) setState(() {});
  }

  void _changed() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _daemon.removeListener(_changed);
    _daemon.dispose();
    super.dispose();
  }

  List<ZionDesktopNotification> _filtered() {
    Iterable<ZionDesktopNotification> items = _daemon.notifications;
    if (_selectedFilter != 'all') items = items.where((n) => n.type.name == _selectedFilter);
    if (!_showRead) items = items.where((n) => !n.read);
    if (!_showUnread) items = items.where((n) => n.read);
    return items.toList(growable: false);
  }

  Color _color(ZionNotificationType type) {
    switch (type) {
      case ZionNotificationType.security:
      case ZionNotificationType.error: return Colors.redAccent;
      case ZionNotificationType.warning: return Colors.orangeAccent;
      case ZionNotificationType.success: return Colors.greenAccent;
      case ZionNotificationType.update: return Colors.blueAccent;
      case ZionNotificationType.system: return const Color(0xFF00BCD4);
      case ZionNotificationType.info: return Colors.lightBlueAccent;
    }
  }

  IconData _icon(ZionNotificationType type) {
    switch (type) {
      case ZionNotificationType.security: return Icons.security;
      case ZionNotificationType.error: return Icons.error_outline;
      case ZionNotificationType.warning: return Icons.warning_amber;
      case ZionNotificationType.success: return Icons.check_circle_outline;
      case ZionNotificationType.update: return Icons.system_update_alt;
      case ZionNotificationType.system: return Icons.settings_outlined;
      case ZionNotificationType.info: return Icons.info_outline;
    }
  }

  String _time(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'الآن';
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} د';
    if (d.inHours < 24) return 'منذ ${d.inHours} س';
    if (d.inDays < 7) return 'منذ ${d.inDays} يوم';
    return '${t.day.toString().padLeft(2,'0')}/${t.month.toString().padLeft(2,'0')}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(children: [
          const Text('Notification Manager', style: TextStyle(color: Color(0xFF00BCD4))),
          if (_daemon.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
              child: Text('${_daemon.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ]),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all, color: Color(0xFF00BCD4)),
            onPressed: _daemon.unreadCount == 0 ? null : _daemon.markAllRead,
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF00BCD4)),
            onPressed: _daemon.notifications.isEmpty ? null : _daemon.clear,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(
            labelColor: Color(0xFF00BCD4),
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFF00BCD4),
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.source_outlined), text: 'Sources'),
            ],
          ),
          Expanded(child: TabBarView(children: [_buildNotifications(items), _buildSources()])),
        ]),
      ),
    );
  }

  Widget _buildNotifications(List<ZionDesktopNotification> items) {
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          children: _filters.map((filter) => Padding(
            padding: const EdgeInsets.only(right: 7, top: 6, bottom: 6),
            child: FilterChip(
              label: Text(filter.toUpperCase(), style: TextStyle(color: _selectedFilter == filter ? Colors.black : const Color(0xFF00BCD4))),
              selected: _selectedFilter == filter,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.transparent,
              selectedColor: const Color(0xFF00BCD4),
            ),
          )).toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          const Text('Show:', style: TextStyle(color: Colors.white54)),
          const SizedBox(width: 10),
          FilterChip(label: const Text('READ', style: TextStyle(color: Color(0xFF00BCD4))), selected: _showRead, onSelected: (_) => setState(() => _showRead = !_showRead), backgroundColor: Colors.transparent, selectedColor: const Color(0xFF00BCD4).withOpacity(.2)),
          const SizedBox(width: 8),
          FilterChip(label: const Text('UNREAD', style: TextStyle(color: Color(0xFF00BCD4))), selected: _showUnread, onSelected: (_) => setState(() => _showUnread = !_showUnread), backgroundColor: Colors.transparent, selectedColor: const Color(0xFF00BCD4).withOpacity(.2)),
        ]),
      ),
      const Divider(color: Color(0xFF00BCD4), height: 1),
      Expanded(
        child: items.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text('لا توجد إشعارات محفوظة', style: TextStyle(color: Colors.white38)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];
                final color = _color(n.type);
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) => _daemon.remove(n.id),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: n.read ? null : () => _daemon.markRead(n.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: n.read ? Colors.white.withOpacity(.03) : color.withOpacity(.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(.3))),
                      child: Row(children: [
                        Icon(_icon(n.type), color: color, size: 25),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: TextStyle(color: n.read ? Colors.white70 : color, fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(n.message, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 3),
                          Text(_time(n.timestamp), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ])),
                        if (!n.read) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      ]),
                    ),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  Widget _buildSources() {
    final sources = <String>{for (final n in _daemon.notifications) n.source}.toList()..sort();
    if (sources.isEmpty) return const Center(child: Text('لا توجد مصادر نشطة', style: TextStyle(color: Colors.white38)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final count = _daemon.notifications.where((n) => n.source == source).length;
        final unread = _daemon.notifications.where((n) => n.source == source && !n.read).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(.25))),
          child: Row(children: [
            const Icon(Icons.apps_outlined, color: Color(0xFF00BCD4)),
            const SizedBox(width: 12),
            Expanded(child: Text(source, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Text('$count', style: const TextStyle(color: Colors.white54)),
            if (unread > 0) ...[const SizedBox(width: 10), Text('$unread unread', style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 11))],
          ]),
        );
      },
    );
  }
}
