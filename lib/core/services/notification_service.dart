import 'package:flutter/material.dart';
import '../../features/notifications/notification_daemon.dart';

enum NotificationType { info, success, warning, error, system, security, update }

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance=NotificationService._internal(); factory NotificationService()=>_instance; NotificationService._internal();
  final NotificationDaemon _daemon=NotificationDaemon();
  Future<void> init() async {await _daemon.init();notifyListeners();}
  void addNotification({required String title,required String message,required NotificationType type,Duration? autoDismiss}){_add(title:title,message:message,type:type,autoDismiss:autoDismiss);}
  Future<void> _add({required String title,required String message,required NotificationType type,Duration? autoDismiss}) async {final id=DateTime.now().microsecondsSinceEpoch.toString();await _daemon.add(id:id,title:title,message:message,type:ZionNotificationType.values.byName(type.name));if(autoDismiss!=null){await Future<void>.delayed(autoDismiss);await _daemon.remove(id);}notifyListeners();}
  void markAsRead(String id){_daemon.markRead(id);} void markAllAsRead(){_daemon.markAllRead();} void clearAll(){_daemon.clear();} void deleteNotification(String id){_daemon.remove(id);}
  List<Map<String,dynamic>> getNotifications({bool unreadOnly=false})=>_daemon.notifications.where((n)=>!unreadOnly||!n.read).map((n)=>{'id':n.id,'title':n.title,'message':n.message,'type':n.type.name,'timestamp':n.timestamp.toIso8601String(),'read':n.read,'source':n.source,'actionKey':n.actionKey}).toList();
  int getUnreadCount()=>_daemon.unreadCount;
  Color getNotificationColor(NotificationType type){switch(type){case NotificationType.info:return const Color(0xFF00BCD4);case NotificationType.success:return Colors.green;case NotificationType.warning:return Colors.orange;case NotificationType.error:return Colors.red;case NotificationType.system:return Colors.purple;case NotificationType.security:return Colors.amber;case NotificationType.update:return Colors.blue;}}
  IconData getNotificationIcon(NotificationType type){switch(type){case NotificationType.info:return Icons.info_outline;case NotificationType.success:return Icons.check_circle_outline;case NotificationType.warning:return Icons.warning_amber_outlined;case NotificationType.error:return Icons.error_outline;case NotificationType.system:return Icons.computer;case NotificationType.security:return Icons.security;case NotificationType.update:return Icons.system_update;}}
}