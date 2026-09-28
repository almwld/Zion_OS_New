import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapsApp extends StatefulWidget {
  const MapsApp({super.key});

  @override
  State<MapsApp> createState() => _MapsAppState();
}

class _MapsAppState extends State<MapsApp> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Cairo, Egypt';
  List<Map<String, String>> _savedLocations = [];
  List<Map<String, String>> _searchResults = [];
  bool _showSaved = true;
  
  // Simulated locations
  final List<Map<String, String>> _locations = [
    {'name': 'Cairo, Egypt', 'lat': '30.0444', 'lng': '31.2357', 'type': 'city'},
    {'name': 'Alexandria, Egypt', 'lat': '31.2001', 'lng': '29.9187', 'type': 'city'},
    {'name': 'Giza, Egypt', 'lat': '29.9870', 'lng': '31.2118', 'type': 'city'},
    {'name': 'Luxor, Egypt', 'lat': '25.6872', 'lng': '32.6396', 'type': 'city'},
    {'name': 'Aswan, Egypt', 'lat': '24.0889', 'lng': '32.8998', 'type': 'city'},
    {'name': 'Sharm El Sheikh', 'lat': '27.9158', 'lng': '34.3300', 'type': 'city'},
    {'name': 'Hurghada', 'lat': '27.2579', 'lng': '33.8126', 'type': 'city'},
    {'name': 'Pyramids of Giza', 'lat': '29.9792', 'lng': '31.1342', 'type': 'landmark'},
    {'name': 'Egyptian Museum', 'lat': '30.0479', 'lng': '31.2332', 'type': 'landmark'},
    {'name': 'Khan El Khalili', 'lat': '30.0477', 'lng': '31.2621', 'type': 'market'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  void _loadSavedLocations() {
    _savedLocations = [
      {'name': 'Cairo, Egypt', 'lat': '30.0444', 'lng': '31.2357'},
      {'name': 'Alexandria, Egypt', 'lat': '31.2001', 'lng': '29.9187'},
    ];
  }

  void _searchLocation() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSaved = true;
      });
      return;
    }
    
    setState(() {
      _searchResults = _locations
          .where((loc) => loc['name']!.toLowerCase().contains(query))
          .map((loc) => {'name': loc['name']!, 'lat': loc['lat']!, 'lng': loc['lng']!})
          .toList();
      _showSaved = false;
    });
  }

  void _selectLocation(String name, String lat, String lng) {
    setState(() {
      _selectedLocation = name;
      _searchController.text = '';
      _searchResults = [];
      _showSaved = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 $name selected'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }

  void _saveLocation(String name, String lat, String lng) {
    if (!_savedLocations.any((loc) => loc['name'] == name)) {
      setState(() {
        _savedLocations.add({'name': name, 'lat': lat, 'lng': lng});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location saved'),
          backgroundColor: Color(0xFF00BCD4),
        ),
      );
    }
  }

  void _removeSavedLocation(int index) {
    setState(() {
      _savedLocations.removeAt(index);
    });
  }

  void _openInBrowser(String lat, String lng) {
    // Open in Google Maps (would use url_launcher in production)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in Google Maps...'),
        backgroundColor: Color(0xFF00BCD4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Maps', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map Preview
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF006064)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openInBrowser('0', '0'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00BCD4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _searchLocation(),
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF00BCD4)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Getting your location...'),
                        backgroundColor: Color(0xFF00BCD4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Content (Search Results or Saved Locations)
          Expanded(
            child: _showSaved
                ? _buildSavedLocationsTab()
                : _buildSearchResultsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedLocationsTab() {
    return Column(
      children: [
        // Popular Places Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Places',
                style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchResults = _locations
                        .where((loc) => loc['type'] == 'landmark')
                        .map((loc) => {'name': loc['name']!, 'lat': loc['lat']!, 'lng': loc['lng']!})
                        .toList();
                    _showSaved = false;
                  });
                },
                child: const Text('See All', style: TextStyle(color: Color(0xFF00BCD4))),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _locations.where((loc) => loc['type'] == 'landmark').take(5).length,
            itemBuilder: (context, index) {
              final places = _locations.where((loc) => loc['type'] == 'landmark').take(5).toList();
              final place = places[index];
              return _buildPlaceCard(place['name']!, place['lat']!, place['lng']!);
            },
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Saved Locations
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFF00BCD4), size: 18),
              const SizedBox(width: 8),
              const Text('Saved Locations', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_savedLocations.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _savedLocations.clear());
                  },
                  child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _savedLocations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.white24),
                      SizedBox(height: 8),
                      Text('No saved locations', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _savedLocations[index];
                    return _buildLocationTile(loc['name']!, loc['lat']!, loc['lng']!, index, true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsTab() {
    return _searchResults.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.white24),
                SizedBox(height: 8),
                Text('No results found', style: TextStyle(color: Colors.white38)),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final loc = _searchResults[index];
              return _buildLocationTile(loc['name']!, loc['lat']!, loc['lng']!, index, false);
            },
          );
  }

  Widget _buildPlaceCard(String name, String lat, String lng) {
    return GestureDetector(
      onTap: () => _selectLocation(name, lat, lng),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place, color: Color(0xFF00BCD4), size: 28),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(String name, String lat, String lng, int index, bool isSaved) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF00BCD4), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lat: $lat, Lng: $lng',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.delete_outline : Icons.bookmark_border,
              color: isSaved ? Colors.red : const Color(0xFF00BCD4),
              size: 20,
            ),
            onPressed: () {
              if (isSaved) {
                _removeSavedLocation(index);
              } else {
                _saveLocation(name, lat, lng);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Color(0xFF00BCD4), size: 20),
            onPressed: () => _selectLocation(name, lat, lng),
          ),
        ],
      ),
    );
  }
}
