import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'zion_desktop.dart';
import 'zion_lock_screen.dart';
import 'core/services/kali_loader_service.dart';
import 'core/services/unified_core_service.dart';

Future<void> _initializeZion() async {
  print('🚀 Initializing Project Zion...');
  
  // استخراج proot المدمج
  final prootExtracted = await KaliLoaderService.extractEmbeddedProot();
  if (prootExtracted) {
    print('✅ Embedded proot ready');
  } else {
    print('⚠️ Could not extract proot, will search system');
  }
  
  // فحص الحالة
  final status = await KaliLoaderService.getStatus();
  print('📊 Status: ${status['mode']}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة الخدمات الأساسية
  await _initializeZion();
  await UnifiedCoreService().healthCheck();
  
  runApp(const ProviderScope(child: ProjectZionApp()));
}

class ProjectZionApp extends StatelessWidget {
  const ProjectZionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Zion',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.green,
      ),
      home: const ZionLockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
