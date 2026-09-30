import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../core/window_manager.dart';
class WindowManagerProvider extends StatelessWidget {
  const WindowManagerProvider({super.key,required this.manager,required this.child});
  final WindowManager manager;
  final Widget child;
  @override Widget build(BuildContext context)=>ChangeNotifierProvider<WindowManager>.value(value:manager,child:child);
}