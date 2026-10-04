import 'package:flutter/widgets.dart';
class ReducedMotion { static bool of(BuildContext context)=>MediaQuery.maybeOf(context)?.disableAnimations??false; }