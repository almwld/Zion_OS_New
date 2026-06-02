import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class HealthCalendarScreen extends StatefulWidget {
  const HealthCalendarScreen({super.key});
  @override
  State<HealthCalendarScreen> createState() => _HealthCalendarScreenState();
}

class _HealthCalendarScreenState extends State<HealthCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;

  List<Map<String, String>> _getEvents(DateTime day) {
    final events = <Map<String, String>>[];
    if (day.day == 15) events.add({'title': 'موعد د. علي المولد', 'time': '10:30 ص', 'type': 'موعد', 'color': '#4CAF50'});
    if (day.day == 18) events.add({'title': 'موعد د. حسن رضا', 'time': '2:00 م', 'type': 'موعد', 'color': '#2196F3'});
    if (day.day == 22) { events.add({'title': 'موعد د. فاطمة', 'time': '9:00 ص', 'type': 'موعد', 'color': '#9C27B0'}); events.add({'title': 'تجديد وصفة', 'time': 'طوال اليوم', 'type': 'تذكير', 'color': '#F44336'}); }
    if (day.day == 25) events.add({'title': 'تحليل شامل', 'time': '8:00 ص', 'type': 'تحليل', 'color': '#00BCD4'});
    if (day.day == 1) events.add({'title': 'تجديد الاشتراك', 'time': 'طوال اليوم', 'type': 'تذكير', 'color': '#E91E63'});
    if (day.weekday == 6) events.add({'title': 'قياس ضغط', 'time': 'صباحاً', 'type': 'تذكير', 'color': '#FF5722'});
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEvents(_selectedDate);
    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الصحي', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})]),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: TableCalendar(
            firstDay: DateTime(2024), lastDay: DateTime(2028),
            focusedDay: _focusedDate, calendarFormat: _format,
            onFormatChanged: (f) => setState(() => _format = f),
            selectedDayPredicate: (d) => isSameDay(_selectedDate, d),
            onDaySelected: (d, f) => setState(() { _selectedDate = d; _focusedDate = f; }),
            calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle)),
            headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true),
            locale: 'ar',
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Spacer(), Text('${events.length} أحداث', style: const TextStyle(color: AppColors.primary))])),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('لا توجد أحداث', style: TextStyle(color: AppColors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  itemBuilder: (context, i) {
                    final e = events[i];
                    final color = Color(int.parse(e['color']!.replaceFirst('#', '0xff')));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8)]),
                      child: Row(children: [
                        Container(width: 4, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['title']!, style: const TextStyle(fontWeight: FontWeight.bold)), Text(e['time']!, style: TextStyle(color: color, fontSize: 11))])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(e['type']!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
