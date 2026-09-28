import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedColor = 0;
  
  final List<Color> _noteColors = [
    const Color(0xFF1A1A1A),
    const Color(0xFF2D1B1B),
    const Color(0xFF1B2D1B),
    const Color(0xFF1B1B2D),
    const Color(0xFF2D2D1B),
  ];
  
  final List<String> _colorNames = ['Dark', 'Red', 'Green', 'Blue', 'Yellow'];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes');
    if (notesJson != null) {
      try {
        _notes = List<Map<String, dynamic>>.from(jsonDecode(notesJson));
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(_notes));
  }

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Content',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Note Color', style: TextStyle(color: Color(0xFF00BCD4))),
            const SizedBox(height: 5),
            Row(
              children: List.generate(_noteColors.length, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _noteColors[index],
                      shape: BoxShape.circle,
                      border: _selectedColor == index 
                          ? Border.all(color: const Color(0xFF00BCD4), width: 2)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _notes.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': titleController.text,
                    'content': contentController.text,
                    'color': _selectedColor,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  _saveNotes();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note added'), backgroundColor: Color(0xFF00BCD4)),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title']);
    final contentController = TextEditingController(text: note['content']);
    int tempColor = note['color'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Note Color', style: TextStyle(color: Color(0xFF00BCD4))),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(_noteColors.length, (index) {
                    return GestureDetector(
                      onTap: () => setStateDialog(() => tempColor = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _noteColors[index],
                          shape: BoxShape.circle,
                          border: tempColor == index 
                              ? Border.all(color: const Color(0xFF00BCD4), width: 2)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() {
                note['title'] = titleController.text;
                note['content'] = contentController.text;
                note['color'] = tempColor;
                _saveNotes();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note updated'), backgroundColor: Color(0xFF00BCD4)),
              );
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() {
                _notes.removeWhere((n) => n['id'] == note['id']);
                _saveNotes();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted'), backgroundColor: Color(0xFF00BCD4)),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _noteColors[note['color']],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note['title'],
                style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                note['content'],
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editNote(note);
                    },
                    child: const Text('Edit', style: TextStyle(color: Color(0xFF00BCD4))),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteNote(note);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _searchQuery.isEmpty
        ? _notes
        : _notes.where((note) =>
            note['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note['content'].toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
            onPressed: () => showSearch(
              context: context,
              delegate: NoteSearchDelegate(_notes, (query) => setState(() => _searchQuery = query)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.note_add, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text('No notes yet', style: TextStyle(color: Colors.white38)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addNote,
                        icon: const Icon(Icons.add),
                        label: const Text('Create your first note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return GestureDetector(
                      onTap: () => _viewNote(note),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _noteColors[note['color']],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note['title'],
                                    style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF00BCD4), size: 18),
                                  onPressed: () => _editNote(note),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _deleteNote(note),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note['content'],
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(note['timestamp']),
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class NoteSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> notes;
  final Function(String) onSearch;

  NoteSearchDelegate(this.notes, this.onSearch);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear, color: Color(0xFF00BCD4)),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, null);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = notes.where((note) =>
      note['title'].toLowerCase().contains(query.toLowerCase()) ||
      note['content'].toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          leading: const Icon(Icons.note, color: Color(0xFF00BCD4)),
          title: Text(note['title'], style: const TextStyle(color: Colors.white)),
          subtitle: Text(note['content'], style: const TextStyle(color: Colors.white54), maxLines: 1),
          onTap: () {
            query = note['title'];
            onSearch(query);
            close(context, null);
          },
        );
      },
    );
  }
}

// Helper function
String jsonEncode(List<Map<String, dynamic>> data) {
  return data.toString();
}

List<Map<String, dynamic>> jsonDecode(String data) {
  return [];
}
