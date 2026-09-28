import 'package:flutter/material.dart';
import 'dart:io';

class MediaCenter extends StatefulWidget {
  const MediaCenter({super.key});

  @override
  State<MediaCenter> createState() => _MediaCenterState();
}

class _MediaCenterState extends State<MediaCenter> {
  int _selectedTab = 0;
  final List<String> _tabs = ['الصور', 'الموسيقى', 'الفيديو', 'الملفات'];
  
  final List<Map<String, dynamic>> _mediaFiles = [
    {'name': 'IMG_20241201.jpg', 'size': '2.5 MB', 'date': '2024-12-01', 'type': 'image'},
    {'name': 'VIDEO_20241130.mp4', 'size': '15.2 MB', 'date': '2024-11-30', 'type': 'video'},
    {'name': 'song.mp3', 'size': '3.8 MB', 'date': '2024-11-29', 'type': 'audio'},
    {'name': 'screenshot.png', 'size': '1.2 MB', 'date': '2024-11-28', 'type': 'image'},
    {'name': 'backup.zip', 'size': '45.6 MB', 'date': '2024-11-27', 'type': 'file'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مركز الوسائط', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          onTap: (index) => setState(() => _selectedTab = index),
          indicatorColor: const Color(0xFF00FF41),
          labelColor: const Color(0xFF00FF41),
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: Column(
        children: [
          // مساحة التخزين
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF41).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.storage, color: Color(0xFF00FF41)),
                    SizedBox(width: 8),
                    Text('مساحة التخزين', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.grey[800],
                  color: const Color(0xFF00FF41),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('65% مستخدم', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('12.5 GB / 32 GB', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // قائمة الملفات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _mediaFiles.where((f) {
                if (_selectedTab == 0) return f['type'] == 'image';
                if (_selectedTab == 1) return f['type'] == 'audio';
                if (_selectedTab == 2) return f['type'] == 'video';
                return true;
              }).length,
              itemBuilder: (context, index) {
                final files = _mediaFiles.where((f) {
                  if (_selectedTab == 0) return f['type'] == 'image';
                  if (_selectedTab == 1) return f['type'] == 'audio';
                  if (_selectedTab == 2) return f['type'] == 'video';
                  return true;
                }).toList();
                final file = files[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        file['type'] == 'image' ? Icons.image :
                        file['type'] == 'audio' ? Icons.audiotrack :
                        file['type'] == 'video' ? Icons.videocam : Icons.insert_drive_file,
                        color: const Color(0xFF00FF41),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file['name'], style: const TextStyle(color: Colors.white)),
                            Text('${file['size']} • ${file['date']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF00FF41)),
                        onPressed: () {},
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
}
