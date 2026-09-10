import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart' as provider;

import 'adaptive/adaptive_interface.dart';
import 'core/services/unified_core_service.dart';
import 'features/terminal/terminal_service.dart';
import 'providers/theme_provider.dart';
import 'screens/desktop_home.dart';
import 'screens/lock_screen.dart';
import 'security/core/security_core.dart';
import 'security/runtime/runtime_integrity.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EasyLocalization.ensureInitialized();
  } catch (_) {}

  final preferencesService = PreferencesService();
  await preferencesService.init();

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
        provider.ChangeNotifierProvider(create: (_) => ModeProvider()),
        provider.ChangeNotifierProvider<PreferencesService>.value(value: preferencesService),
        provider.Provider<SecurityCore>.value(value: securityCore),
        provider.Provider<TerminalService>(
          create: (_) => TerminalService(securityCore),
          dispose: (_, service) => service.dispose(),
        ),
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
            home: const AdaptiveInterface(child: AuthenticationGate()),
          );
        },
      ),
    );
  }
}

/// Owns the authentication-to-desktop lifecycle so there is exactly one
/// transition point and the desktop dashboard cannot accidentally be stacked
/// on top of the lock screen.
class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  bool _authenticated = false;

  void _onAuthenticated() {
    if (!mounted || _authenticated) return;
    setState(() => _authenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return const ZionDesktop();
    return LockScreen(onAuthenticated: _onAuthenticated);
  }
}
