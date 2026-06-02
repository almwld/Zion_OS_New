import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Header(title: 'سياسة الخصوصية لمنصة صحتك', subtitle: 'آخر تحديث: 1 مايو 2026'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withOpacity(0.2))),
            child: const Row(children: [Icon(Icons.info, color: AppColors.info, size: 20), SizedBox(width: 8), Expanded(child: Text('نحن نهتم بخصوصيتك. تشرح هذه السياسة كيف نجمع ونستخدم ونحمي بياناتك.', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)))]),
          ),
          const SizedBox(height: 16),
          const _Section(title: '1. المعلومات التي نجمعها', content: '• المعلومات الشخصية: الاسم، البريد الإلكتروني، رقم الهاتف.\n• المعلومات الصحية: التاريخ الطبي، الأمراض، الحساسية، الأدوية.\n• معلومات الجهاز: نوع الجهاز، نظام التشغيل، عنوان IP.\n• معلومات الموقع: موقعك الجغرافي للخدمات القريبة.'),
          const _Section(title: '2. كيفية استخدام المعلومات', content: '• تقديم وتحسين خدماتنا الصحية.\n• تخصيص تجربتك في التطبيق.\n• التواصل معك بخصوص المواعيد والتذكيرات.\n• مشاركة البيانات مع الأطباء بموافقتك الصريحة.'),
          const _Section(title: '3. مشاركة المعلومات', content: '• لا نبيع بياناتك لأي طرف ثالث.\n• نشارك البيانات مع مقدمي الرعاية الصحية بموافقتك.\n• قد نشارك بيانات مجمعة (بدون تعريف شخصي) لأغراض بحثية.\n• نلتزم بالقوانين المحلية والدولية لحماية البيانات.'),
          const _Section(title: '4. أمان البيانات', content: '• تشفير جميع البيانات أثناء النقل والتخزين.\n• استخدام بروتوكولات أمان متقدمة.\n• فريق أمني متخصص لمراقبة وحماية البيانات.\n• نسخ احتياطي دوري للبيانات.'),
          const _Section(title: '5. حقوق المستخدم', content: '• الوصول إلى بياناتك الشخصية.\n• تصحيح البيانات غير الدقيقة.\n• حذف حسابك وبياناتك.\n• سحب الموافقة على معالجة البيانات.\n• تصدير بياناتك بصيغة مقروءة.'),
          const _Section(title: '6. ملفات تعريف الارتباط', content: '• نستخدم ملفات تعريف الارتباط لتحسين تجربة التطبيق.\n• يمكنك تعطيلها من إعدادات جهازك.\n• لا نستخدم ملفات تتبع طرف ثالث.'),
          const _Section(title: '7. الاحتفاظ بالبيانات', content: '• نحتفظ ببياناتك طوال فترة استخدامك للتطبيق.\n• بعد حذف الحساب، نحذف البيانات خلال 30 يوماً.\n• قد نحتفظ ببعض البيانات للأغراض القانونية.'),
          const _Section(title: '8. تحديثات السياسة', content: '• سنخطرك بأي تغييرات جوهرية في سياسة الخصوصية.\n• استمرار استخدامك للمنصة يعني موافقتك على التحديثات.'),
          const _Section(title: '9. تواصل معنا', content: 'لأي استفسار عن سياسة الخصوصية:\n📧 privacy@sehatak.com\n📱 +967 777 123 456\n🏢 شارع الزبيري، صنعاء، اليمن'),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title, subtitle;
  const _Header({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String title, content;
  const _Section({required this.title, required this.content});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.darkGrey)),
      ]),
    );
  }
}
