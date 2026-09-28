import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _events = [];
  final TextEditingController _eventController = TextEditingController();

  void _addEvent() {
    if (_eventController.text.isEmpty) return;
    
    setState(() {
      _events.add({
        'date': _selectedDate,
        'title': _eventController.text,
        'time': DateFormat('HH:mm').format(DateTime.now()),
      });
      _eventController.clear();
    });
  }

  void _deleteEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayEvents = _events.where((e) => 
      e['date'].year == _selectedDate.year &&
      e['date'].month == _selectedDate.month &&
      e['date'].day == _selectedDate.day
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF00BCD4)),
                  onPressed: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                  }),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF00BCD4)),
                  onPressed: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                  }),
                ),
              ],
            ),
          ),
          
          // Days of Week
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) => 
                Expanded(
                  child: Text(day, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                )
              ).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Calendar Grid
          Expanded(
            flex: 2,
            child: _buildCalendarGrid(),
          ),
          
          const Divider(color: Color(0xFF00BCD4)),
          
          // Events List
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _eventController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add event...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addEvent,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: todayEvents.isEmpty
                      ? const Center(child: Text('No events', style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          itemCount: todayEvents.length,
                          itemBuilder: (context, index) {
                            final event = todayEvents[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event, color: Color(0xFF00BCD4), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(event['title'], style: const TextStyle(color: Colors.white))),
                                  Text(event['time'], style: const TextStyle(color: Colors.white54)),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () => _deleteEvent(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayNumber = index - startWeekday + 1;
        final isValid = dayNumber >= 1 && dayNumber <= daysInMonth;
        final isToday = isValid && 
          dayNumber == DateTime.now().day &&
          _selectedDate.month == DateTime.now().month &&
          _selectedDate.year == DateTime.now().year;
        final isSelected = isValid && dayNumber == _selectedDate.day;
        
        return GestureDetector(
          onTap: () => setState(() {
            if (isValid) _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
          }),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isValid ? dayNumber.toString() : '',
                style: TextStyle(
                  color: isToday ? const Color(0xFF00BCD4) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
