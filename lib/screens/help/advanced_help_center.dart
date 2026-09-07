import 'package:flutter/material.dart';
import '../../core/services/help_service.dart';

class AdvancedHelpCenter extends StatefulWidget {
  const AdvancedHelpCenter({super.key});

  @override
  State<AdvancedHelpCenter> createState() => _AdvancedHelpCenterState();
}

class _AdvancedHelpCenterState extends State<AdvancedHelpCenter>
    with SingleTickerProviderStateMixin {
  late final HelpService _helpService;
  late final TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _helpService = HelpService();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await _helpService.sendFeedback(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _subjectController.text.trim(),
        _messageController.text.trim(),
      );
      if (!mounted) return;
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _helpService.getCategories();
    final faqs = _searchQuery.isEmpty
        ? _helpService.getFaqsByCategory(_selectedCategory)
        : _helpService.searchFaqs(_searchQuery);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.help_outline), text: 'FAQs'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Tutorials'),
            Tab(icon: Icon(Icons.feedback_outlined), text: 'Contact'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqs(faqs, categories),
          _buildTutorials(),
          _buildContact(),
        ],
      ),
    );
  }

  Widget _buildFaqs(
    List<Map<String, dynamic>> faqs,
    List<String> categories,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search FAQs...',
              filled: true,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: categories
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(),
        Expanded(
          child: faqs.isEmpty
              ? const Center(child: Text('No FAQs found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return Card(
                      color: Colors.white.withOpacity(.06),
                      child: ExpansionTile(
                        leading: Icon(_getIcon(faq['icon'] as String?)),
                        title: Text(faq['question'] as String),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(faq['answer'] as String),
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

  Widget _buildTutorials() {
    final tutorials = _helpService.getTutorials();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        final steps = (tutorial['steps'] as List).cast<String>();
        return Card(
          color: Colors.white.withOpacity(.06),
          child: ExpansionTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(tutorial['title'] as String),
            subtitle: Text(tutorial['duration'] as String),
            children: [
              for (final step in steps)
                ListTile(
                  leading: const Icon(Icons.chevron_right),
                  title: Text(step),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContact() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _contactCard('Email', Icons.email_outlined, () =>
                _helpService.sendEmail('support@zion-os.com', 'Support Request', '')),
            _contactCard('Website', Icons.language, () =>
                _helpService.openWebsite('https://zion-os.com')),
            _contactCard('GitHub', Icons.code, _helpService.openGitHub),
            _contactCard('Telegram', Icons.send, _helpService.openTelegram),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Send Feedback', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name *')),
        const SizedBox(height: 10),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email *')),
        const SizedBox(height: 10),
        TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject')),
        const SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Message *'),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _isSending ? null : _sendFeedback,
          child: _isSending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Feedback'),
        ),
      ],
    );
  }

  Widget _contactCard(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 160,
      child: Card(
        color: Colors.white.withOpacity(.06),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 8),
                Text(title),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'lock': return Icons.lock_outline;
      case 'network_wifi': return Icons.wifi;
      case 'visibility_off': return Icons.visibility_off;
      case 'update': return Icons.system_update;
      case 'encryption': return Icons.encryption_outlined;
      case 'bug_report': return Icons.bug_report_outlined;
      case 'check_circle': return Icons.check_circle_outline;
      case 'backup': return Icons.backup_outlined;
      default: return Icons.help_outline;
    }
  }
}
