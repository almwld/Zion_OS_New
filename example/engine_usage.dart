import 'dart:async';
import '../lib/engine/config/engine_config.dart';
import '../lib/engine/config/engine_mode.dart';
import '../lib/engine/engine_bootstrap.dart';

Future<void> main() async {
  final engine = await EngineBootstrap.init(const EngineConfig(
    defaultMode: EngineMode.local,
    localModelPath: '/storage/emulated/0/Download/model.gguf',
    githubToken: String.fromEnvironment('GITHUB_TOKEN'),
    cloudApiKey: String.fromEnvironment('ZION_CLOUD_API_KEY'),
    githubOwner: 'almwld',
    githubRepo: 'Zion_OS_New',
    requireApprovalForWrite: true,
  ));

  final subscription = engine.events.listen((event) {
    print('[${event.type}] ${event.message}');
  });
  final approvals = engine.approvalRequests.listen((request) {
    print('موافقة مطلوبة: ${request.action} / ${request.risk}');
    // في التطبيق الحقيقي، تُعرض الموافقة في الواجهة ثم يستدعى respond().
  });

  try {
    await engine.switchMode(EngineMode.local);
    final result = await engine.runTask(
      goal: 'أصلح خطأ البناء في PR رقم 76 بعد فحص الفحوص والسجلات والملفات، ثم راقب البناء بعد التعديل.',
      context: const {'owner': 'almwld', 'repo': 'Zion_OS_New', 'pr': 76},
    );
    print(result.report);

    // التبديل صريح؛ لا يوجد fallback تلقائي إلى السحابة.
    const cloudKey = String.fromEnvironment('ZION_CLOUD_API_KEY');
    if (cloudKey.isNotEmpty) {
      await engine.switchMode(EngineMode.cloud);
      final cloudResult = await engine.runTask(
        goal: 'لخص نتائج المهمة السابقة وحدد الخطوة التالية.',
        context: {'previousTaskId': result.taskId},
      );
      print(cloudResult.report);
    }
  } finally {
    await approvals.cancel();
    await subscription.cancel();
    await engine.dispose();
  }
}