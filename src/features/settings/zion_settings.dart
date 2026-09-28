import 'package:flutter/material.dart';

class ZionSettings extends StatelessWidget {
  const ZionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Zion Settings'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.green),
            title: const Text('Theme', style: TextStyle(color: Colors.white)),
            trailing: const Text('Matrix', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.green),
            title: const Text('Security', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.update, color: Colors.green),
            title: const Text('Updates', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.green),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            trailing: const Text('Zion OS v3.0', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
