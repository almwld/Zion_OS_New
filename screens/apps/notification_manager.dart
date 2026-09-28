import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManagerApp extends StatefulWidget {
  const NotificationManagerApp({super.key});

  @override
  State<NotificationManagerApp> createState() => _NotificationManagerAppState();
}

class _NotificationManagerAppState extends State<NotificationManagerApp> {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _appNotifications = [];
  bool _showRead = true;
  bool _showUnread = true;
  String _selectedFilter = 'all';

  final List<String> _filters = ['all', 'system', 'security', 'update', 'info', 'warning'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notifications = [
      {'id': '1', 'title': 'System Update', 'message': 'Zion OS 4.0.1 is available', 'time': '5 min ago', 'type': 'system', 'read': false},
      {'id': '2', 'title': 'Security Alert', 'message': 'Unauthorized access attempt blocked', 'time': '15 min ago', 'type': 'security', 'read': false},
      {'id': '3', 'title': 'App Update', 'message': '4 apps have been updated', 'time': '1 hour ago', 'type': 'update', 'read': true},
      {'id': '4', 'title': 'WiFi Connected', 'message': 'Connected to Home Network', 'time': '2 hours ago', 'type': 'info', 'read': true},
      {'id': '5', 'title': 'Storage Warning', 'message': 'Storage is 85% full', 'time': '3 hours ago', 'type': 'warning', 'read': false},
      {'id': '6', 'title': 'Backup Complete', 'message': 'Automatic backup finished', 'time': 'Yesterday', 'type': 'system', 'read': true},
      {'id': '7', 'title': 'New Feature', 'message': 'App Lock feature added', 'time': 'Yesterday', 'type': 'update', 'read': false},
    ];

    _appNotifications = [
      {'name': 'Terminal', 'enabled': true, 'icon': Icons.terminal},
      {'name': 'File Manager', 'enabled': true, 'icon': Icons.folder},
      {'name': 'Browser', 'enabled': true, 'icon': Icons.public},
      {'name': 'Settings', 'enabled': true, 'icon': Icons.settings},
      {'name': 'Email', 'enabled': false, 'icon': Icons.email},
      {'name': 'Weather', 'enabled': true, 'icon': Icons.wb_sunny},
      {'name': 'Maps', 'enabled': true, 'icon': Icons.map},
      {'name': 'Radio', 'enabled': false, 'icon': Icons.radio},
    ];
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) _notifications[index]['read'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['read'] = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  void _toggleAppNotification(String name) {
    setState(() {
      final index = _appNotifications.indexWhere((a) => a['name'] == name);
      if (index != -1) _appNotifications[index]['enabled'] = !_appNotifications[index]['enabled'];
    });
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'system': return '⚙️';
      case 'security': return '🔒';
      case 'update': return '🔄';
      case 'info': return 'ℹ️';
      case 'warning': return '⚠️';
      default: return '📢';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'system': return const Color(0xFF00BCD4);
      case 'security': return Colors.red;
      case 'update': return Colors.blue;
      case 'warning': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;
    final filteredNotifications = _selectedFilter == 'all'
        ? _notifications
        : _notifications.where((n) => n['type'] == _selectedFilter).toList();
    final displayNotifications = _showRead && _showUnread
        ? filteredNotifications
        : _showRead
            ? filteredNotifications.where((n) => n['read']).toList()
            : filteredNotifications.where((n) => !n['read']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notification Manager', style: TextStyle(color: Color(0xFF00BCD4))),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF00BCD4)),
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF00BCD4)),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xFF00BCD4),
              tabs: [
                Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                Tab(icon: Icon(Icons.apps), text: 'App Settings'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNotificationsTab(displayNotifications, unreadCount),
                  _buildAppSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(List<Map<String, dynamic>> notifications, int unreadCount) {
    return Column(
      children: [
        // Filter Bar
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _filters.map((filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
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
        
        // Read/Unread Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('Show:', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('READ', style: TextStyle(color: Color(0xFF00BCD4))),
                selected: _showRead,
                onSelected: (_) => setState(() => _showRead = !_showRead),
                backgroundColor: Colors.transparent,
                selectedColor: const Color(0xFF00BCD4).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('UNREAD', style: TextStyle(color: Color(0xFF00BCD4))),
                selected: _showUnread,
                onSelected: (_) => setState(() => _showUnread = !_showUnread),
                backgroundColor: Colors.transparent,
                selectedColor: const Color(0xFF00BCD4).withOpacity(0.2),
              ),
            ],
          ),
        ),
        
        const Divider(color: Color(0xFF00BCD4), height: 1),
        
        // Notifications List
        Expanded(
          child: notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Dismissible(
                      key: Key(n['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteNotification(n['id']),
                      child: GestureDetector(
                        onTap: () => _markAsRead(n['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: n['read'] 
                                ? Colors.white.withOpacity(0.03)
                                : _getTypeColor(n['type']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTypeColor(n['type']).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(_getTypeIcon(n['type']), style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['title'],
                                      style: TextStyle(
                                        color: n['read'] ? Colors.white70 : _getTypeColor(n['type']),
                                        fontWeight: n['read'] ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n['message'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    Text(n['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (!n['read'])
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(n['type']),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppSettingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appNotifications.length,
      itemBuilder: (context, index) {
        final app = _appNotifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(app['icon'], color: const Color(0xFF00BCD4), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: app['enabled'],
                onChanged: (_) => _toggleAppNotification(app['name']),
                activeColor: const Color(0xFF00BCD4),
              ),
            ],
          ),
        );
      },
    );
  }
}
