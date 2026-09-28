import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateCalculatorApp extends StatefulWidget {
  const DateCalculatorApp({super.key});

  @override
  State<DateCalculatorApp> createState() => _DateCalculatorAppState();
}

class _DateCalculatorAppState extends State<DateCalculatorApp> {
  int _selectedTab = 0;
  
  // Date Difference
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  int _differenceDays = 30;
  int _differenceWeeks = 4;
  int _differenceMonths = 1;
  
  // Date Addition
  DateTime _baseDate = DateTime.now();
  int _addYears = 0;
  int _addMonths = 0;
  int _addDays = 0;
  DateTime _resultDate = DateTime.now();
  
  // Age Calculator
  DateTime _birthDate = DateTime(1990, 1, 1);
  int _ageYears = 0;
  int _ageMonths = 0;
  int _ageDays = 0;
  int _ageTotalDays = 0;

  @override
  void initState() {
    super.initState();
    _calculateDifference();
    _calculateAddition();
    _calculateAge();
  }

  void _calculateDifference() {
    setState(() {
      _differenceDays = _endDate.difference(_startDate).inDays;
      _differenceWeeks = (_differenceDays / 7).floor();
      _differenceMonths = (_differenceDays / 30.44).floor();
    });
  }

  void _calculateAddition() {
    setState(() {
      _resultDate = DateTime(
        _baseDate.year + _addYears,
        _baseDate.month + _addMonths,
        _baseDate.day + _addDays,
      );
    });
  }

  void _calculateAge() {
    final now = DateTime.now();
    int years = now.year - _birthDate.year;
    int months = now.month - _birthDate.month;
    int days = now.day - _birthDate.day;
    
    if (days < 0) {
      months--;
      final lastMonth = DateTime(now.year, now.month, 0);
      days += lastMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    
    setState(() {
      _ageYears = years;
      _ageMonths = months;
      _ageDays = days;
      _ageTotalDays = now.difference(_birthDate).inDays;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Date Calculator', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.compare_arrows), text: 'Difference'),
            Tab(icon: Icon(Icons.add), text: 'Add/Subtract'),
            Tab(icon: Icon(Icons.person), text: 'Age'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildDifferenceTab(),
          _buildAddSubtractTab(),
          _buildAgeTab(),
        ],
      ),
    );
  }

  Widget _buildDifferenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Start Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Date', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_startDate),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4)),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            _calculateDifference();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // End Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('End Date', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_endDate),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4)),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                            _calculateDifference();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Results
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('DIFFERENCE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 16),
                _buildResultRow('Days', '$_differenceDays'),
                _buildResultRow('Weeks', '$_differenceWeeks'),
                _buildResultRow('Months', '$_differenceMonths'),
                const Divider(color: Colors.white24, height: 20),
                _buildResultRow('Total Hours', '${_differenceDays * 24}'),
                _buildResultRow('Total Minutes', '${_differenceDays * 24 * 60}'),
                _buildResultRow('Total Seconds', '${_differenceDays * 24 * 60 * 60}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSubtractTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Base Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Base Date', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_baseDate),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _baseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4)),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _baseDate = date;
                            _calculateAddition();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add/Subtract Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildAddControl('Years', _addYears, (v) {
                  setState(() { _addYears = v; _calculateAddition(); });
                }),
                const SizedBox(height: 12),
                _buildAddControl('Months', _addMonths, (v) {
                  setState(() { _addMonths = v; _calculateAddition(); });
                }),
                const SizedBox(height: 12),
                _buildAddControl('Days', _addDays, (v) {
                  setState(() { _addDays = v; _calculateAddition(); });
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('RESULT DATE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  _formatDate(_resultDate),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Birth Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Birth Date', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_birthDate),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _birthDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFF00BCD4)),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _birthDate = date;
                            _calculateAge();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Age Results
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('YOUR AGE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAgeBox('Years', _ageYears),
                    _buildAgeBox('Months', _ageMonths),
                    _buildAgeBox('Days', _ageDays),
                  ],
                ),
                const Divider(color: Colors.white24, height: 30),
                _buildResultRow('Total Days', '$_ageTotalDays'),
                _buildResultRow('Total Hours', '${_ageTotalDays * 24}'),
                _buildResultRow('Total Minutes', '${_ageTotalDays * 24 * 60}'),
                _buildResultRow('Total Seconds', '${_ageTotalDays * 24 * 60 * 60}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddControl(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Color(0xFF00BCD4)),
              onPressed: () => onChanged(value - 1),
            ),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeBox(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
