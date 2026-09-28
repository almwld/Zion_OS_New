import 'package:flutter/material.dart';

class DocumentsApp extends StatefulWidget {
  const DocumentsApp({super.key});

  @override
  State<DocumentsApp> createState() => _DocumentsAppState();
}

class _DocumentsAppState extends State<DocumentsApp> {
  final List<Map<String, dynamic>> _documents = [
    {'name': 'Annual Report 2024.pdf', 'size': '2.5 MB', 'date': '2024-12-01', 'type': 'PDF'},
    {'name': 'Project Proposal.docx', 'size': '1.8 MB', 'date': '2024-11-28', 'type': 'Word'},
    {'name': 'Budget Summary.xlsx', 'size': '0.9 MB', 'date': '2024-11-25', 'type': 'Excel'},
    {'name': 'Presentation.pptx', 'size': '3.2 MB', 'date': '2024-11-20', 'type': 'PPT'},
    {'name': 'README.txt', 'size': '0.1 MB', 'date': '2024-11-15', 'type': 'TXT'},
    {'name': 'Contract Agreement.pdf', 'size': '1.2 MB', 'date': '2024-11-10', 'type': 'PDF'},
    {'name': 'Meeting Notes.docx', 'size': '0.5 MB', 'date': '2024-11-05', 'type': 'Word'},
  ];

  IconData _getIcon(String type) {
    switch (type) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Word': return Icons.description;
      case 'Excel': return Icons.table_chart;
      case 'PPT': return Icons.slideshow;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'PDF': return Colors.red;
      case 'Word': return Colors.blue;
      case 'Excel': return Colors.green;
      case 'PPT': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Documents', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getColor(doc['type']).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: _getColor(doc['type']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getIcon(doc['type']), color: _getColor(doc['type']), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${doc['size']} • ${doc['date']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColor(doc['type']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(doc['type'], style: TextStyle(color: _getColor(doc['type']), fontSize: 10)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
