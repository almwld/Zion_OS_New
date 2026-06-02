import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({super.key});

  @override
  State<ProviderVerificationScreen> createState() => _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState extends State<ProviderVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق مقدمي الخدمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.medical_services, size: 20), text: 'طبيب'),
            Tab(icon: Icon(Icons.local_pharmacy, size: 20), text: 'صيدلي'),
            Tab(icon: Icon(Icons.emergency, size: 20), text: 'مسعف'),
            Tab(icon: Icon(Icons.local_hospital, size: 20), text: 'مستشفى'),
            Tab(icon: Icon(Icons.biotech, size: 20), text: 'مخبري'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DoctorVerificationTab(),
          _PharmacistVerificationTab(),
          _ParamedicVerificationTab(),
          _HospitalVerificationTab(),
          _LabTechnicianVerificationTab(),
        ],
      ),
    );
  }
}

// ============================================
// 1. تبويب الطبيب
// ============================================
class _DoctorVerificationTab extends StatelessWidget {
  const _DoctorVerificationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('🩺', 'توثيق حساب الطبيب', 'للتسجيل كطبيب معتمد في منصة صحتك، يجب تقديم المستندات التالية لإثبات الأهلية المهنية.', AppColors.primary),
        const SizedBox(height: 16),
        _sectionTitle('المستندات المطلوبة'),
        _docItem('1', 'شهادة البكالوريوس في الطب والجراحة (MBBS أو MD)', 'صورة مصدقة من الشهادة الجامعية'),
        _docItem('2', 'ترخيص مزاولة المهنة من وزارة الصحة', 'ساري المفعول - مع رقم الترخيص وتاريخ الانتهاء'),
        _docItem('3', 'بطاقة التسجيل في نقابة الأطباء', 'سارية المفعول'),
        _docItem('4', 'شهادة الاختصاص (للتخصصات الدقيقة)', 'إن وجدت - مع توثيق من المجلس الطبي'),
        _docItem('5', 'صورة من البطاقة الشخصية أو جواز السفر', 'سارية المفعول'),
        _docItem('6', 'صورة شخصية حديثة', 'خلفية بيضاء - مقاس 4×6'),
        _docItem('7', 'السيرة الذاتية الطبية', 'تشمل سنوات الخبرة والتخصصات الدقيقة'),
        _docItem('8', 'شهادة حسن سير وسلوك', 'من جهة رسمية'),
        const SizedBox(height: 20),
        _sectionTitle('شروط القبول'),
        _conditionItem('حاصل على بكالوريوس طب وجراحة من جامعة معترف بها'),
        _conditionItem('خبرة لا تقل عن سنتين بعد الامتياز'),
        _conditionItem('عدم وجود عقوبات تأديبية سارية من نقابة الأطباء'),
        _conditionItem('اجتياز المقابلة الشخصية مع اللجنة الطبية للمنصة'),
        _conditionItem('الالتزام بمعايير الجودة الطبية المعتمدة من المنصة'),
        _conditionItem('تقديم تقييمات إيجابية من مرضى سابقين (إن وجدت)'),
        const SizedBox(height: 20),
        _sectionTitle('خطوات التسجيل'),
        _stepItem('1', 'تعبئة نموذج التسجيل الإلكتروني'),
        _stepItem('2', 'رفع المستندات المطلوبة'),
        _stepItem('3', 'مراجعة المستندات من فريق التحقق (3-5 أيام عمل)'),
        _stepItem('4', 'مقابلة عبر الفيديو مع اللجنة الطبية'),
        _stepItem('5', 'توقيع اتفاقية مزود الخدمة إلكترونياً'),
        _stepItem('6', 'تفعيل الحساب وبدء استقبال الاستشارات'),
        const SizedBox(height: 24),
        _noteCard('💰 رسوم التوثيق: 5,000 ريال يمني (غير قابلة للاسترداد)\n⏱️ مدة المعالجة: 5-7 أيام عمل'),
      ]),
    );
  }
}

