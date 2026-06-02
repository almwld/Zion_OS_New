import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sehatak/presentation/screens/notification/notification_screen.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/core/services/api_service.dart';
import 'package:sehatak/presentation/widgets/common_widgets.dart';
import 'package:sehatak/presentation/screens/doctor/doctors_list_screen.dart';
import 'package:sehatak/presentation/screens/doctor/doctor_details_screen.dart';
import 'package:sehatak/presentation/screens/more/more_screen.dart';
import 'package:sehatak/presentation/screens/pharmacy/pharmacy_screen.dart';
import 'package:sehatak/presentation/screens/emergencies/emergency_numbers.dart';
import 'package:sehatak/presentation/bloc/theme_bloc/theme_bloc.dart';
import 'package:sehatak/presentation/screens/health_tips/health_tips_screen.dart';
import 'package:sehatak/presentation/screens/nearby/nearby_screen.dart';
import 'package:sehatak/presentation/screens/patient/patient_appointments.dart';
import 'package:sehatak/presentation/screens/patient/patient_dashboard.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/widgets/services_carousel.dart';
import 'package:sehatak/presentation/screens/smart_clinic/smart_clinic_screen.dart';
import 'package:sehatak/presentation/screens/cart/cart_screen.dart';
import 'package:sehatak/presentation/screens/lab/labs_list_screen.dart';
import 'package:sehatak/presentation/screens/payment/payment_methods_screen.dart';
import 'package:sehatak/presentation/screens/health_community/health_community_screen.dart';
import 'package:sehatak/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:sehatak/presentation/screens/auth/login_screen.dart';
import 'package:sehatak/presentation/widgets/shimmer/shimmer_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () => setState(() => _isLoading = false));
  }

  final List<Widget> _screens = const [
    _HomeTab(), DoctorsListScreen(), PharmacyScreen(),
    ChatScreen(), PatientAppointments(), PatientDashboard(), MoreScreen(),
  ];

  void _requireAuth(VoidCallback action) {
    if (ApiService.isLoggedIn) {
      action();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => AuthBloc(), child: const LoginScreen())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111D33) : Colors.white,
        boxShadow: [BoxShadow(color: isDark ? Colors.black38 : AppColors.primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _navItem(0, Icons.home_rounded, 'الرئيسية'),
          _navItem(1, Icons.person_search_rounded, 'الأطباء'),
          _navItem(2, Icons.local_pharmacy_rounded, 'الصيدلية'),
          _centerChatButton(),
          _navItem(4, Icons.calendar_month_rounded, 'المواعيد'),
          _navItem(5, Icons.folder_rounded, 'صحتي'),
          _navItem(6, Icons.grid_view_rounded, 'المزيد'),
        ]),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.grey;
    return GestureDetector(
      onTap: () {
        if (index == 3 || index == 4 || index == 5) {
          _requireAuth(() => setState(() => _currentIndex = index));
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (selected) Container(width: 28, height: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 2),
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: color)),
        ]),
      ),
    );
  }

  Widget _centerChatButton() {
    final selected = _currentIndex == 3;
    return GestureDetector(
      onTap: () => _requireAuth(() => setState(() => _currentIndex = 3)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 2),
        Text('الدردشة', style: TextStyle(fontSize: 8, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppColors.primary : AppColors.grey)),
      ]),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _requireAuth(BuildContext context, VoidCallback action) {
    if (ApiService.isLoggedIn) {
      action();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => AuthBloc(), child: const LoginScreen())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 8),
          IconButton(
            icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.amber.withOpacity(0.2))), child: const Icon(Icons.account_balance_wallet, color: AppColors.amber, size: 20)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())), tooltip: 'المحفظة',
          ),
          IconButton(
            icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.smart_toy, color: Colors.white, size: 20)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartClinicScreen())), tooltip: 'المساعد الذكي',
          ),
        ]),
        title: Text(isLoggedIn ? 'مرحباً، أحمد' : 'منصة صحتك', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
IconButton(icon: const Icon(Icons.dark_mode, color: AppColors.primary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.primary), onPressed: () {}),
          if (!isLoggedIn)
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => AuthBloc(), child: const LoginScreen()))), child: const Text('تسجيل', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // شريط تسجيل الدخول (يختفي بعد التسجيل)
          if (!isLoggedIn) LoginPromptBar(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => AuthBloc(), child: const LoginScreen())))),

          const SizedBox(height: 14),

          // شريط البحث
          const SizedBox(height: 16),
          const ServicesCarousel(),
          const SizedBox(height: 16),
          const CustomSearchBar(hint: 'بحث عن خدمات، أطباء، مقالات...'),
          const SizedBox(height: 16),

          // البانر الرئيسي
          HeroBannerCard(onTap: () {}),
          const SizedBox(height: 16),
          const SizedBox(height: 22),

          // خدمات سريعة
          Text('خدمات سريعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            QuickServiceCard(icon: Icons.local_pharmacy, label: 'الصيدلية', color: AppColors.success, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen()))),
            QuickServiceCard(icon: Icons.emergency, label: 'الطوارئ', color: AppColors.error, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyNumbers()))),
            QuickServiceCard(icon: Icons.near_me, label: 'بالقرب منك', color: AppColors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyScreen()))),
            QuickServiceCard(icon: Icons.shopping_cart, label: 'السلة', color: AppColors.orange, onTap: () => _requireAuth(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())))),
            QuickServiceCard(icon: Icons.science, label: 'التحاليل', color: AppColors.purple, onTap: () => _requireAuth(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabsListScreen())))),
          ]),
          const SizedBox(height: 22),

          // أفضل الأطباء
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('أفضل الأطباء', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsListScreen())), child: const Text('عرض الكل ›'))]),
          const SizedBox(height: 8),
          DoctorCard(name: 'د. علي المولد', specialty: 'استشاري باطنية وأطفال', experience: 'خبرة 20+ سنة', rating: 4.9, reviews: 328, fee: '500', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: '1')))),
          const SizedBox(height: 8),
          DoctorCard(name: 'د. حسن رضا', specialty: 'طبيب عام', experience: 'خبرة 8+ سنوات', rating: 4.8, reviews: 235, fee: '300', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: '2')))),
          const SizedBox(height: 8),
          DoctorCard(name: 'د. عائشة ملك', specialty: 'طبيبة جلدية', experience: 'خبرة 6+ سنوات', rating: 4.9, reviews: 189, fee: '800', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: '9')))),
          const SizedBox(height: 22),

          // مجتمع صحتك
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('مجتمع صحتك', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: () => _requireAuth(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCommunityScreen()))), child: const Text('عرض الكل ›'))]),
          const SizedBox(height: 8),
          CommunityPostCard(user: 'أم محمد', avatar: '👩', topic: 'سكري الأطفال', content: 'ابني عمره 8 سنوات وشُخص بالسكري. أي نصائح للتعامل معه في المدرسة؟', time: 'منذ 2 ساعة', replies: 24, likes: 45, color: AppColors.error, onTap: () {}),
          CommunityPostCard(user: 'د. حسن رضا', avatar: '👨‍⚕️', topic: 'نصيحة طبية', content: '🫀 تذكير: قياس ضغط الدم بانتظام من أهم عادات الوقاية. المعدل الطبيعي أقل من 120/80.', time: 'منذ 5 ساعات', replies: 18, likes: 92, color: AppColors.success, onTap: () {}),

          if (isLoggedIn) ...[
            const SizedBox(height: 22),
            Text('السجل الطبي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _historyItem('ارتفاع ضغط الدم', 'تم التشخيص: 15 مارس 2023', AppColors.error),
            _historyItem('الربو', 'تم التشخيص: 10 يناير 2021', AppColors.warning),
            _historyItem('التهاب المعدة', 'تم التشخيص: 5 أغسطس 2019', AppColors.info),
          ],
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _historyItem(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Row(children: [Container(width: 4, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.grey))])), const Icon(Icons.chevron_left, color: AppColors.grey)]),
    );
  }
}
