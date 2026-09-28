import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/admin_service.dart';

class AdminCenter extends StatefulWidget {
  const AdminCenter({super.key});

  @override
  State<AdminCenter> createState() => _AdminCenterState();
}

class _AdminCenterState extends State<AdminCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController();
  String _selectedRole = 'Operator';
  String _selectedPermissions = 'limited';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addUser(AdminService service) {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    service.addUser(_usernameController.text, _selectedRole, _selectedPermissions, true);
    _usernameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User added successfully'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminService>(
      builder: (context, service, child) {
        final stats = service.getSystemStats();
        final users = service.getUsers();
        final permissions = service.getPermissions();
        final logs = service.getSystemLogs(limit: 50);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Administration Center', style: TextStyle(color: Color(0xFF00BCD4))),
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
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.security), text: 'Permissions'),
                Tab(icon: Icon(Icons.history), text: 'Logs'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(stats, service),
              _buildUsersTab(service, users),
              _buildPermissionsTab(permissions),
              _buildLogsTab(logs, service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab(Map<String, dynamic> stats, AdminService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Total Users', '${stats['total_users']}', Icons.people, const Color(0xFF00BCD4)),
              _buildStatCard('Active Users', '${stats['active_users']}', Icons.check_circle, Colors.green),
              _buildStatCard('System Logs', '${stats['total_logs']}', Icons.history, Colors.orange),
              _buildStatCard('Maintenance', stats['maintenance_mode'] ? 'ON' : 'OFF', Icons.build, stats['maintenance_mode'] ? Colors.red : Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Controls', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Maintenance Mode', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Restrict non-admin access', style: TextStyle(color: Colors.white54)),
                  value: service.maintenanceMode,
                  onChanged: (v) => service.setMaintenanceMode(v),
                  activeColor: const Color(0xFF00BCD4),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => service.clearSystemLogs(),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(AdminService service, List<Map<String, dynamic>> users) {
    return Column(
      children: [
        // Add User Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const Text('Add New User', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Color(0xFF00BCD4)),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
                  DropdownMenuItem(value: 'Operator', child: Text('Operator')),
                  DropdownMenuItem(value: 'Viewer', child: Text('Viewer')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPermissions,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Color(0xFF00BCD4)),
                decoration: const InputDecoration(
                  labelText: 'Permissions',
                  labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black,
                ),
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('Full Access')),
                  DropdownMenuItem(value: 'limited', child: Text('Limited Access')),
                  DropdownMenuItem(value: 'readonly', child: Text('Read Only')),
                ],
                onChanged: (v) => setState(() => _selectedPermissions = v!),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addUser(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Add User'),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Users List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user['active'] ? const Color(0xFF00BCD4).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                  ),
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
                        user['role'] == 'Administrator' ? Icons.admin_panel_settings : Icons.person,
                        color: const Color(0xFF00BCD4),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('${user['role']} • ${user['permissions']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch(
                      value: user['active'],
                      onChanged: (_) => service.updateUser(user['id'], !user['active']),
                      activeColor: const Color(0xFF00BCD4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => service.deleteUser(user['id']),
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

  Widget _buildPermissionsTab(List<Map<String, dynamic>> permissions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final perm = permissions[index];
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
                child: Center(
                  child: Text('${perm['level']}', style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perm['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(perm['description'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab(List<Map<String, dynamic>> logs, AdminService service) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No logs available', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['action'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(log['details'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('User: ${log['user']} • ${_formatDate(log['timestamp'])}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), Colors.black]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
