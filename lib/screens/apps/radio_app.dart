import 'package:flutter/material.dart';

class RadioApp extends StatefulWidget {
  const RadioApp({super.key});

  @override
  State<RadioApp> createState() => _RadioAppState();
}

class _RadioAppState extends State<RadioApp> {
  int _selectedStation = 0;
  bool _isPlaying = false;
  double _volume = 0.8;
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'News', 'Music', 'Sports', 'Talk', 'Religious'];
  
  final List<Map<String, dynamic>> _stations = [
    {'name': 'BBC World News', 'frequency': '94.3 FM', 'category': 'News', 'icon': Icons.radio, 'color': 0xFF00BCD4},
    {'name': 'Nile FM', 'frequency': '104.2 FM', 'category': 'Music', 'icon': Icons.music_note, 'color': 0xFF4CAF50},
    {'name': 'Radio Masr', 'frequency': '88.7 FM', 'category': 'Music', 'icon': Icons.audiotrack, 'color': 0xFF2196F3},
    {'name': 'ON Sport', 'frequency': '92.1 FM', 'category': 'Sports', 'icon': Icons.sports_soccer, 'color': 0xFFFF9800},
    {'name': 'Nogoum FM', 'frequency': '100.6 FM', 'category': 'Music', 'icon': Icons.mic, 'color': 0xFF9C27B0},
    {'name': 'Radio Horeya', 'frequency': '90.4 FM', 'category': 'Talk', 'icon': Icons.chat, 'color': 0xFFE91E63},
    {'name': 'Al-Azhar Radio', 'frequency': '98.8 FM', 'category': 'Religious', 'icon': Icons.mosque, 'color': 0xFF00BCD4},
    {'name': 'CNN International', 'frequency': '101.2 FM', 'category': 'News', 'icon': Icons.public, 'color': 0xFFF44336},
    {'name': 'Mega FM', 'frequency': '92.7 FM', 'category': 'Music', 'icon': Icons.headphones, 'color': 0xFF673AB7},
    {'name': 'Radio Sawa', 'frequency': '95.5 FM', 'category': 'Music', 'icon': Icons.library_music, 'color': 0xFF00BCD4},
  ];
  
  final List<Map<String, dynamic>> _recentStations = [
    {'name': 'BBC World News', 'time': '5 min ago'},
    {'name': 'Nile FM', 'time': '30 min ago'},
    {'name': 'Radio Masr', 'time': '1 hour ago'},
  ];
  
  List<Map<String, dynamic>> get _filteredStations {
    if (_selectedCategory == 'All') {
      return _stations;
    }
    return _stations.where((s) => s['category'] == _selectedCategory).toList();
  }

  void _playStation(int index) {
    setState(() {
      _selectedStation = index;
      _isPlaying = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${_stations[index]['name']}'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  void _stopPlaying() {
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stations = _filteredStations;
    final currentStation = _stations[_selectedStation];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Radio', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF00BCD4)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Currently Playing Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00BCD4), const Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.radio, size: 60, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  _isPlaying ? 'NOW PLAYING' : 'SELECT A STATION',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStation['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  currentStation['frequency'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Volume Slider
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white70, size: 20),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        onChanged: (v) => setState(() => _volume = v),
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white70, size: 20),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Play/Pause Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                      onPressed: () {
                        if (_selectedStation > 0) {
                          _playStation(_selectedStation - 1);
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: const Color(0xFF00BCD4),
                          size: 40,
                        ),
                        onPressed: _isPlaying ? _stopPlaying : () => _playStation(_selectedStation),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                      onPressed: () {
                        if (_selectedStation < _stations.length - 1) {
                          _playStation(_selectedStation + 1);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Categories
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == _categories[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = _categories[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFF00BCD4).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF00BCD4),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Recent Stations
          if (_selectedCategory == 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF00BCD4), size: 16),
                  const SizedBox(width: 8),
                  const Text('Recent Stations', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
            ),
          
          if (_selectedCategory == 'All')
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recentStations.length,
                itemBuilder: (context, index) {
                  final station = _recentStations[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF00BCD4), size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(station['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                            Text(station['time'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Stations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final isPlaying = _isPlaying && _stations[_selectedStation]['name'] == station['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPlaying ? const Color(0xFF00BCD4).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaying ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4).withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(station['color']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(station['icon'], color: Color(station['color']), size: 24),
                    ),
                    title: Text(
                      station['name'],
                      style: TextStyle(
                        color: isPlaying ? const Color(0xFF00BCD4) : Colors.white,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      station['frequency'],
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: const Color(0xFF00BCD4),
                      ),
                      onPressed: isPlaying ? _stopPlaying : () => _playStation(_stations.indexOf(station)),
                    ),
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
