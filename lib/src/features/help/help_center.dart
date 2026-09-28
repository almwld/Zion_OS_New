import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenter extends StatefulWidget {
  const HelpCenter({super.key});

  @override
  State<HelpCenter> createState() => _HelpCenterState();
}

class _HelpCenterState extends State<HelpCenter> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _faqs = [
    {'question': 'كيف أبدأ باستخدام Zion OS؟', 'answer': 'يمكنك البدء من خلال شاشة القفل باستخدام PIN 1234، ثم استكشاف التطبيقات المتاحة.'},
    {'question': 'هل يحتاج التطبيق إلى صلاحيات خاصة؟', 'answer': 'نعم، يحتاج التطبيق إلى صلاحيات التخزين والكاميرا والميكروفون للعمل بشكل كامل.'},
    {'question': 'كيف أستخدم أدوات الاختراق؟', 'answer': 'توجد جميع الأدوات في سطح المكتب مصنفة حسب الفئة (هجوم، دفاع، تحليل، أدوات).'},
    {'question': 'ما هو PIN الافتراضي؟', 'answer': 'الرقم السري الافتراضي هو 1234.'},
    {'question': 'كيف أتواصل مع الدعم؟', 'answer': 'يمكنك التواصل عبر البريد الإلكتروني: support@zion-os.com'},
  ];

  final List<Map<String, dynamic>> _tutorials = [
    {'title': 'فحص شبكة', 'steps': '1. افتح Network Scanner\n2. أدخل نطاق IP\n3. اضغط فحص الشبكة'},
    {'title': 'كسر كلمة مرور', 'steps': '1. افتح Password Cracker\n2. أدخل الهاش المستهدف\n3. اختر نوع الهجوم\n4. اضغط كسر'},
    {'title': 'وضع التخفي', 'steps': '1. افتح Stealth Mode\n2. فعّل وضع التخفي\n3. اختر خيارات الإخفاء'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) => 
      faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مركز المساعدة', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ابحث في المساعدة...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF41)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00FF41)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.5)),
                ),
              ),
            ),
          ),
          // روابط سريعة
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickLink(Icons.email, 'البريد', () async {
                  final Uri email = Uri(scheme: 'mailto', path: 'support@zion-os.com');
                  if (await canLaunchUrl(email)) launchUrl(email);
                }),
                _buildQuickLink(Icons.telegram, 'تيليجرام', () {}),
                _buildQuickLink(Icons.discord, 'ديسكورد', () {}),
                _buildQuickLink(Icons.web, 'الموقع', () async {
                  final Uri url = Uri.parse('https://zion-os.com');
                  if (await canLaunchUrl(url)) launchUrl(url);
                }),
                _buildQuickLink(Icons.video_library, 'دروس فيديو', () {}),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // دليل سريع
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF41).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.quickreply, color: Color(0xFF00FF41), size: 20),
                    SizedBox(width: 8),
                    Text('دليل سريع', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ..._tutorials.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(t['title'], style: const TextStyle(color: Colors.white)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(t['steps'], style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // الأسئلة الشائعة
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = filteredFaqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionTile(
                    title: Text(faq['question'], style: const TextStyle(color: Color(0xFF00FF41))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(faq['answer'], style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: Icon(icon, color: const Color(0xFF00FF41), size: 24),
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
