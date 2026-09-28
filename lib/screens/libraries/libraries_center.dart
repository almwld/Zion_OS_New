import 'package:flutter/material.dart';
import '../../core/services/libraries_service.dart';

class LibrariesCenter extends StatefulWidget {
  const LibrariesCenter({super.key});

  @override
  State<LibrariesCenter> createState() => _LibrariesCenterState();
}

class _LibrariesCenterState extends State<LibrariesCenter> with SingleTickerProviderStateMixin {
  late LibrariesService _librariesService;
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Network', 'Security', 'Framework', 'Wireless', 'Web'];

  @override
  void initState() {
    super.initState();
    _librariesService = LibrariesService();
    _librariesService.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final installedLibs = _librariesService.getInstalledLibraries();
    final availableLibs = _librariesService.getAvailableLibraries();
    
    List<Map<String, dynamic>> filteredLibs = _tabController.index == 0 ? installedLibs : availableLibs;
    
    if (_searchQuery.isNotEmpty) {
      filteredLibs = filteredLibs.where((lib) =>
        lib['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        lib['description'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedCategory != 'All') {
      filteredLibs = filteredLibs.where((lib) => lib['category'] == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Services & Libraries', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: 'Installed'),
            Tab(icon: Icon(Icons.cloud_download), text: 'Available'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                    hintText: 'Search libraries...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category, style: TextStyle(color: _selectedCategory == category ? Colors.black : const Color(0xFF00BCD4))),
                        selected: _selectedCategory == category,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                        backgroundColor: Colors.transparent,
                        selectedColor: const Color(0xFF00BCD4),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFF00BCD4), height: 1),
          
          // Libraries List
          Expanded(
            child: filteredLibs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No libraries found', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLibs.length,
                    itemBuilder: (context, index) {
                      final lib = filteredLibs[index];
                      return _buildLibraryCard(lib);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLibraryCard(Map<String, dynamic> lib) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getCategoryIcon(lib['category']), color: const Color(0xFF00BCD4), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lib['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(lib['description'], style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(lib['category'], style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.code, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text('Version ${lib['version']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              const Icon(Icons.storage, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(lib['size'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              if (lib['installed'])
                ElevatedButton.icon(
                  onPressed: () async {
                    await _librariesService.uninstallLibrary(lib['id']);
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Uninstall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    await _librariesService.installLibrary(lib['id']);
                    setState(() {});
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Install'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Network': return Icons.network_wifi;
      case 'Security': return Icons.security;
      case 'Framework': return Icons.folder;
      case 'Wireless': return Icons.wifi;
      case 'Web': return Icons.web;
      default: return Icons.folder;
    }
  }
}
