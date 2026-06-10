import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/features/lock/lock_screen.dart';
import 'src/features/desktop/glass_desktop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const ZionOS());
}

class ZionOS extends StatelessWidget {
  const ZionOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zion OS v3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.green,
      ),
      initialRoute: '/lock',
      routes: {
        '/lock': (context) => const LockScreen(),
        '/home': (context) => const GlassDesktop(),
      },
    );
  }
}
