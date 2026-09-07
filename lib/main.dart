import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart' as provider;

import 'core/services/unified_core_service.dart';
import 'features/terminal/terminal_service.dart';
import 'providers/theme_provider.dart';
import 'screens/lock_screen.dart';
import 'security/core/security_core.dart';
import 'security/runtime/runtime_integrity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final securityCore = SecurityCore();
  final runtimeReport = const RuntimeIntegrity().verify(securityCore);
  securityCore.auditLogger.log(
    action: 'application.bootstrap',
    actor: 'zion-os',
    outcome: runtimeReport.passed ? 'passed' : 'failed',
    metadata: <String, Object?>{
      'runtimeIntegrity': runtimeReport.passed,
      'failedChecks': runtimeReport.failedChecks,
    },
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('ar'),
      child: ZionOSApp(securityCore: securityCore),
    ),
  );
}

class ZionOSApp extends StatelessWidget {
  const ZionOSApp({required this.securityCore, super.key});

  final SecurityCore securityCore;

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        provider.Provider<SecurityCore>.value(value: securityCore),
        provider.Provider<TerminalService>(create: (_) => TerminalService(securityCore), dispose: (_, service) => service.dispose()),
        provider.Provider<UnifiedCoreService>(create: (_) => UnifiedCoreService()),
      ],
      child: provider.Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Zion OS',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getThemeData(),
            localizationsDelegates: [
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const LockScreen(),
          );
        },
      ),
    );
  }
}
