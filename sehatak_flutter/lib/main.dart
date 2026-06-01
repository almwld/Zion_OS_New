import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/firebase_service.dart';
import 'core/themes/theme_manager.dart';
import 'presentation/bloc/auth_bloc/auth_bloc.dart';
import 'presentation/bloc/theme_bloc/theme_bloc.dart';
import 'presentation/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAMcD8bz4fA9s5-MFXz2vlDErLVAdy8YfE',
      appId: '1:302830226901:android:c768d699c649114216415c',
      messagingSenderId: '302830226901',
      projectId: 'sehatak-latform',
      storageBucket: 'sehatak-latform.firebasestorage.app',
    ),
  );

  await FirebaseService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()..add(AppStarted())),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'صحتك',
            debugShowCheckedModeBanner: false,
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
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