// ============================================
// 2. تبويب الصيدلي
// ============================================
class _PharmacistVerificationTab extends StatelessWidget {
  const _PharmacistVerificationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('💊', 'توثيق حساب الصيدلي', 'للتسجيل كصيدلي معتمد في منصة صحتك، يجب تقديم المستندات التالية لإثبات الأهلية المهنية.', AppColors.success),
        const SizedBox(height: 16),
        _sectionTitle('المستندات المطلوبة'),
        _docItem('1', 'شهادة البكالوريوس في الصيدلة (B.Pharm أو Pharm.D)', 'صورة مصدقة من الشهادة الجامعية'),
        _docItem('2', 'ترخيص مزاولة مهنة الصيدلة من وزارة الصحة', 'ساري المفعول'),
        _docItem('3', 'بطاقة التسجيل في نقابة الصيادلة', 'سارية المفعول'),
        _docItem('4', 'صورة من البطاقة الشخصية أو جواز السفر', 'سارية المفعول'),
        _docItem('5', 'صورة شخصية حديثة', 'خلفية بيضاء'),
        _docItem('6', 'ترخيص الصيدلية (إن كنت تملك صيدلية)', 'ساري المفعول مع العنوان'),
        _docItem('7', 'شهادة التصنيف المهني', 'إن وجدت'),
        const SizedBox(height: 20),
        _sectionTitle('شروط القبول'),
        _conditionItem('حاصل على بكالوريوس صيدلة من جامعة معترف بها'),
        _conditionItem('خبرة لا تقل عن سنة في مجال الصيدلة'),
        _conditionItem('عدم وجود مخالفات مهنية مسجلة'),
        _conditionItem('الالتزام بقوانين الأدوية والتسعيرة الرسمية'),
        _conditionItem('توفير خدمة توصيل الأدوية (لأصحاب الصيدليات)'),
        const SizedBox(height: 20),
        _sectionTitle('خطوات التسجيل'),
        _stepItem('1', 'تعبئة نموذج التسجيل'),
        _stepItem('2', 'رفع المستندات المطلوبة'),
        _stepItem('3', 'مراجعة من فريق التحقق (2-3 أيام عمل)'),
        _stepItem('4', 'تفعيل الحساب وبدء استقبال الطلبات'),
        const SizedBox(height: 24),
        _noteCard('💰 رسوم التوثيق: 3,000 ريال يمني\n⏱️ مدة المعالجة: 3-5 أيام عمل'),
      ]),
    );
  }
}

// ============================================
// 3. تبويب المسعف
// ============================================
class _ParamedicVerificationTab extends StatelessWidget {
  const _ParamedicVerificationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('🚑', 'توثيق حساب المسعف', 'للتسجيل كمسعف معتمد في منصة صحتك، يجب تقديم المستندات التالية لإثبات الأهلية.', AppColors.error),
        const SizedBox(height: 16),
        _sectionTitle('المستندات المطلوبة'),
        _docItem('1', 'شهادة دورة الإسعافات الأولية المتقدمة', 'من جهة معتمدة (الهلال الأحمر، منظمة الصحة)'),
        _docItem('2', 'شهادة BLS أو ACLS', 'Basic Life Support أو Advanced Cardiac Life Support'),
        _docItem('3', 'بطاقة الهوية الشخصية', 'سارية المفعول'),
        _docItem('4', 'رخصة القيادة (للسائقين)', 'سارية المفعول'),
        _docItem('5', 'شهادة حسن سير وسلوك', 'حديثة'),
        _docItem('6', 'الشهادات التدريبية الإضافية', 'مثل: التعامل مع الكوارث، الإسعاف الحربي'),
        _docItem('7', 'صورة شخصية', 'حديثة'),
        const SizedBox(height: 20),
        _sectionTitle('شروط القبول'),
        _conditionItem('إتمام دورة إسعافات أولية متقدمة معتمدة'),
        _conditionItem('معرفة جيدة بالطرق والشوارع في منطقة الخدمة'),
        _conditionItem('لياقة بدنية وصحية جيدة'),
        _conditionItem('القدرة على التعامل مع حالات الطوارئ'),
        _conditionItem('توفر وسيلة مواصلات مناسبة (سيارة إسعاف أو مركبة مجهزة)'),
        _conditionItem('الاستعداد للعمل على مدار 24 ساعة'),
        const SizedBox(height: 20),
        _sectionTitle('خطوات التسجيل'),
        _stepItem('1', 'تعبئة نموذج التسجيل'),
        _stepItem('2', 'رفع المستندات'),
        _stepItem('3', 'اختبار عملي للإسعافات الأولية'),
        _stepItem('4', 'تدريب على استخدام تطبيق المنصة للطوارئ'),
        _stepItem('5', 'تفعيل الحساب والاستعداد للاستجابة'),
        const SizedBox(height: 24),
        _noteCard('💰 رسوم التوثيق: 2,000 ريال يمني\n⏱️ مدة المعالجة: 3-5 أيام عمل'),
      ]),
    );
  }
}

