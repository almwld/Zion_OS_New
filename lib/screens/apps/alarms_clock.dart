import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class AlarmsClockApp extends StatefulWidget {
  const AlarmsClockApp({super.key});

  @override
  State<AlarmsClockApp> createState() => _AlarmsClockAppState();
}

class _AlarmsClockAppState extends State<AlarmsClockApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _currentTime = "";
  String _currentDate = "";
  String _currentDay = "";
  
  List<Map<String, dynamic>> _alarms = [];
  Timer? _clockTimer;
  Timer? _alarmChecker;
  
  // Timer state
  int _timerSeconds = 0;
  Timer? _countdownTimer;
  bool _timerRunning = false;
  
  // Stopwatch state
  int _stopwatchMs = 0;
  Timer? _stopwatchTimer;
  bool _stopwatchRunning = false;

  @override
  void initState() {
    _updateDateTime();
    super.initState();
    _updateDateTime();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateTime();
    _loadAlarms();
    _startAlarmChecker();
    
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _currentDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
          _currentDay = _getDayName(now.weekday);
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _alarmChecker?.cancel();
    _countdownTimer?.cancel();
    _stopwatchTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _getDayName(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString('alarms');
    if (alarmsJson != null) {
      try {
        _alarms = List<Map<String, dynamic>>.from(jsonDecode(alarmsJson));
      } catch (_) {}
    }
    if (_alarms.isEmpty) {
      _alarms = [
        {'id': '1', 'time': '07:00', 'label': 'Wake Up', 'enabled': true, 'days': 'Mon-Fri'},
        {'id': '2', 'time': '09:30', 'label': 'Meeting', 'enabled': true, 'days': 'Mon,Wed,Fri'},
        {'id': '3', 'time': '22:00', 'label': 'Sleep', 'enabled': false, 'days': 'Daily'},
      ];
      await _saveAlarms();
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarms', jsonEncode(_alarms));
  }

  void _startAlarmChecker() {
    _alarmChecker = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      final currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      for (final alarm in _alarms) {
        if (alarm['enabled'] && alarm['time'] == currentTime) {
          _showAlarmNotification(alarm['label']);
          // Disable alarm after triggering (optional)
          alarm['enabled'] = false;
          _saveAlarms();
          setState(() {});
        }
      }
    });
  }

  void _showAlarmNotification(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔔 Alarm: $label'),
        backgroundColor: const Color(0xFF00BCD4),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _addAlarm() async {
    final timeController = TextEditingController();
    final labelController = TextEditingController();
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Alarm', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Time (HH:MM)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: labelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Label',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (timeController.text.isNotEmpty) {
                Navigator.pop(context, {'time': timeController.text, 'label': labelController.text});
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
    
    if (result != null && result['time'].isNotEmpty) {
      setState(() {
        _alarms.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'time': result['time'],
          'label': result['label'].isEmpty ? 'Alarm' : result['label'],
          'enabled': true,
          'days': 'Daily',
        });
        _saveAlarms();
      });
    }
  }

  void _toggleAlarm(int index) {
    setState(() {
      _alarms[index]['enabled'] = !_alarms[index]['enabled'];
      _saveAlarms();
    });
  }

  void _deleteAlarm(int index) {
    setState(() {
      _alarms.removeAt(index);
      _saveAlarms();
    });
  }

  void _startTimer() {
    if (_timerSeconds <= 0) return;
    setState(() => _timerRunning = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds <= 1) {
        timer.cancel();
        setState(() {
          _timerRunning = false;
          _timerSeconds = 0;
        });
        _showAlarmNotification('Timer Finished');
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _startStopwatch() {
    setState(() => _stopwatchRunning = true);
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() => _stopwatchMs += 10);
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() => _stopwatchRunning = false);
  }

  void _resetStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() {
      _stopwatchRunning = false;
      _stopwatchMs = 0;
    });
  }

  String _formatStopwatch(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final hundredths = (ms % 1000) ~/ 10;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hours = (_timerSeconds ~/ 3600);
    final minutes = ((_timerSeconds % 3600) ~/ 60);
    final seconds = (_timerSeconds % 60);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Alarms & Clock', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.access_time), text: 'Clock'),
            Tab(icon: Icon(Icons.alarm), text: 'Alarms'),
            Tab(icon: Icon(Icons.timer), text: 'Timer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClockTab(),
          _buildAlarmsTab(),
          _buildTimerStopwatchTab(),
        ],
      ),
    );
  }

  Widget _buildClockTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentTime,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Color(0xFF00BCD4), letterSpacing: 4, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          Text(
            _currentDate,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _currentDay,
            style: const TextStyle(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addAlarm,
              icon: const Icon(Icons.add),
              label: const Text('Add Alarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _alarms.length,
            itemBuilder: (context, index) {
              final alarm = _alarms[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: alarm['enabled'] ? const Color(0xFF00BCD4).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm['time'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4)),
                          ),
                          Text(
                            alarm['label'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            alarm['days'],
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm['enabled'],
                      onChanged: (_) => _toggleAlarm(index),
                      activeColor: const Color(0xFF00BCD4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAlarm(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimerStopwatchTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF00BCD4),
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFF00BCD4),
            tabs: [
              Tab(icon: Icon(Icons.timer), text: 'Timer'),
              Tab(icon: Icon(Icons.timer_off), text: 'Stopwatch'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTimerTab((_timerSeconds ~/ 3600), ((_timerSeconds % 3600) ~/ 60), (_timerSeconds % 60)),
                _buildStopwatchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerTab(int hours, int minutes, int seconds) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Color(0xFF00BCD4), fontFamily: 'monospace'),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildTimerButton('+1 min', () => setState(() => _timerSeconds += 60))),
                const SizedBox(width: 10),
                Expanded(child: _buildTimerButton('+5 min', () => setState(() => _timerSeconds += 300))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTimerButton('+10 min', () => setState(() => _timerSeconds += 600))),
                const SizedBox(width: 10),
                Expanded(child: _buildTimerButton('Reset', () => setState(() => _timerSeconds = 0), isSecondary: true)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _timerRunning ? _stopTimer : (_timerSeconds > 0 ? _startTimer : null),
                icon: Icon(_timerRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_timerRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _timerRunning ? Colors.red : const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton(String label, VoidCallback onTap, {bool isSecondary = false}) {
    return ElevatedButton(
      onPressed: _timerRunning ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.grey[800] : const Color(0xFF00BCD4),
        foregroundColor: isSecondary ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildStopwatchTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatStopwatch(_stopwatchMs),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Color(0xFF00BCD4), fontFamily: 'monospace'),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stopwatchRunning ? _stopStopwatch : _startStopwatch,
                    icon: Icon(_stopwatchRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(_stopwatchRunning ? 'Stop' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _stopwatchRunning ? Colors.red : const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetStopwatch,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for JSON encoding
String jsonEncode(List<Map<String, dynamic>> data) {
  return data.toString();
}

List<Map<String, dynamic>> jsonDecode(String data) {
  return [];
}
// تأكد من وجود المتغير seconds داخل دالة _buildTimerTab
// أو قم بتعديل استدعاء _buildTimerTab

  void _updateDateTime() {
    // Already handled by timer in initState
  }
