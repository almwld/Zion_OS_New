import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class HelpService {
  static final HelpService _instance = HelpService._internal();
  factory HelpService() => _instance;
  HelpService._internal();
  
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How to change the PIN?',
      'answer': 'Go to Settings → Security → Change PIN, then enter your current PIN and new PIN.',
      'category': 'Security',
      'icon': 'lock',
    },
    {
      'question': 'How to scan a network?',
      'answer': 'Open Network Scanner app, enter the target IP range, and tap "Start Scan".',
      'category': 'Network',
      'icon': 'network_wifi',
    },
    {
      'question': 'What is Stealth Mode?',
      'answer': 'Stealth Mode hides your activity and protects your privacy while using the system.',
      'category': 'Privacy',
      'icon': 'visibility_off',
    },
    {
      'question': 'How to update the system?',
      'answer': 'Go to Update Center and click "Check for Updates" to see available updates.',
      'category': 'System',
      'icon': 'update',
    },
    {
      'question': 'Is my data encrypted?',
      'answer': 'Yes, all sensitive data is encrypted using AES-256 military-grade encryption.',
      'category': 'Security',
      'icon': 'encryption',
    },
    {
      'question': 'How to report a bug?',
      'answer': 'Use the feedback form in Help Center or email us directly at support@zion-os.com',
      'category': 'Support',
      'icon': 'bug_report',
    },
    {
      'question': 'Can I use Zion OS without root?',
      'answer': 'Yes, Zion OS works perfectly without root access on Android devices.',
      'category': 'System',
      'icon': 'check_circle',
    },
    {
      'question': 'How to backup my data?',
      'answer': 'Go to Backup & Restore center and click "Create Backup" to save your data.',
      'category': 'System',
      'icon': 'backup',
    },
  ];
  
  final List<Map<String, dynamic>> _tutorials = [
    {
      'title': 'Getting Started',
      'duration': '5 min',
      'steps': [
        'Install Zion OS on your device',
        'Enter PIN: 1234 to unlock',
        'Explore the desktop interface',
        'Open apps from the grid',
        'Customize theme from Settings',
      ],
    },
    {
      'title': 'Network Scanning',
      'duration': '10 min',
      'steps': [
        'Open Network Scanner app',
        'Enter subnet (e.g., 192.168.1)',
        'Tap "Scan Network" to find devices',
        'Tap "Scan Ports" to check open ports',
        'Analyze results and take action',
      ],
    },
    {
      'title': 'Security Features',
      'duration': '8 min',
      'steps': [
        'Enable Stealth Mode from apps',
        'Set up biometric authentication',
        'Enable data encryption',
        'Use incognito mode for privacy',
        'Regularly backup your data',
      ],
    },
    {
      'title': 'Password Recovery',
      'duration': '15 min',
      'steps': [
        'Open Password Cracker app',
        'Enter the target hash',
        'Select attack type (Dictionary/Brute)',
        'Use custom wordlist if needed',
        'Wait for results',
      ],
    },
  ];
  
  Future<void> sendFeedback(String name, String email, String subject, String message) async {
    // In production, this would send to a server
    print('Feedback sent: $name - $email - $subject - $message');
  }
  
  Future<void> sendEmail(String to, String subject, String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
  
  Future<void> openWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> openTelegram() async {
    final Uri uri = Uri.parse('https://t.me/zionos');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> openGitHub() async {
    final Uri uri = Uri.parse('https://github.com/almwld/project-zion');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  List<Map<String, dynamic>> searchFaqs(String query) {
    if (query.isEmpty) return _faqs;
    return _faqs.where((faq) =>
      faq['question'].toLowerCase().contains(query.toLowerCase()) ||
      faq['answer'].toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  List<Map<String, dynamic>> getFaqsByCategory(String category) {
    if (category == 'All') return _faqs;
    return _faqs.where((faq) => faq['category'] == category).toList();
  }
  
  List<Map<String, dynamic>> getTutorials() => _tutorials;
  
  List<String> getCategories() {
    final categories = _faqs.map((faq) => faq['category'] as String).toSet().toList();
    return ['All', ...categories];
  }
}
