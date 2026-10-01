import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_zion/features/notifications/notification_daemon.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('notification daemon persists, deduplicates and restores history',() async {
    SharedPreferences.setMockInitialValues({});
    final first=NotificationDaemon(storageKey:'test.notifications');
    await first.add(title:'Build',message:'Build finished',type:ZionNotificationType.success,id:'build-1');
    await first.add(title:'Build',message:'Build finished',type:ZionNotificationType.success,id:'build-1');
    expect(first.notifications,hasLength(1)); expect(first.unreadCount,1);
    await first.markRead('build-1'); expect(first.unreadCount,0);
    final second=NotificationDaemon(storageKey:'test.notifications'); await second.init();
    expect(second.notifications,hasLength(1)); expect(second.notifications.single.read,isTrue);
    await second.clear(); expect(second.notifications,isEmpty);
  });
}