// ============================================
// 4. تبويب المستشفى
// ============================================
class _HospitalVerificationTab extends StatelessWidget {
  const _HospitalVerificationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('🏥', 'توثيق حساب المستشفى', 'لتسجيل مستشفى في منصة صحتك، يجب تقديم المستندات التالية لإثبات الاعتماد.', AppColors.info),
        const SizedBox(height: 16),
        _sectionTitle('المستندات المطلوبة'),
        _docItem('1', 'ترخيص المستشفى من وزارة الصحة', 'ساري المفعول مع الدرجة والتخصص'),
        _docItem('2', 'شهادة الاعتماد من المجلس الطبي اليمني', 'إن وجدت'),
        _docItem('3', 'سجل تجاري ساري المفعول', 'من وزارة الصناعة والتجارة'),
        _docItem('4', 'بطاقة ضريبية', 'سارية المفعول'),
        _docItem('5', 'قائمة بأسماء الأطباء العاملين', 'مع أرقام تراخيصهم'),
        _docItem('6', 'قائمة الأقسام والتخصصات المتوفرة', 'مع عدد الأسرة لكل قسم'),
        _docItem('7', 'صور من داخل المستشفى', 'الاستقبال، الغرف، غرفة العمليات'),
        _docItem('8', 'عقد إيجار أو ملكية المبنى', 'موثق'),
        _docItem('9', 'شهادة السلامة من الدفاع المدني', 'سارية المفعول'),
        _docItem('10', 'ترخيص المختبر والصيدلية الداخلية', 'إن وجدت'),
        const SizedBox(height: 20),
        _sectionTitle('شروط القبول'),
        _conditionItem('مستشفى مرخص من وزارة الصحة اليمنية'),
        _conditionItem('توفر 50 سريراً على الأقل'),
        _conditionItem('توفر قسم طوارئ يعمل 24 ساعة'),
        _conditionItem('توفر أطباء اختصاص في جميع الأقسام الأساسية'),
        _conditionItem('توفر مختبر وأشعة داخل المستشفى'),
        _conditionItem('الالتزام بمعايير مكافحة العدوى والجودة'),
        const SizedBox(height: 20),
        _sectionTitle('خطوات التسجيل'),
        _stepItem('1', 'تعبئة نموذج تسجيل المستشفى'),
        _stepItem('2', 'رفع جميع المستندات المطلوبة'),
        _stepItem('3', 'زيارة تفتيشية من فريق المنصة'),
        _stepItem('4', 'توقيع اتفاقية الشراكة'),
        _stepItem('5', 'تدريب الموظفين على نظام المنصة'),
        _stepItem('6', 'تفعيل الحساب وبدء استقبال المرضى'),
        const SizedBox(height: 24),
        _noteCard('💰 رسوم التوثيق: 25,000 ريال يمني\n⏱️ مدة المعالجة: 7-14 يوم عمل\n📋 تتضمن الزيارة التفتيشية'),
      ]),
    );
  }
}

// ============================================
// 5. تبويب المخبري
// ============================================
class _LabTechnicianVerificationTab extends StatelessWidget {
  const _LabTechnicianVerificationTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoCard('🔬', 'توثيق حساب المخبري', 'للتسجيل كمختبر أو فني تحاليل معتمد في منصة صحتك، يجب تقديم المستندات التالية.', AppColors.purple),
        const SizedBox(height: 16),
        _sectionTitle('المستندات المطلوبة'),
        _docItem('1', 'شهادة البكالوريوس في التحاليل الطبية أو المختبرات', 'صورة مصدقة'),
        _docItem('2', 'ترخيص المختبر من وزارة الصحة', 'ساري المفعول'),
        _docItem('3', 'بطاقة التسجيل المهني', 'من نقابة المختبرات'),
        _docItem('4', 'قائمة التحاليل المتوفرة', 'مع الأسعار'),
        _docItem('5', 'شهادات معايرة الأجهزة', 'حديثة'),
        _docItem('6', 'صورة من البطاقة الشخصية', 'سارية'),
        _docItem('7', 'عقد إيجار أو ملكية المختبر', 'إن وجد'),
        _docItem('8', 'شهادة ضبط الجودة', 'إن وجدت ISO 15189'),
        const SizedBox(height: 20),
        _sectionTitle('شروط القبول'),
        _conditionItem('حاصل على بكالوريوس تحاليل طبية أو كيمياء حيوية'),
        _conditionItem('خبرة لا تقل عن سنة في العمل المخبري'),
        _conditionItem('توفر أجهزة مخبرية معايرة ومناسبة'),
        _conditionItem('الالتزام بمعايير الجودة والمكافحة'),
        _conditionItem('توفير خدمة سحب عينات منزلية (اختياري)'),
        const SizedBox(height: 20),
        _sectionTitle('خطوات التسجيل'),
        _stepItem('1', 'تعبئة نموذج التسجيل'),
        _stepItem('2', 'رفع المستندات المطلوبة'),
        _stepItem('3', 'فحص عينات مراقبة الجودة'),
        _stepItem('4', 'تفعيل الحساب وبدء استقبال الطلبات'),
        const SizedBox(height: 24),
        _noteCard('💰 رسوم التوثيق: 5,000 ريال يمني\n⏱️ مدة المعالجة: 5-7 أيام عمل'),
      ]),
    );
  }
}

// ============================================
// ويدجتس مساعدة
// ============================================

Widget _infoCard(String emoji, String title, String subtitle, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
 borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 36)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
      ])),
    ]),
  );
}

Widget _sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
  );
}

Widget _docItem(String number, String title, String description) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
      ])),
    ]),
  );
}

Widget _conditionItem(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

Widget _stepItem(String number, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 24, height: 24, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

Widget _noteCard(String text) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, color: AppColors.warning, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey, height: 1.6))),
    ]),
  );
}
