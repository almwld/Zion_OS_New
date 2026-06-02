import 'package:sehatak/presentation/screens/cart/cart_screen.dart';
import 'package:sehatak/presentation/screens/health_map/health_map_screen.dart';
import 'package:sehatak/presentation/screens/physiotherapy/physiotherapy_screen.dart';
import 'package:sehatak/presentation/screens/family_planning/family_planning_screen.dart';
import 'package:sehatak/presentation/screens/genetic_counseling/genetic_counseling_screen.dart';
import 'package:sehatak/presentation/screens/alternative_medicine/alternative_medicine_screen.dart';
import 'package:sehatak/presentation/screens/share_app/share_app_screen.dart';
import 'package:sehatak/presentation/screens/rate_app/rate_app_screen.dart';
import 'package:sehatak/presentation/screens/help_center/help_center_screen.dart';
import 'package:sehatak/presentation/screens/contact_us/contact_us_screen.dart';
import 'package:sehatak/presentation/screens/report_issue/report_issue_screen.dart';
import 'package:sehatak/presentation/screens/privacy/privacy_screen.dart';
import 'package:sehatak/presentation/screens/terms/terms_screen.dart';
import 'package:sehatak/presentation/screens/permissions/permissions_screen.dart';
import 'package:sehatak/presentation/screens/download_data/download_data_screen.dart';
import 'package:sehatak/presentation/screens/font_size/font_size_screen.dart';
import 'package:sehatak/presentation/screens/two_factor_auth/two_factor_auth_screen.dart';
import 'package:sehatak/presentation/screens/change_password/change_password_screen.dart';
import 'package:sehatak/presentation/screens/edit_profile/edit_profile_screen.dart';
import 'package:sehatak/presentation/screens/risk_calculator/risk_calculator_screen.dart';
import 'package:sehatak/presentation/screens/diet_plan/diet_plan_screen.dart';
import 'package:sehatak/presentation/screens/checkup_reminder/checkup_reminder_screen.dart';
import 'package:sehatak/presentation/screens/recovery_calculator/recovery_calculator_screen.dart';
import 'package:sehatak/presentation/screens/home_lab/home_lab_screen.dart';
import 'package:sehatak/presentation/screens/personal_medic/personal_medic_screen.dart';
import 'package:sehatak/presentation/screens/shopping_list/shopping_list_screen.dart';
import 'package:sehatak/presentation/screens/pill_organizer/pill_organizer_screen.dart';
import 'package:sehatak/presentation/screens/urgent_consult/urgent_consult_screen.dart';
import 'package:sehatak/presentation/screens/drug_compare/drug_compare_screen.dart';
import 'package:sehatak/presentation/screens/pediatric_dose/pediatric_dose_screen.dart';
import 'package:sehatak/presentation/screens/vision_test/vision_test_screen.dart';
import 'package:sehatak/presentation/screens/weather_health/weather_health_screen.dart';
import 'package:sehatak/presentation/screens/health_education/health_education_screen.dart';
import 'package:sehatak/presentation/screens/share_health/share_health_screen.dart';
import 'package:sehatak/presentation/screens/health_news/health_news_screen.dart';
import 'package:sehatak/presentation/screens/nearby_clinics/nearby_clinics_screen.dart';
import 'package:sehatak/presentation/screens/vitals/vitals_dashboard_screen.dart';
import 'package:sehatak/presentation/screens/health_calendar/health_calendar_screen.dart';
import 'package:sehatak/presentation/screens/shared/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/screens/pharmacy/pharmacy_screen.dart';
import 'package:sehatak/presentation/screens/patient/patient_medical_history.dart';
import 'package:sehatak/presentation/screens/patient/patient_prescriptions.dart';
import 'package:sehatak/presentation/screens/patient/patient_appointments.dart';
import 'package:sehatak/presentation/screens/shared/notifications_screen.dart';
import 'package:sehatak/presentation/screens/settings/settings_screen.dart';
import 'package:sehatak/presentation/screens/emergencies/emergency_numbers.dart';
import 'package:sehatak/presentation/screens/insurance/insurance_companies.dart';
import 'package:sehatak/presentation/screens/lab/labs_list_screen.dart';
import 'package:sehatak/presentation/screens/map/interactive_map_screen.dart';
import 'package:sehatak/presentation/screens/about/about_screen.dart';
import 'package:sehatak/presentation/screens/health_tips/health_tips_screen.dart';
import 'package:sehatak/presentation/screens/women_health/period_tracker_screen.dart';
import 'package:sehatak/presentation/screens/home_care/home_care_screen.dart';
import 'package:sehatak/presentation/screens/family_doctor/family_doctor_screen.dart';
import 'package:sehatak/presentation/screens/blood_donation/blood_donation_screen.dart';
import 'package:sehatak/presentation/screens/vaccination/vaccination_screen.dart';
import 'package:sehatak/presentation/screens/first_aid/first_aid_screen.dart';
import 'package:sehatak/presentation/screens/child_growth/child_growth_screen.dart';
import 'package:sehatak/presentation/screens/drug_dictionary/drug_dictionary_screen.dart';
import 'package:sehatak/presentation/screens/medical_reports/medical_reports_screen.dart';
import 'package:sehatak/presentation/screens/medication/medication_reminder_screen.dart';
import 'package:sehatak/presentation/screens/health_tools/bmi_calculator_screen.dart';
import 'package:sehatak/presentation/screens/health_tools/calorie_calculator_screen.dart';
import 'package:sehatak/presentation/screens/mental_health/mental_health_screen.dart';
import 'package:sehatak/presentation/screens/articles/articles_screen.dart';
import 'package:sehatak/presentation/screens/health_shop/health_shop_screen.dart';
import 'package:sehatak/presentation/screens/hospital_booking/hospital_booking_screen.dart';
import 'package:sehatak/presentation/screens/pregnancy/pregnancy_tracker_screen.dart';
import 'package:sehatak/presentation/screens/symptom_checker/symptom_checker_screen.dart';
import 'package:sehatak/presentation/screens/sleep_tracker/sleep_tracker_screen.dart';
import 'package:sehatak/presentation/screens/step_counter/step_counter_screen.dart';
import 'package:sehatak/presentation/screens/health_tools/heart_rate_screen.dart';
import 'package:sehatak/presentation/screens/health_challenges/health_challenges_screen.dart';
import 'package:sehatak/presentation/screens/glucose_tracker/glucose_tracker_screen.dart';
import 'package:sehatak/presentation/screens/stress_meter/stress_meter_screen.dart';
import 'package:sehatak/presentation/screens/dental_care/dental_care_screen.dart';
import 'package:sehatak/presentation/screens/smart_clinic/smart_clinic_screen.dart';
import 'package:sehatak/presentation/screens/eye_care/eye_care_screen.dart';
import 'package:sehatak/presentation/screens/medication/advanced_reminder_screen.dart';
import 'package:sehatak/presentation/screens/health_community/health_community_screen.dart';
import 'package:sehatak/presentation/screens/blood_pressure/blood_pressure_screen.dart';
import 'package:sehatak/presentation/screens/weight_tracker/weight_tracker_screen.dart';
import 'package:sehatak/presentation/screens/favorites/favorite_doctors_screen.dart';
import 'package:sehatak/presentation/screens/voice_search/voice_search_screen.dart';
import 'package:sehatak/presentation/screens/video_consult/video_consult_screen.dart';
import 'package:sehatak/presentation/screens/visit_history/visit_history_screen.dart';
import 'package:sehatak/presentation/screens/hospital_compare/hospital_compare_screen.dart';
import 'package:sehatak/presentation/screens/medical_notes/medical_notes_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ========= خدمات سريعة =========
          Text('خدمات سريعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 8, childAspectRatio: 0.85,
            children: [
              _serviceItem(context, Icons.emergency_share, 'الطوارئ', AppColors.error, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyNumbers()))),
              _serviceItem(context, Icons.local_hospital, 'مستشفيات', AppColors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalBookingScreen()))),
              _serviceItem(context, Icons.science_rounded, 'مختبرات', AppColors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractiveMapScreen(type: 'labs')))),
              _serviceItem(context, Icons.shield_moon, 'تأمين', AppColors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsuranceCompanies()))),
              _serviceItem(context, Icons.local_pharmacy, 'صيدلية', AppColors.success, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen()))),
              _serviceItem(context, Icons.shopping_bag, 'متجر صحي', AppColors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthShopScreen()))),
              _serviceItem(context, Icons.bloodtype, 'بنك الدم', AppColors.error, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodDonationScreen()))),
              _serviceItem(context, Icons.directions_car, 'إسعاف', AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyNumbers()))),
            ],
          ),
          const SizedBox(height: 22),

          // ========= الرعاية الصحية =========
          Text('الرعاية الصحية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.calendar_month_rounded, 'مواعيدي', 'عرض وإدارة المواعيد', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointments()))),
          _menuItem(context, Icons.receipt_long, 'الوصفات الطبية', 'عرض الوصفات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientPrescriptions()))),
          _menuItem(context, Icons.folder_shared, 'السجل الطبي', 'سجل صحي كامل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientMedicalHistory()))),
          _menuItem(context, Icons.chat_bubble_rounded, 'استشارات', 'تحدث مع طبيب', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
          _menuItem(context, Icons.videocam, 'استشارة فيديو', 'مكالمة مباشرة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoConsultScreen()))),
          _menuItem(context, Icons.history, 'سجل الزيارات', 'تاريخ زياراتك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitHistoryScreen()))),
          const SizedBox(height: 22),

          // ========= خدمات متخصصة =========
          Text('خدمات متخصصة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.tips_and_updates, 'نصائح صحية', 'نصائح يومية مفيدة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthTipsScreen()))),
          _menuItem(context, Icons.female, 'صحة المرأة', 'تتبع الدورة الشهرية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeriodTrackerScreen()))),
          _menuItem(context, Icons.home_work, 'خدمات منزلية', 'رعاية في منزلك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeCareScreen()))),
          _menuItem(context, Icons.family_restroom, 'طبيب العائلة', 'متابعة صحة العائلة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDoctorScreen()))),
          _menuItem(context, Icons.pregnant_woman, 'متابعة الحمل', 'أسبوع بأسبوع', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PregnancyTrackerScreen()))),
          _menuItem(context, Icons.child_care, 'نمو الطفل', 'مراحل التطور', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildGrowthScreen()))),
          _menuItem(context, Icons.vaccines, 'سجل التطعيمات', 'تطعيماتك كاملة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccinationScreen()))),
          const SizedBox(height: 22),

          // ========= أدوات صحية =========
          Text('أدوات صحية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.medical_services, 'إسعافات أولية', 'دليل الطوارئ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstAidScreen()))),
          _menuItem(context, Icons.sick, 'فحص الأعراض', 'حلل أعراضك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()))),
          _menuItem(context, Icons.smart_toy, 'العيادة الذكية', 'AI تحليل أعراضك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartClinicScreen()))),
          _menuItem(context, Icons.medication_liquid, 'قاموس الأدوية', 'معلومات الأدوية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrugDictionaryScreen()))),
          _menuItem(context, Icons.monitor_weight, 'حاسبة BMI', 'اعرف وزنك المثالي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BMICalculatorScreen()))),
          _menuItem(context, Icons.calculate, 'حاسبة السعرات', 'احسب سعرات طعامك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieCalculatorScreen()))),
          _menuItem(context, Icons.favorite, 'معدل القلب', 'نبضات القلب والتمارين', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeartRateScreen()))),
          const SizedBox(height: 22),

          // ========= متابعة صحية =========
          Text('متابعة صحية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.alarm, 'تذكير الأدوية', 'لا تنس جرعاتك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationReminderScreen()))),
          _menuItem(context, Icons.notifications_active, 'تذكير متقدم', 'جرعات وإعادة تعبئة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReminderScreen()))),
          _menuItem(context, Icons.bedtime, 'تتبع النوم', 'جودة ومدة نومك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepTrackerScreen()))),
          _menuItem(context, Icons.directions_walk, 'عداد الخطوات', 'خطواتك اليومية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StepCounterScreen()))),
          _menuItem(context, Icons.monitor_heart, 'ضغط الدم', 'تتبع وسجل ضغطك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodPressureScreen()))),
          _menuItem(context, Icons.monitor_weight_outlined, 'تتبع الوزن', 'وزنك وBMI والهدف', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightTrackerScreen()))),
          _menuItem(context, Icons.bloodtype_outlined, 'تتبع السكر', 'قراءات الجلوكوز', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlucoseTrackerScreen()))),
          const SizedBox(height: 22),

          // ========= خدمات أخرى =========
          Text('خدمات أخرى', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.description, 'تقارير طبية', 'تقاريرك المخزنة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalReportsScreen()))),
          _menuItem(context, Icons.article, 'مقالات طبية', 'اقرأ أحدث المقالات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesScreen()))),
          _menuItem(context, Icons.people, 'مجتمع صحتك', 'انضم للنقاشات الصحية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCommunityScreen()))),
          _menuItem(context, Icons.emoji_events, 'تحديات صحية', 'اربح نقاطاً وجوائز', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthChallengesScreen()))),
          _menuItem(context, Icons.psychology, 'صحة نفسية', 'استشارات ودعم نفسي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentalHealthScreen()))),
          _menuItem(context, Icons.masks, 'طب الأسنان', 'خدمات ونصائح للأسنان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DentalCareScreen()))),
          _menuItem(context, Icons.visibility, 'طب العيون', 'فحوصات ونصائح للعيون', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeCareScreen()))),
          _menuItem(context, Icons.favorite_outline, 'أطباء مفضلين', 'قائمة أطبائك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteDoctorsScreen()))),
          _menuItem(context, Icons.compare, 'مقارنة مستشفيات', 'قارن قبل الاختيار', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalCompareScreen()))),
          _menuItem(context, Icons.note_alt, 'ملاحظات طبية', 'دون ملاحظاتك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalNotesScreen()))),
          _menuItem(context, Icons.psychology_alt, 'مقياس التوتر', 'قِس مستوى توترك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StressMeterScreen()))),
          _menuItem(context, Icons.mic, 'بحث صوتي', 'تحدث للبحث', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceSearchScreen()))),
          const SizedBox(height: 22),

          // ========= عام =========
          _menuItem(context, Icons.calendar_month, 'التقويم الصحي', 'مواعيدك وأحداثك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCalendarScreen()))),
          _menuItem(context, Icons.search, 'بحث متقدم', 'ابحث في كل الخدمات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          _menuItem(context, Icons.dashboard, 'المؤشرات الحيوية', 'ضغط، سكر، وزن، نوم', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsDashboardScreen()))),
          _menuItem(context, Icons.smart_display, 'تثقيف صحي', 'فيديوهات تعليمية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthEducationScreen()))),
          _menuItem(context, Icons.share, 'مشاركة الملف', 'شارك بياناتك بأمان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareHealthScreen()))),
          _menuItem(context, Icons.newspaper, 'أخبار صحية', 'آخر الأخبار', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthNewsScreen()))),
          _menuItem(context, Icons.location_on, 'عيادات قريبة', 'الأقرب لك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyClinicsScreen()))),
          _menuItem(context, Icons.child_care, 'جرعات الأطفال', 'حاسبة أدوية الأطفال', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PediatricDoseScreen()))),
          _menuItem(context, Icons.visibility, 'فحص النظر', 'اختبر قوة بصرك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionTestScreen()))),
          _menuItem(context, Icons.wb_sunny, 'الطقس والصحة', 'تأثير الطقس عليك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherHealthScreen()))),
          _menuItem(context, Icons.calendar_view_week, 'منظم الأدوية', 'جدول أسبوعي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PillOrganizerScreen()))),
          _menuItem(context, Icons.priority_high, 'استشارة طارئة', 'تواصل فوري', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UrgentConsultScreen()))),
          _menuItem(context, Icons.compare_arrows, 'مقارنة أدوية', 'قارن بين الأدوية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrugCompareScreen()))),
          _menuItem(context, Icons.medical_services, 'المسعف الشخصي', 'إسعافات فورية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalMedicScreen()))),
          _menuItem(context, Icons.shopping_cart, 'قائمة التسوق', 'تسوق صحي', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()))),
          _menuItem(context, Icons.healing, 'حاسبة التعافي', 'مدة الشفاء المتوقعة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryCalculatorScreen()))),
          _menuItem(context, Icons.home_repair_service, 'فحص منزلي', 'اطلب الفحص لبابك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeLabScreen()))),
          _menuItem(context, Icons.assessment, 'حاسبة الخطر', 'خطر الأمراض', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskCalculatorScreen()))),
          _menuItem(context, Icons.restaurant_menu, 'خطة غذائية', 'حمية مخصصة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DietPlanScreen()))),
          _menuItem(context, Icons.event_note, 'فحوصات دورية', 'تذكير الفحوصات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckupReminderScreen()))),
          _menuItem(context, Icons.accessibility_new, 'علاج طبيعي', 'جلسات منزلية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhysiotherapyScreen()))),
          _menuItem(context, Icons.family_restroom, 'تنظيم الأسرة', 'استشارات ووسائل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPlanningScreen()))),
          _menuItem(context, Icons.biotech, 'الاستشارات الوراثية', 'فحوصات DNA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneticCounselingScreen()))),
          _menuItem(context, Icons.eco, 'الطب البديل', 'علاجات طبيعية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlternativeMedicineScreen()))),
          _menuItem(context, Icons.map, 'خرائط المرافق', 'جميع المرافق الصحية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthMapScreen()))),
          Text('عام', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _menuItem(context, Icons.notifications_active, 'الإشعارات', 'تنبيهاتك', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          _menuItem(context, Icons.settings_rounded, 'الإعدادات', 'تفضيلات التطبيق', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          _menuItem(context, Icons.help_outline, 'المساعدة', 'أسئلة شائعة وتواصل', () {}),
          _menuItem(context, Icons.share_rounded, 'مشاركة', 'شارك التطبيق', () {}),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _serviceItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 5), elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
        trailing: const Icon(Icons.arrow_back_ios, size: 12, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
