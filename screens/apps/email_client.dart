import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailClient extends StatefulWidget {
  const EmailClient({super.key});

  @override
  State<EmailClient> createState() => _EmailClientState();
}

class _EmailClientState extends State<EmailClient> {
  int _selectedTab = 0;
  final TextEditingController _composeToController = TextEditingController();
  final TextEditingController _composeSubjectController = TextEditingController();
  final TextEditingController _composeBodyController = TextEditingController();
  
  final List<Map<String, dynamic>> _emails = [
    {
      'id': '1',
      'from': 'Ahmed Hassan',
      'fromEmail': 'ahmed@example.com',
      'subject': 'Project Update',
      'body': 'The project is progressing well. We need to review the security features.',
      'time': '10:30 AM',
      'date': '2024-12-01',
      'read': false,
      'starred': true,
      'hasAttachment': true,
    },
    {
      'id': '2',
      'from': 'Mohamed Ali',
      'fromEmail': 'mohamed@example.com',
      'subject': 'Meeting Tomorrow',
      'body': 'Reminder: Team meeting at 10 AM tomorrow in Conference Room A.',
      'time': 'Yesterday',
      'date': '2024-11-30',
      'read': true,
      'starred': false,
      'hasAttachment': false,
    },
    {
      'id': '3',
      'from': 'Sara Kamel',
      'fromEmail': 'sara@example.com',
      'subject': 'New Document',
      'body': 'Please find attached the updated documentation for the project.',
      'time': 'Yesterday',
      'date': '2024-11-30',
      'read': false,
      'starred': true,
      'hasAttachment': true,
    },
    {
      'id': '4',
      'from': 'Support Team',
      'fromEmail': 'support@zion-os.com',
      'subject': 'Your Account Status',
      'body': 'Your account is active and secure. Thank you for using Zion OS.',
      'time': 'Dec 28',
      'date': '2024-11-28',
      'read': true,
      'starred': false,
      'hasAttachment': false,
    },
  ];
  
  final List<Map<String, dynamic>> _accounts = [
    {'email': 'user@zion-os.com', 'name': 'Zion User', 'active': true},
    {'email': 'work@company.com', 'name': 'Work Account', 'active': false},
  ];

  int get _unreadCount => _emails.where((e) => !e['read']).length;

  void _markAsRead(String id) {
    setState(() {
      final index = _emails.indexWhere((e) => e['id'] == id);
      if (index != -1) _emails[index]['read'] = true;
    });
  }

  void _toggleStarred(String id) {
    setState(() {
      final index = _emails.indexWhere((e) => e['id'] == id);
      if (index != -1) _emails[index]['starred'] = !_emails[index]['starred'];
    });
  }

  void _deleteEmail(String id) {
    setState(() {
      _emails.removeWhere((e) => e['id'] == id);
    });
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _composeToController.text,
      query: 'subject=${Uri.encodeComponent(_composeSubjectController.text)}&body=${Uri.encodeComponent(_composeBodyController.text)}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      _composeToController.clear();
      _composeSubjectController.clear();
      _composeBodyController.clear();
      Navigator.pop(context);
    }
  }

  void _viewEmail(Map<String, dynamic> email) {
    _markAsRead(email['id']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email['from'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(email['fromEmail'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    email['starred'] ? Icons.star : Icons.star_border,
                    color: email['starred'] ? Colors.amber : const Color(0xFF00BCD4),
                  ),
                  onPressed: () => _toggleStarred(email['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteEmail(email['id']);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(email['subject'], style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Divider(color: Color(0xFF00BCD4), height: 20),
            Text(email['body'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (email['hasAttachment']) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attachment, color: Color(0xFF00BCD4), size: 16),
                    SizedBox(width: 8),
                    Text('1 attachment', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _composeToController.text = email['fromEmail'];
                      _composeSubjectController.text = 'Re: ${email['subject']}';
                      _composeBodyController.text = '\n\n\n----- Original Message -----\nFrom: ${email['from']}\nSubject: ${email['subject']}\n\n${email['body']}';
                      Navigator.pop(context);
                      _composeEmail();
                    },
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _composeEmail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Message', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _composeToController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'To',
                  labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _composeSubjectController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _composeBodyController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Discard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmails = _selectedTab == 0
        ? _emails
        : _selectedTab == 1
            ? _emails.where((e) => e['starred']).toList()
            : _emails.where((e) => !e['read']).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Email', style: TextStyle(color: Color(0xFF00BCD4))),
            if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
            onPressed: _composeEmail,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF00BCD4)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'accounts', child: Text('Accounts')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
            Tab(icon: Icon(Icons.star), text: 'Starred'),
            Tab(icon: Icon(Icons.mark_email_unread), text: 'Unread'),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEmails.length,
        itemBuilder: (context, index) {
          final email = filteredEmails[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: email['read'] ? Colors.white.withOpacity(0.03) : const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: email['read'] ? Colors.white.withOpacity(0.05) : const Color(0xFF00BCD4).withOpacity(0.3),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                child: Text(
                  email['from'][0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF00BCD4)),
                ),
              ),
              title: Text(
                email['subject'],
                style: TextStyle(
                  color: email['read'] ? Colors.white70 : Colors.white,
                  fontWeight: email['read'] ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email['from'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(email['body'], style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      email['starred'] ? Icons.star : Icons.star_border,
                      color: email['starred'] ? Colors.amber : const Color(0xFF00BCD4),
                      size: 18,
                    ),
                    onPressed: () => _toggleStarred(email['id']),
                  ),
                  Text(email['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              onTap: () => _viewEmail(email),
            ),
          );
        },
      ),
    );
  }
}
