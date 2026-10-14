import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart' as provider;

import 'core/services/unified_core_service.dart';
import 'core/services/zion_api_audit_bridge.dart';
import 'core/services/zion_pkg_external_bridge.dart';
import 'core/magiczionos/magiczionos_provider.dart';
import 'features/terminal/terminal_service.dart';
import 'providers/theme_provider.dart';
import 'core/theme/theme_manager.dart';
import 'adaptive/adaptive_interface.dart';
import 'app_router.dart';
import 'security/core/security_core.dart';
import 'security/runtime/runtime_integrity.dart';
import 'services/preferences_service.dart';
import 'services/toast_service.dart';
import 'widgets/startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EasyLocalization.ensureInitialized();
  } catch (_) {}

  final preferencesService = PreferencesService();
  await preferencesService.init();

  final securityCore = SecurityCore();
  final runtimeReport = const RuntimeIntegrity().verify(securityCore);
  ZionApiAuditBridge(securityCore).register();
  ZionPkgExternalBridge(securityCore).register();

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
      child: ZionOSApp(
        securityCore: securityCore,
        preferencesService: preferencesService,
      ),
    ),
  );
}

class ZionOSApp extends StatelessWidget {
  const ZionOSApp({
    required this.securityCore,
    required this.preferencesService,
    super.key,
  });

  final SecurityCore securityCore;
  final PreferencesService preferencesService;

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        provider.ChangeNotifierProvider(create: (_) => ThemeManager()),
        provider.ChangeNotifierProvider(create: (_) => ModeProvider()),
        provider.ChangeNotifierProvider<PreferencesService>.value(value: preferencesService),
        provider.Provider<SecurityCore>.value(value: securityCore),
        provider.Provider<TerminalService>(
          create: (_) => TerminalService(securityCore),
          dispose: (_, service) => service.dispose(),
        ),
        provider.Provider<UnifiedCoreService>(create: (_) => UnifiedCoreService()),
        provider.ChangeNotifierProvider<MagiczionosProvider>(
          create: (_) => MagiczionosProvider(auditLogger: securityCore.auditLogger)..initialize(),
        ),
      ],
      child: provider.Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // MaterialApp owns the Zion system/desktop shell theme only.
          // Individual app windows install their own Theme below.
          return MaterialApp(
            navigatorKey: ToastService.navigatorKey,
            title: 'Zion OS',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getThemeData().copyWith(
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xF21B252B),
                contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  side: BorderSide(color: Color(0xFF0D9488)),
                ),
                insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                elevation: 8,
                showCloseIcon: true,
                closeIconColor: Colors.white70,
              ),
            ),
            localizationsDelegates: [
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const ZionStartupGate(),
          );
        },
      ),
    );
  }
}
