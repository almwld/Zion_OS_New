import 'package:flutter/material.dart';
import 'dart:io';

class LearningCenter extends StatefulWidget {
  const LearningCenter({super.key});

  @override
  State<LearningCenter> createState() => _LearningCenterState();
}

class _LearningCenterState extends State<LearningCenter> {
  int _selectedCategory = 0;
  final List<String> _categories = ['البداية', 'الشبكات', 'الاختراق', 'الحماية', 'المتقدم'];
  
  final List<Map<String, dynamic>> _lessons = [
    {'title': 'مقدمة في الأمن السيبراني', 'duration': '15 دقيقة', 'level': 'مبتدئ', 'completed': 45},
    {'title': 'أساسيات الشبكات', 'duration': '25 دقيقة', 'level': 'مبتدئ', 'completed': 30},
    {'title': 'أنواع الثغرات', 'duration': '20 دقيقة', 'level': 'متوسط', 'completed': 60},
    {'title': 'اختبار الاختراق', 'duration': '35 دقيقة', 'level': 'متوسط', 'completed': 20},
    {'title': 'التشفير المتقدم', 'duration': '40 دقيقة', 'level': 'متقدم', 'completed': 10},
    {'title': 'هندسة عكسية', 'duration': '50 دقيقة', 'level': 'متقدم', 'completed': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مركز التعلم', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00FF41)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات التعلم
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00FF41).withOpacity(0.2), Colors.black],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('📚', 'الدروس', '24'),
                _buildStatItem('⏱️', 'ساعات التعلم', '18'),
                _buildStatItem('🏆', 'الإنجازات', '7'),
                _buildStatItem('📈', 'التقدم', '42%'),
              ],
            ),
          ),
          // فئات
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00FF41) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.5)),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF00FF41),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          // قائمة الدروس
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF41).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_arrow, color: Color(0xFF00FF41)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson['title'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lesson['duration']} • مستوى ${lesson['level']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF41).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${lesson['completed']}%',
                              style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: lesson['completed'] / 100,
                        backgroundColor: Colors.grey[800],
                        color: const Color(0xFF00FF41),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
