import 'dart:io';

import 'package:flutter/material.dart';

import '../../../features/terminal/termux_runtime_service.dart';

class PackageManager extends StatefulWidget {
  const PackageManager({super.key});

  @override
  State<PackageManager> createState() => _PackageManagerState();
}

class _PackageManagerState extends State<PackageManager> {
  static const _prefix = TermuxRuntimeService.prefix;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _packages = <Map<String, String>>[];
  RuntimeStatus _status = RuntimeStatus.notConfigured;
  String _statusDetail = 'Checking the real Zion package runtime…';
  String _manager = 'dpkg';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    if (mounted) setState(() => _isLoading = true);

    final capabilities = await const TermuxRuntimeService().probeCore();
    final dpkg = capabilities['dpkg'];
    final apt = capabilities['apt'];
    final pkg = capabilities['pkg'];
    final selected = dpkg?.status == RuntimeStatus.available
        ? dpkg
        : (apt?.status == RuntimeStatus.available ? apt : pkg);

    if (selected == null || selected.status != RuntimeStatus.available) {
      if (!mounted) return;
      setState(() {
        _packages = <Map<String, String>>[];
        _manager = dpkg?.status == RuntimeStatus.available ? 'dpkg' : 'apt/pkg';
        _status = selected?.status ?? RuntimeStatus.notConfigured;
        _statusDetail = selected?.detail ??
            'No real package manager is installed under ${_prefix}/bin.';
        _isLoading = false;
      });
      return;
    }

    _manager = selected.id;
    _status = RuntimeStatus.available;
    try {
      final executable = '${_prefix}/bin/${selected.id}';
      final args = selected.id == 'dpkg'
          ? const <String>['-l']
          : const <String>['list', '--installed'];
      final result = await Process.run(executable, args, runInShell: false);
      if (result.exitCode != 0) {
        throw ProcessException(
          executable,
          args,
          result.stderr.toString(),
          result.exitCode,
        );
      }
      final lines = result.stdout.toString().split('\n');
      _packages = lines
          .where((line) => line.trimLeft().startsWith('ii '))
          .map((line) {
            final parts = line.trim().split(RegExp(r'\s+'));
            return <String, String>{
              'name': parts.length > 1 ? parts[1] : 'unknown',
              'version': parts.length > 2 ? parts[2] : 'unknown',
              'description':
                  parts.length > 3 ? parts.sublist(3).join(' ') : '',
            };
          })
          .toList();
      _statusDetail =
          'REAL $_manager runtime • ${_packages.length} installed packages.';
    } catch (error) {
      _packages = <Map<String, String>>[];
      _statusDetail = 'REAL $_manager is present but package listing failed: $error';
      _status = RuntimeStatus.available;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, String>> get _filteredPackages {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _packages;
    return _packages
        .where((p) => (p['name'] ?? '').toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final available = _status == RuntimeStatus.available;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Package Manager'),
        backgroundColor: Colors.indigo.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPackages,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: available ? Colors.green.shade900 : Colors.orange.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  available ? Icons.check_circle : Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusDetail,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              enabled: available,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: available
                    ? 'Search installed packages…'
                    : 'Package manager not configured',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPackages.isEmpty
                    ? Center(
                        child: Text(
                          available
                              ? 'No installed packages reported by $_manager.'
                              : 'UNAVAILABLE: install the real Zion userland before using pkg/apt/dpkg.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPackages.length,
                        itemBuilder: (ctx, i) {
                          final package = _filteredPackages[i];
                          return Card(
                            color: Colors.grey.shade900,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.archive,
                                color: Colors.indigo,
                              ),
                              title: Text(
                                package['name'] ?? 'unknown',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${package['version'] ?? 'unknown'}\n'
                                '${package['description'] ?? ''}',
                                style: const TextStyle(color: Colors.grey),
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
