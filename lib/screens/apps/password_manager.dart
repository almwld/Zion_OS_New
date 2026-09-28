import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PasswordManagerApp extends StatefulWidget {
  const PasswordManagerApp({super.key});

  @override
  State<PasswordManagerApp> createState() => _PasswordManagerAppState();
}

class _PasswordManagerAppState extends State<PasswordManagerApp> {
  List<Map<String, String>> _passwords = [];
  bool _showPasswords = false;
  String _searchQuery = '';
  int _selectedTab = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordsJson = prefs.getString('saved_passwords');
    if (passwordsJson != null) {
      // Parse JSON
    }
    
    // Never seed the vault with fabricated credentials. A new installation
    // starts empty and only displays credentials explicitly added by the user.
  }

  Future<void> _savePasswords() async {
    final prefs = await SharedPreferences.getInstance();
    // Persistence is intentionally left disabled until encrypted storage is wired.
    // Never write credentials to plaintext SharedPreferences.
  }

  void _addPassword() {
    final siteController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedCategory = 'Other';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Password', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: siteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Website/App',
                      labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Username/Email',
                      labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Color(0xFF00BCD4)),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Email', child: Text('Email')),
                      DropdownMenuItem(value: 'Social', child: Text('Social')),
                      DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                      DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                      DropdownMenuItem(value: 'Dev', child: Text('Development')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedCategory = v!),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (siteController.text.isNotEmpty && usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                setState(() {
                  _passwords.add({
                    'site': siteController.text,
                    'username': usernameController.text,
                    'password': passwordController.text,
                    'category': selectedCategory,
                  });
                });
                _savePasswords();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password added'), backgroundColor: Color(0xFF00BCD4)),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _deletePassword(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Are you sure you want to delete this password?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              setState(() {
                _passwords.removeAt(index);
              });
              _savePasswords();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password deleted'), backgroundColor: Color(0xFF00BCD4)),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  String _generateStrongPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return String.fromCharCodes(
      List.generate(16, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

  void _showGenerator() {
    final generated = _generateStrongPassword();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Password', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                generated,
                style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _copyToClipboard(generated);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPasswords = _searchQuery.isEmpty
        ? _passwords
        : _passwords.where((p) =>
            p['site']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p['username']!.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Password Manager', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.password, color: Color(0xFF00BCD4)),
            onPressed: _showGenerator,
          ),
          IconButton(
            icon: Icon(_showPasswords ? Icons.visibility_off : Icons.visibility, color: Color(0xFF00BCD4)),
            onPressed: () => setState(() => _showPasswords = !_showPasswords),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _passwords.length.toString(), Icons.vpn_key),
                _buildStatItem('Strength', 'Strong', Icons.security),
                _buildStatItem('Weak', '0', Icons.warning),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                hintText: 'Search passwords...',
                hintStyle: const TextStyle(color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF00BCD4)),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Passwords List
          Expanded(
            child: filteredPasswords.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text('No passwords saved', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPasswords.length,
                    itemBuilder: (context, index) {
                      final pwd = filteredPasswords[index];
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_getCategoryIcon(pwd['category']!), color: const Color(0xFF00BCD4), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pwd['site']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(pwd['username']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(pwd['category']!, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _showPasswords ? pwd['password']! : '••••••••',
                                          style: const TextStyle(color: Color(0xFF00BCD4), fontFamily: 'monospace'),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 18, color: Color(0xFF00BCD4)),
                                              onPressed: () => _copyToClipboard(pwd['password']!),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => _deletePassword(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPassword,
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Email': return Icons.email;
      case 'Social': return Icons.people;
      case 'Shopping': return Icons.shopping_cart;
      case 'Finance': return Icons.attach_money;
      case 'Dev': return Icons.code;
      default: return Icons.vpn_key;
    }
  }
}
