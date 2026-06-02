import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/screens/call/call_screen.dart';
import 'package:sehatak/presentation/screens/doctor/doctor_booking_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String? doctorId;
  const DoctorDetailsScreen({super.key, this.doctorId});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isFavorite = false;
  bool _isFollowing = false;
  double _userRating = 0;

  Map<String, dynamic> get _doctor {
    switch (widget.doctorId) {
      case '1': return {'name': 'د. علي المولد', 'specialty': 'استشاري باطنية وأطفال', 'experience': '20+ سنة', 'rating': 4.9, 'reviews': 328, 'patients': '15,000+', 'fee': '500', 'available': true, 'hospital': 'مستشفى الثورة العام', 'about': 'استشاري باطنية وأطفال مع خبرة واسعة في تشخيص وعلاج الأمراض الباطنية.', 'education': ['بكالوريوس طب - جامعة صنعاء', 'زمالة الباطنية - المجلس العربي'], 'services': ['استشارة باطنية', 'استشارة أطفال', 'فحص شامل'], 'availability': ['السبت - الأربعاء: 9 ص - 5 م', 'الخميس: 9 ص - 1 م']};
      case '2': return {'name': 'د. حسن رضا', 'specialty': 'طبيب عام', 'experience': '8+ سنة', 'rating': 4.8, 'reviews': 235, 'patients': '8,000+', 'fee': '300', 'available': true, 'hospital': 'عيادة الصحة بلس', 'about': 'طبيب عام متخصص في طب الأسرة.', 'education': ['بكالوريوس طب - جامعة تعز'], 'services': ['استشارة عامة', 'فحص دوري'], 'availability': ['الأحد - الخميس: 8 ص - 4 م']};
      default: return {'name': 'د. أحمد محمد', 'specialty': 'طبيب عام', 'experience': '5+ سنة', 'rating': 4.5, 'reviews': 89, 'patients': '2,000+', 'fee': '200', 'available': true, 'hospital': 'مستشفى عام', 'about': 'طبيب عام مهتم بصحة المجتمع.', 'education': ['بكالوريوس طب - جامعة عدن'], 'services': ['استشارة عامة'], 'availability': ['الأحد - الخميس: 8 ص - 2 م']};
    }
  }

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    final doc = _doctor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(slivers: [
        // ========== HEADER كبير مرتب ==========
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary, AppColors.primaryDark])),
              child: SafeArea(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 30),
                  CircleAvatar(radius: 50, backgroundColor: Colors.white24, child: Text(doc['name'][0] + doc['name'][doc['name'].length - 3], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  Text(doc['name'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(doc['specialty'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  // النجوم منفصلة
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _starRow(doc['rating']),
                    const SizedBox(width: 8),
                    Text('${doc['rating']} (${doc['reviews']} تقييم)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  // السعر والتوفر
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('${doc['fee']} ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: doc['available'] ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Text(doc['available'] ? 'متاح' : 'غير متاح', style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white), onPressed: () => setState(() => _isFavorite = !_isFavorite)),
          ],
        ),

        // ========== أزرار الإجراءات ==========
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: isDark ? const Color(0xFF111D33) : AppColors.surfaceContainerLow,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _actionBtn(Icons.chat, 'محادثة', AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(doctorName: doc['name'])))),
              _actionBtn(Icons.videocam, 'فيديو', AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(channelName: 'call_${doc['name']}', callerName: doc['name'])))),
              _actionBtn(Icons.call, 'صوتي', AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(channelName: 'call_${doc['name']}', callerName: doc['name'], isVideo: false)))),
              _actionBtn(Icons.person_add, _isFollowing ? 'متابَع' : 'متابعة', AppColors.purple, () => setState(() => _isFollowing = !_isFollowing)),
              _actionBtn(Icons.calendar_today, 'حجز', AppColors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorBookingScreen(doctorId: widget.doctorId ?? '1')))),
            ]),
          ),
        ),

        // ========== تبويبات ==========
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(TabBar(
            controller: _tab, indicatorColor: AppColors.primary, indicatorWeight: 3,
            labelColor: AppColors.primary, unselectedLabelColor: AppColors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: 'نبذة'), Tab(text: 'تقييمات'), Tab(text: 'مواعيد')],
          )),
        ),

        SliverFillRemaining(
          child: TabBarView(controller: _tab, children: [
            _aboutTab(doc, isDark),
            _reviewsTab(isDark),
            _appointmentsTab(doc),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _aboutTab(Map<String, dynamic> doc, bool isDark) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('نبذة عن الطبيب'),
      Text(doc['about'], style: const TextStyle(fontSize: 14, height: 1.7)),
      const SizedBox(height: 20),
      _section('المؤهلات العلمية'),
      ...(doc['education'] as List).map((e) => _infoRow(Icons.school, e)),
      const SizedBox(height: 20),
      _section('الخدمات'),
      ...(doc['services'] as List).map((s) => _infoRow(Icons.check_circle, s, color: AppColors.success)),
      const SizedBox(height: 20),
      _section('معلومات'),
      _infoCard('المستشفى', doc['hospital'], Icons.local_hospital),
      _infoCard('المرضى', doc['patients'], Icons.people),
      const SizedBox(height: 20),
      _section('أوقات الدوام'),
      ...(doc['availability'] as List).map((a) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [const Icon(Icons.access_time, size: 16, color: AppColors.grey), const SizedBox(width: 8), Text(a, style: const TextStyle(fontSize: 13))]))),
    ]));
  }

  Widget _reviewsTab(bool isDark) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('التقييمات'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Text('4.9', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _starRow(4.9), const SizedBox(height: 4), const Text('3 تقييمات', style: TextStyle(fontSize: 13, color: AppColors.grey)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      _section('أضف تقييمك'),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(icon: Icon(i < _userRating ? Icons.star : Icons.star_border, color: AppColors.amber, size: 32), onPressed: () => setState(() => _userRating = i + 1.0)))),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('إرسال التقييم'))),
    ]));
  }

  Widget _appointmentsTab(Map<String, dynamic> doc) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('الأوقات المتاحة'),
      Wrap(spacing: 6, runSpacing: 6, children: ['9:00', '9:30', '10:00', '10:30', '11:00', '2:00', '2:30', '3:00', '4:00'].map((t) => ChoiceChip(label: Text(t), selected: false, onSelected: (_) {})).toList()),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorBookingScreen(doctorId: widget.doctorId ?? '1'))), icon: const Icon(Icons.calendar_month), label: const Text('حجز موعد'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
    ]));
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)));
  Widget _infoRow(IconData icon, String text, {Color color = AppColors.primary}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))],),);
  Widget _infoCard(String label, String value, IconData icon) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 10), Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 13)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))]));

  Widget _starRow(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < rating.floor() ? Icons.star : Icons.star_half, color: AppColors.amber, size: 18)));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
