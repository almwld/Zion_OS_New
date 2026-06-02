import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'core/themes/theme_manager.dart';
import 'presentation/bloc/theme_bloc/theme_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'منصة صحتك',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            themeMode: state is ThemeLoadedState ? state.themeMode : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
