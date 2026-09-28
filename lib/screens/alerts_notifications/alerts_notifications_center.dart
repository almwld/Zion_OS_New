import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/advanced_alerts_service.dart';

class AlertsNotificationsCenter extends StatefulWidget {
  const AlertsNotificationsCenter({super.key});

  @override
  State<AlertsNotificationsCenter> createState() => _AlertsNotificationsCenterState();
}

class _AlertsNotificationsCenterState extends State<AlertsNotificationsCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _alertFilter = 'all';
  String _notificationFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedAlertsService>(
      builder: (context, service, child) {
        final alerts = service.getAlerts();
        final notifications = service.getNotifications();
        final filteredAlerts = _alertFilter == 'all'
            ? alerts
            : alerts.where((a) => a['severity'] == _alertFilter).toList();
        final filteredNotifications = _notificationFilter == 'all'
            ? notifications
            : notifications.where((n) => n['type'] == _notificationFilter).toList();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Alerts & Notifications', style: TextStyle(color: Color(0xFF00BCD4))),
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white54,
              indicatorColor: const Color(0xFF00BCD4),
              tabs: const [
                Tab(icon: Icon(Icons.warning), text: 'Alerts'),
                Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAlertsTab(service, filteredAlerts),
              _buildNotificationsTab(service, filteredNotifications),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(AdvancedAlertsService service, List<Map<String, dynamic>> alerts) {
    return Column(
      children: [
        // Filter and Actions
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAlertFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildAlertFilterChip('Critical', 'critical'),
                    const SizedBox(width: 8),
                    _buildAlertFilterChip('Warning', 'warning'),
                    const SizedBox(width: 8),
                    _buildAlertFilterChip('Info', 'info'),
                    const SizedBox(width: 8),
                    _buildAlertFilterChip('Success', 'success'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: service.markAllAlertsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: const Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: service.clearAlerts,
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear all'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(color: Color(0xFF00BCD4), height: 1),
        
        // Alerts List
        Expanded(
          child: alerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No alerts', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Dismissible(
                      key: Key(alert['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => service.deleteAlert(alert['id']),
                      child: GestureDetector(
                        onTap: () => service.markAlertAsRead(alert['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: alert['read']
                                ? Colors.white.withOpacity(0.03)
                                : _getSeverityColor(alert['severity']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getSeverityColor(alert['severity']).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_getSeverityIcon(alert['severity']), color: _getSeverityColor(alert['severity']), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(alert['title'], style: TextStyle(color: _getSeverityColor(alert['severity']), fontWeight: FontWeight.bold)),
                                    Text(alert['message'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(_formatDate(alert['timestamp']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (!alert['read'])
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(alert['severity']),
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

  Widget _buildNotificationsTab(AdvancedAlertsService service, List<Map<String, dynamic>> notifications) {
    return Column(
      children: [
        // Filter and Actions
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildNotificationFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildNotificationFilterChip('System', 'system'),
                    const SizedBox(width: 8),
                    _buildNotificationFilterChip('Security', 'security'),
                    const SizedBox(width: 8),
                    _buildNotificationFilterChip('Update', 'update'),
                    const SizedBox(width: 8),
                    _buildNotificationFilterChip('Info', 'info'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: service.markAllNotificationsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: const Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: service.clearNotifications,
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear all'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
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
                    final notification = notifications[index];
                    return Dismissible(
                      key: Key(notification['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => service.deleteNotification(notification['id']),
                      child: GestureDetector(
                        onTap: () => service.markNotificationAsRead(notification['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notification['read']
                                ? Colors.white.withOpacity(0.03)
                                : const Color(0xFF00BCD4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(_getNotificationIcon(notification['type']), color: const Color(0xFF00BCD4), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notification['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(notification['message'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(_formatDate(notification['timestamp']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (!notification['read'])
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF00BCD4), shape: BoxShape.circle),
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

  Widget _buildAlertFilterChip(String label, String value) {
    final isSelected = _alertFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : const Color(0xFF00BCD4))),
      selected: isSelected,
      onSelected: (_) => setState(() => _alertFilter = value),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF00BCD4),
    );
  }

  Widget _buildNotificationFilterChip(String label, String value) {
    final isSelected = _notificationFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : const Color(0xFF00BCD4))),
      selected: isSelected,
      onSelected: (_) => setState(() => _notificationFilter = value),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF00BCD4),
    );
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'critical': return Icons.error;
      case 'warning': return Icons.warning;
      case 'success': return Icons.check_circle;
      default: return Icons.info;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      case 'success': return Colors.green;
      default: return const Color(0xFF00BCD4);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'system': return Icons.computer;
      case 'security': return Icons.security;
      case 'update': return Icons.update;
      default: return Icons.notifications;
    }
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
