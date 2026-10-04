import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'service_status.dart';
import 'quick_actions.dart';
class ControlCenterUI extends StatelessWidget {
  const ControlCenterUI({super.key});
  @override Widget build(BuildContext c){
    final status=ServiceStatus(); final actions=QuickActions();
    return Scaffold(
      appBar:AppBar(title:const Text('Control Center')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          Dashboard(),const SizedBox(height:16),
          const Text('Services',style:TextStyle(fontWeight:FontWeight.bold)),
          for(final e in status.all().entries)ListTile(title:Text(e.key),leading:Icon(e.value?Icons.check_circle:Icons.error)),
          const Divider(),
          const Text('Quick actions',style:TextStyle(fontWeight:FontWeight.bold)),
          for(final a in actions.actions)ListTile(title:Text(a),leading:const Icon(Icons.flash_on)),
        ],
      ),
    );
  }
}
