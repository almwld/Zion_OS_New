import 'package:flutter/material.dart';

class TerminalShortcuts extends StatelessWidget {
  final Function(String) onCommandSelected;
  
  const TerminalShortcuts({super.key, required this.onCommandSelected});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shortcuts = [
      {'cmd': 'ls -la', 'desc': 'List all files', 'icon': Icons.folder},
      {'cmd': 'pwd', 'desc': 'Show current path', 'icon': Icons.location_on},
      {'cmd': 'cd /sdcard', 'desc': 'Go to SD card', 'icon': Icons.sd_storage},
      {'cmd': 'mkdir folder', 'desc': 'Create folder', 'icon': Icons.create_new_folder},
      {'cmd': 'rm -rf file', 'desc': 'Delete file', 'icon': Icons.delete},
      {'cmd': 'cat file.txt', 'desc': 'View file', 'icon': Icons.description},
      {'cmd': 'ps aux', 'desc': 'Show processes', 'icon': Icons.settings_applications},
      {'cmd': 'df -h', 'desc': 'Disk usage', 'icon': Icons.storage},
      {'cmd': 'free -m', 'desc': 'Memory usage', 'icon': Icons.memory},
      {'cmd': 'ifconfig', 'desc': 'Network info', 'icon': Icons.network_wifi},
      {'cmd': 'ping 8.8.8.8', 'desc': 'Test connection', 'icon': Icons.speed},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.code, color: Color(0xFF00BCD4)),
                SizedBox(width: 8),
                Text('Quick Commands', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: shortcuts.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> sc = shortcuts[index];
                return ListTile(
                  leading: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(sc['icon'] as IconData, color: const Color(0xFF00BCD4), size: 18),
                  ),
                  title: Text(sc['cmd'] as String, style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace')),
                  subtitle: Text(sc['desc'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () => onCommandSelected(sc['cmd'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
