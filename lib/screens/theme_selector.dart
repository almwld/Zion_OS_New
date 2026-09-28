import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_manager.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Theme Selector', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildThemeCard(
            'Turquoise',
            const Color(0xFF00BCD4),
            AppTheme.turquoise,
            themeManager,
          ),
          _buildThemeCard(
            'Cyber Green',
            const Color(0xFF00FF41),
            AppTheme.cyberGreen,
            themeManager,
          ),
          _buildThemeCard(
            'Neon Blue',
            const Color(0xFF2196F3),
            AppTheme.neonBlue,
            themeManager,
          ),
          _buildThemeCard(
            'Dark Purple',
            const Color(0xFF9C27B0),
            AppTheme.darkPurple,
            themeManager,
          ),
          _buildThemeCard(
            'Sunset',
            const Color(0xFFFF5722),
            AppTheme.sunset,
            themeManager,
          ),
          _buildThemeCard(
            'Matrix',
            const Color(0xFF33FF33),
            AppTheme.matrix,
            themeManager,
          ),
          _buildThemeCard(
            'Holographic',
            const Color(0xFFE040FB),
            AppTheme.holographic,
            themeManager,
          ),
          _buildThemeCard(
            'Midnight',
            const Color(0xFF3F51B5),
            AppTheme.midnight,
            themeManager,
          ),
          _buildThemeCard(
            'Aurora',
            const Color(0xFF4CAF50),
            AppTheme.aurora,
            themeManager,
          ),
          _buildThemeCard(
            'Ember',
            const Color(0xFFFF6B00),
            AppTheme.ember,
            themeManager,
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeCard(String name, Color color, AppTheme theme, ThemeManager manager) {
    final isSelected = manager.currentTheme == theme;
    
    return GestureDetector(
      onTap: () => manager.setTheme(theme),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), Colors.black],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.palette,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 8)),
              ),
          ],
        ),
      ),
    );
  }
}
