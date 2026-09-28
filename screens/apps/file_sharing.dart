import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class FileSharingApp extends StatefulWidget {
  const FileSharingApp({super.key});

  @override
  State<FileSharingApp> createState() => _FileSharingAppState();
}

class _FileSharingAppState extends State<FileSharingApp> {
  int _selectedTab = 0;
  final List<Map<String, dynamic>> _sentFiles = [];
  final List<Map<String, dynamic>> _receivedFiles = [];
  
  // Simulated files
  final List<Map<String, dynamic>> _recentFiles = [
    {'name': 'Document.pdf', 'size': '2.5 MB', 'date': '2024-12-01', 'sender': 'Ahmed', 'status': 'sent'},
    {'name': 'Photo.jpg', 'size': '1.8 MB', 'date': '2024-11-30', 'sender': 'Mohamed', 'status': 'received'},
    {'name': 'Video.mp4', 'size': '15.2 MB', 'date': '2024-11-29', 'sender': 'Ali', 'status': 'sent'},
    {'name': 'Music.mp3', 'size': '3.5 MB', 'date': '2024-11-28', 'sender': 'Sara', 'status': 'received'},
    {'name': 'Archive.zip', 'size': '8.7 MB', 'date': '2024-11-27', 'sender': 'Omar', 'status': 'sent'},
  ];
  
  final List<Map<String, dynamic>> _contacts = [
    {'name': 'Ahmed', 'avatar': 'A', 'online': true, 'color': 0xFF00BCD4},
    {'name': 'Mohamed', 'avatar': 'M', 'online': true, 'color': 0xFF4CAF50},
    {'name': 'Sara', 'avatar': 'S', 'online': false, 'color': 0xFFE91E63},
    {'name': 'Ali', 'avatar': 'A', 'online': true, 'color': 0xFF2196F3},
    {'name': 'Omar', 'avatar': 'O', 'online': false, 'color': 0xFFFF9800},
    {'name': 'Nour', 'avatar': 'N', 'online': true, 'color': 0xFF9C27B0},
  ];

  void _shareFile(Map<String, dynamic> file) {
    Share.share('Check out this file: ${file['name']}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${file['name']}...'), backgroundColor: const Color(0xFF00BCD4)),
    );
  }

  void _sendFile(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending file to ${contact['name']}...'), backgroundColor: const Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('File Sharing', style: TextStyle(color: Color(0xFF00BCD4))),
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
            Tab(icon: Icon(Icons.history), text: 'Recent'),
            Tab(icon: Icon(Icons.people), text: 'Contacts'),
            Tab(icon: Icon(Icons.receipt), text: 'Transfers'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildRecentTab(),
          _buildContactsTab(),
          _buildTransfersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select file to share...'), backgroundColor: Color(0xFF00BCD4)),
          );
        },
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.share, color: Colors.black),
      ),
    );
  }

  Widget _buildRecentTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final file = _recentFiles[index];
        final isSent = file['status'] == 'sent';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(file['name']),
                  color: const Color(0xFF00BCD4),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${file['size']} • ${file['date']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    Row(
                      children: [
                        Icon(
                          isSent ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: isSent ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSent ? 'Sent to ${file['sender']}' : 'Received from ${file['sender']}',
                          style: TextStyle(color: isSent ? Colors.green : Colors.blue, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF00BCD4), size: 20),
                onPressed: () => _shareFile(file),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        
        // Contacts List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(contact['color']).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          contact['avatar'],
                          style: TextStyle(color: Color(contact['color']), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: contact['online'] ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                contact['online'] ? 'Online' : 'Offline',
                                style: TextStyle(color: contact['online'] ? Colors.green : Colors.grey, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _sendFile(contact),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.black,
                      ),
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

  Widget _buildTransfersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('No active transfers', style: TextStyle(color: Colors.white38)),
          SizedBox(height: 8),
          Text('Share files to start transferring', style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (filename.endsWith('.jpg') || filename.endsWith('.png')) return Icons.image;
    if (filename.endsWith('.mp4')) return Icons.video_file;
    if (filename.endsWith('.mp3')) return Icons.audiotrack;
    if (filename.endsWith('.zip') || filename.endsWith('.rar')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }
}
