import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskScheduler extends StatefulWidget {
  const TaskScheduler({super.key});
  @override
  State<TaskScheduler> createState() => _TaskSchedulerState();
}

class _TaskSchedulerState extends State<TaskScheduler> {
  static const _key = 'zion_scheduled_tasks_v1';
  final List<Map<String, dynamic>> _tasks = [];
  final _taskNameController = TextEditingController();
  final _commandController = TextEditingController();
  String _selectedInterval = 'Hourly';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _tasks
          ..clear()
          ..addAll(decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_tasks));
  }

  Future<void> _addTask() async {
    final name = _taskNameController.text.trim();
    final command = _commandController.text.trim();
    if (name.isEmpty || command.isEmpty) return;
    setState(() {
      _tasks.add({
        'name': name,
        'command': command,
        'interval': _selectedInterval,
        'enabled': true,
        'created': DateTime.now().toIso8601String(),
      });
    });
    await _save();
    _taskNameController.clear();
    _commandController.clear();
  }

  Future<void> _toggleTask(int index) async {
    setState(() => _tasks[index]['enabled'] = !(_tasks[index]['enabled'] == true));
    await _save();
  }

  Future<void> _deleteTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _save();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        title: const Text('جدولة المهام'),
        backgroundColor: const Color(0xFF101923),
        foregroundColor: const Color(0xFF00BCD4),
      ),
      body: Column(
        children: [
          _buildAddTaskCard(),
          const Divider(color: Colors.white24),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('لا توجد مهام مجدولة', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (ctx, i) => Card(
                      color: const Color(0xFF101923),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: _tasks[i]['enabled'] == true,
                          onChanged: (_) => _toggleTask(i),
                          activeColor: const Color(0xFF00BCD4),
                        ),
                        title: Text(_tasks[i]['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          (_tasks[i]['command']?.toString() ?? '') + '\nالفترة: ' + (_tasks[i]['interval']?.toString() ?? ''),
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
                          onPressed: () => _deleteTask(i),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskCard() {
    return Card(
      color: const Color(0xFF101923),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم المهمة', labelStyle: TextStyle(color: Color(0xFF00BCD4)), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commandController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'الأمر', labelStyle: TextStyle(color: Color(0xFF00BCD4)), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedInterval,
                    items: const [
                      DropdownMenuItem(value: 'Hourly', child: Text('كل ساعة')),
                      DropdownMenuItem(value: 'Daily', child: Text('يوميًا')),
                      DropdownMenuItem(value: 'Weekly', child: Text('أسبوعيًا')),
                      DropdownMenuItem(value: 'Monthly', child: Text('شهريًا')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedInterval = v);
                    },
                    decoration: const InputDecoration(labelText: 'الفترة', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
