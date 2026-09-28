import 'package:flutter/material.dart';

class ZionNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;

  ZionNotification({
    required this.title,
    required this.message,
    this.icon = Icons.info,
    this.color = const Color(0xFF00FF41),
  }) : time = DateTime.now();
}

class ZionNotificationCenter extends ChangeNotifier {
  final List<ZionNotification> _notifications = [];

  List<ZionNotification> get notifications => _notifications.reversed.toList();
  int get unreadCount => _notifications.length;

  void add(String title, String message, {IconData icon = Icons.info, Color color = const Color(0xFF00FF41)}) {
    _notifications.add(ZionNotification(title: title, message: message, icon: icon, color: color));
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}

class ZionNotificationPanel extends StatelessWidget {
  const ZionNotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E0A),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوان
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1A3A1A))),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications, color: Color(0xFF00FF41), size: 18),
                SizedBox(width: 8),
                Text('الإشعارات', style: TextStyle(color: Color(0xFF00FF41), fontSize: 14, fontWeight: FontWeight.bold)),
                Spacer(),
                Text('3', style: TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
              ],
            ),
          ),
          // قائمة الإشعارات
          SizedBox(
            height: 200,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _NotificationItem(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  title: 'تم الاتصال بـ Kali Linux',
                  message: '600+ أداة جاهزة للاستخدام',
                  time: 'الآن',
                ),
                _NotificationItem(
                  icon: Icons.wifi,
                  color: Colors.blue,
                  title: 'تم الاتصال بالشبكة',
                  message: 'IP: 192.168.1.100',
                  time: 'منذ 5 دقائق',
                ),
                _NotificationItem(
                  icon: Icons.security,
                  color: Colors.orange,
                  title: 'تحديث أمني متاح',
                  message: 'يتوفر تحديث أمني جديد',
                  time: 'منذ 30 دقيقة',
                ),
              ],
            ),
          ),
          // زر مسح الكل
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1A3A1A))),
            ),
            child: GestureDetector(
              onTap: () {},
              child: const Center(
                child: Text('مسح الكل', style: TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}
