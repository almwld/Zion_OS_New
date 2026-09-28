import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperSelector extends StatefulWidget {
  const WallpaperSelector({super.key});

  @override
  State<WallpaperSelector> createState() => _WallpaperSelectorState();
}

class _WallpaperSelectorState extends State<WallpaperSelector> {
  int _selectedWallpaper = 0;
  final List<Map<String, dynamic>> _wallpapers = [
    {'name': 'Default', 'colors': [Color(0xFF0A2E38), Colors.black], 'type': 'gradient'},
    {'name': 'Cyber', 'colors': [Color(0xFF1A0B2E), Color(0xFF0A0A0A)], 'type': 'gradient'},
    {'name': 'Ocean', 'colors': [Color(0xFF0D2E3B), Color(0xFF03090C)], 'type': 'gradient'},
    {'name': 'Sunset', 'colors': [Color(0xFF3B1A0A), Color(0xFF0A0A0A)], 'type': 'gradient'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedWallpaper = prefs.getInt('wallpaper') ?? 0);
  }

  Future<void> _selectWallpaper(int index) async {
    setState(() => _selectedWallpaper = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wallpaper', index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Wallpaper', style: TextStyle(color: Color(0xFF00BCD4))),
      backgroundColor: Colors.black,
      content: SizedBox(
        width: 300,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _wallpapers.length,
          itemBuilder: (context, index) {
            final wp = _wallpapers[index];
            final isSelected = _selectedWallpaper == index;
            return GestureDetector(
              onTap: () => _selectWallpaper(index),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1,
                    colors: wp['colors'],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00BCD4) : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    wp['name'],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF00BCD4))),
        ),
      ],
    );
  }
}
