import 'package:flutter/material.dart';
import '../../core/services/app_store_service.dart';

class AppStoreCenter extends StatefulWidget {
  const AppStoreCenter({super.key});

  @override
  State<AppStoreCenter> createState() => _AppStoreCenterState();
}

class _AppStoreCenterState extends State<AppStoreCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppStoreService _storeService;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Security', 'Tools', 'Privacy', 'Games', 'Productivity'];

  @override
  void initState() {
    super.initState();
    _storeService = AppStoreService();
    _storeService.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final installedApps = _storeService.getInstalledApps();
    final availableApps = _storeService.getAvailableApps();
    
    List<Map<String, dynamic>> filteredApps = _tabController.index == 0 ? installedApps : availableApps;
    
    if (_searchQuery.isNotEmpty) {
      filteredApps = filteredApps.where((app) =>
        app['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        app['description'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedCategory != 'All') {
      filteredApps = filteredApps.where((app) => app['category'] == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('App Store', style: TextStyle(color: Color(0xFF00BCD4))),
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
            Tab(icon: Icon(Icons.apps), text: 'Installed'),
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
                    hintText: 'Search apps...',
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
          
          // App List
          Expanded(
            child: filteredApps.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apps, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No apps found', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      return _buildAppCard(app);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppCard(Map<String, dynamic> app) {
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
          // App Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(_getIconData(app['icon']), color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          
          // App Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  app['description'],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        app['category'],
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${app['rating']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.download, color: Color(0xFF00BCD4), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      app['downloads'],
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          ElevatedButton(
            onPressed: () async {
              if (app['installed']) {
                await _storeService.uninstallApp(app['id']);
              } else {
                await _storeService.installApp(app['id']);
              }
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: app['installed'] ? Colors.red : const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(app['installed'] ? 'Uninstall' : 'Install'),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'terminal': return Icons.terminal;
      case 'network_wifi': return Icons.network_wifi;
      case 'wifi': return Icons.wifi;
      case 'lock': return Icons.lock;
      case 'vpn_key': return Icons.vpn_key;
      case 'speed': return Icons.speed;
      case 'search': return Icons.search;
      case 'storage': return Icons.storage;
      case 'cloud': return Icons.cloud;
      case 'visibility_off': return Icons.visibility_off;
      default: return Icons.apps;
    }
  }
}
