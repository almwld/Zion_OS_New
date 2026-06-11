import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};
  final List<Map<String, dynamic>> _eventList = [];
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _eventDescController = TextEditingController();
  
  final List<Map<String, dynamic>> _holidays = [
    {'date': '2025-01-01', 'name': 'New Year\'s Day', 'type': 'holiday'},
    {'date': '2025-01-07', 'name': 'Christmas (Coptic)', 'type': 'holiday'},
    {'date': '2025-04-25', 'name': 'Sinai Liberation Day', 'type': 'holiday'},
    {'date': '2025-05-01', 'name': 'Labor Day', 'type': 'holiday'},
    {'date': '2025-07-23', 'name': 'Revolution Day', 'type': 'holiday'},
    {'date': '2025-10-06', 'name': 'Armed Forces Day', 'type': 'holiday'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    _eventList.addAll([
      {'title': 'Team Meeting', 'date': '2025-06-15', 'time': '10:00 AM', 'description': 'Weekly sync', 'color': 0xFF00BCD4},
      {'title': 'Project Deadline', 'date': '2025-06-20', 'time': '05:00 PM', 'description': 'Submit final report', 'color': 0xFFF44336},
      {'title': 'Doctor Appointment', 'date': '2025-06-18', 'time': '02:30 PM', 'description': 'Annual checkup', 'color': 0xFF4CAF50},
      {'title': 'Birthday Party', 'date': '2025-06-25', 'time': '07:00 PM', 'description': 'Ahmed\'s birthday', 'color': 0xFFFF9800},
    ]);

    for (var event in _eventList) {
      final date = DateTime.parse(event['date']);
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add({
        'title': event['title'],
        'time': event['time'],
        'description': event['description'],
        'color': event['color'].toString(),
      });
    }

    for (var holiday in _holidays) {
      final date = DateTime.parse(holiday['date']);
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add({
        'title': holiday['name'],
        'time': 'All Day',
        'description': 'Public Holiday',
        'color': '0xFFFF9800',
      });
    }
  }

  void _addEvent() {
    if (_selectedDay == null || _eventTitleController.text.isEmpty) return;

    final newEvent = {
      'title': _eventTitleController.text,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
      'time': _eventTimeController.text.isEmpty ? '12:00 PM' : _eventTimeController.text,
      'description': _eventDescController.text.isEmpty ? 'No description' : _eventDescController.text,
      'color': 0xFF00BCD4,
    };
    
    setState(() {
      _eventList.add(newEvent);
      final date = _selectedDay!;
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add({
        'title': newEvent['title'],
        'time': newEvent['time'],
        'description': newEvent['description'],
        'color': newEvent['color'].toString(),
      });
    });
    
    _eventTitleController.clear();
    _eventTimeController.clear();
    _eventDescController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event added'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  void _deleteEvent(Map<String, dynamic> event) {
    setState(() {
      _eventList.removeWhere((e) => e['title'] == event['title'] && e['date'] == event['date']);
      final date = DateTime.parse(event['date']);
      if (_events[date] != null) {
        _events[date]!.removeWhere((e) => e['title'] == event['title']);
        if (_events[date]!.isEmpty) {
          _events.remove(date);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsForDay = _selectedDay != null ? _events[_selectedDay] ?? [] : [];
    final todayEvents = _eventList.where((e) => e['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now())).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Color(0xFF00BCD4)),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            eventLoader: (day) => _events[day] ?? [],
            calendarStyle: CalendarStyle(
              weekendTextStyle: const TextStyle(color: Colors.white70),
              defaultTextStyle: const TextStyle(color: Colors.white),
              holidayTextStyle: const TextStyle(color: Colors.white),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markerSize: 6,
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              titleTextStyle: TextStyle(color: Color(0xFF00BCD4), fontSize: 18),
              formatButtonVisible: true,
              formatButtonTextStyle: TextStyle(color: Color(0xFF00BCD4)),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Color(0xFF00BCD4)),
              weekendStyle: TextStyle(color: Color(0xFF00BCD4)),
            ),
          ),
          
          const Divider(color: Color(0xFF00BCD4), height: 1),
          
          // Today's Events
          if (todayEvents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Events', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...todayEvents.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(e['color']),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e['title'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        Text(e['time'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          
          // Events List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventsForDay.length,
              itemBuilder: (context, index) {
                final event = eventsForDay[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(int.parse(event['color'])).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(int.parse(event['color'])).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(event['color'])).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.event, color: Color(int.parse(event['color'])), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(event['time'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            if (event['description'] != 'No description')
                              Text(event['description'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteEvent({
                          'title': event['title'],
                          'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Event - ${DateFormat('yyyy-MM-dd').format(_selectedDay ?? DateTime.now())}',
            style: const TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _eventTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Event Title',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _eventTimeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Time (e.g., 10:00 AM)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _eventDescController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: _addEvent, child: const Text('Add', style: TextStyle(color: Color(0xFF00BCD4)))),
        ],
      ),
    );
  }
}
