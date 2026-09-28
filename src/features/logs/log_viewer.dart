import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  List<String> _logs = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  final List<String> _filterOptions = ['ALL', 'INFO', 'WARNING', 'ERROR', 'SUCCESS'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/zion.log');
      
      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        _logs = content.split('\n').where((l) => l.isNotEmpty).toList();
      } else {
        _logs = [
          '[${DateTime.now().toIso8601String()}] [INFO] Zion OS started',
          '[${DateTime.now().toIso8601String()}] [SUCCESS] System ready',
        ];
      }
    } catch (_) {}
    
    setState(() => _isLoading = false);
  }

  Future<void> _clearLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final logFile = File('${dir.path}/zion.log');
    await logFile.writeAsString('');
    _loadLogs();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs cleared')),
    );
  }

  List<String> get _filteredLogs {
    if (_filter == 'ALL') return _logs;
    return _logs.where((log) => log.contains('[$_filter]')).toList();
  }

  Color _getLogColor(String log) {
    if (log.contains('[ERROR]')) return Colors.red;
    if (log.contains('[WARNING]')) return Colors.orange;
    if (log.contains('[SUCCESS]')) return Colors.green;
    if (log.contains('[INFO]')) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Log Viewer'),
        backgroundColor: Colors.amber.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: _filterOptions.map((filter) => FilterChip(
                label: Text(filter),
                selected: _filter == filter,
                onSelected: (selected) {
                  if (selected) setState(() => _filter = filter);
                },
                backgroundColor: Colors.grey.shade800,
                selectedColor: Colors.amber.shade700,
                labelStyle: TextStyle(color: _filter == filter ? Colors.black : Colors.white),
              )).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (ctx, i) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SelectableText(
                        _filteredLogs[i],
                        style: TextStyle(color: _getLogColor(_filteredLogs[i]), fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
