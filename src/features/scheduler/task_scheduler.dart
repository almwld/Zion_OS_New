import 'package:flutter/material.dart';

class TaskScheduler extends StatefulWidget {
  const TaskScheduler({super.key});

  @override
  State<TaskScheduler> createState() => _TaskSchedulerState();
}

class _TaskSchedulerState extends State<TaskScheduler> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  String _selectedInterval = 'Hourly';

  void _addTask() {
    if (_taskNameController.text.isEmpty || _commandController.text.isEmpty) return;
    
    setState(() {
      _tasks.add({
        'name': _taskNameController.text,
        'command': _commandController.text,
        'interval': _selectedInterval,
        'enabled': true,
        'created': DateTime.now().toIso8601String(),
      });
    });
    
    _taskNameController.clear();
    _commandController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added')),
    );
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['enabled'] = !_tasks[index]['enabled'];
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Task Scheduler'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Column(
        children: [
          _buildAddTaskCard(),
          const Divider(color: Colors.white24),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks scheduled', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (ctx, i) => Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: _tasks[i]['enabled'],
                          onChanged: (_) => _toggleTask(i),
                          activeColor: Colors.teal,
                        ),
                        title: Text(_tasks[i]['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${_tasks[i]['command']}\nInterval: ${_tasks[i]['interval']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
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
      color: Colors.grey.shade900,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Task Name',
                labelStyle: TextStyle(color: Colors.teal),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commandController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Command',
                labelStyle: TextStyle(color: Colors.teal),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedInterval,
                    items: const [
                      DropdownMenuItem(value: 'Hourly', child: Text('Hourly')),
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    ],
                    onChanged: (v) => setState(() => _selectedInterval = v!),
                    decoration: const InputDecoration(
                      labelText: 'Interval',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('ADD'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
