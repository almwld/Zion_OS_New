import 'dart:async';
import '../lib/engine/config/engine_config.dart';
import '../lib/engine/config/engine_mode.dart';
import '../lib/engine/engine_bootstrap.dart';

Future<void> main() async {
  final engine = await EngineBootstrap.init(const EngineConfig(
    defaultMode: EngineMode.local,
    localModelPath: '/storage/emulated/0/Download/model.gguf',
    githubToken: String.fromEnvironment('GITHUB_TOKEN'),
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
      goal: 'افحص حالة البناء في PR رقم 76، وحدد سبب الفشل واقترح إصلاحاً.',
      context: const {'owner': 'almwld', 'repo': 'Zion_OS_New', 'pr': 76},
    );
    print(result.report);

    // التبديل صريح؛ لا يوجد fallback تلقائي إلى السحابة.
    // يتطلب الوضع السحابي إعداد مفتاح API في EngineConfig.
  } finally {
    await approvals.cancel();
    await subscription.cancel();
    await engine.dispose();
  }
}