import 'package:flutter/material.dart';
import 'dart:io';

class ProcessManager extends StatefulWidget {
  const ProcessManager({super.key});

  @override
  State<ProcessManager> createState() => _ProcessManagerState();
}

class _ProcessManagerState extends State<ProcessManager> {
  List<ProcessInfo> _processes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await Process.run('ps', ['-A']);
      final lines = result.stdout.toString().split('\n');
      _processes = lines.skip(1).where((l) => l.trim().isNotEmpty).map((line) {
        final parts = line.trim().split(RegExp(r'\s+'));
        return ProcessInfo(
          pid: parts.isNotEmpty ? parts[0] : '0',
          name: parts.length > 3 ? parts.last : 'unknown',
        );
      }).toList();
    } catch (_) {}
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Process Manager'),
        backgroundColor: Colors.orange.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProcesses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _processes.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: const Icon(Icons.code, color: Colors.orange),
                title: Text(_processes[i].name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('PID: ${_processes[i].pid}', style: const TextStyle(color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red),
                  onPressed: () => _killProcess(_processes[i].pid),
                ),
              ),
            ),
    );
  }

  void _killProcess(String pid) async {
    await Process.run('kill', ['-9', pid]);
    _loadProcesses();
  }
}

class ProcessInfo {
  final String pid;
  final String name;
  ProcessInfo({required this.pid, required this.name});
}
