import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والأحكام', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Header(title: 'الشروط والأحكام', subtitle: 'آخر تحديث: 1 مايو 2026'),
          const SizedBox(height: 10),
          const _Section(title: '1. القبول', content: 'باستخدامك منصة صحتك، فإنك توافق على هذه الشروط والأحكام. إذا كنت لا توافق، يرجى عدم استخدام التطبيق.'),
          const _Section(title: '2. الخدمات', content: '• استشارات طبية عبر الإنترنت.\n• حجز مواعيد مع الأطباء.\n• طلب الأدوية وتوصيلها.\n• حجز التحاليل والفحوصات.\n• الوصول إلى السجل الطبي.'),
          const _Section(title: '3. الاستشارات الطبية', content: '• الاستشارات عبر المنصة لا تغني عن زيارة الطبيب.\n• في الحالات الطارئة، اتصل بالإسعاف فوراً.\n• الأطباء يبذلون قصارى جهدهم ولكن لا نضمن دقة التشخيص عن بعد.'),
          const _Section(title: '4. حسابات المستخدمين', content: '• أنت مسؤول عن الحفاظ على سرية حسابك.\n• يجب أن تكون المعلومات المقدمة صحيحة ودقيقة.\n• يمنع مشاركة حسابك مع آخرين.\n• نحتفظ بالحق في تعليق الحسابات المخالفة.'),
          const _Section(title: '5. المدفوعات', content: '• جميع الأسعار بالريال اليمني أو حسب العملة المختارة.\n• الرسوم غير قابلة للاسترداد بعد إتمام الخدمة.\n• نستخدم بوابات دفع آمنة ومعتمدة.'),
          const _Section(title: '6. الإلغاء والاسترداد', content: '• يمكن إلغاء المواعيد قبل 24 ساعة من الموعد.\n• رسوم الإلغاء المتأخر: 25% من قيمة الخدمة.\n• الأدوية غير قابلة للاسترداد بعد الفتح.'),
          const _Section(title: '7. الملكية الفكرية', content: '• جميع المحتويات (نصوص، صور، شعارات) مملوكة لمنصة صحتك.\n• يمنع نسخ أو توزيع المحتوى بدون إذن مسبق.'),
          const _Section(title: '8. حدود المسؤولية', content: '• المنصة وسيط بينك وبين مقدمي الخدمة.\n• لسنا مسؤولين عن أي أضرار ناتجة عن استخدام التطبيق.\n• مسؤولية التشخيص والعلاج تقع على عاتق مقدم الخدمة.'),
          const _Section(title: '9. إنهاء الخدمة', content: '• يمكنك حذف حسابك في أي وقت.\n• نحتفظ بالحق في إنهاء خدمتك في حالة المخالفة.\n• بعد الحذف، تفقد حق الوصول لبياناتك.'),
          const _Section(title: '10. القانون المطبق', content: '• تخضع هذه الشروط للقوانين اليمنية.\n• أي نزاع يحل ودياً أو عبر المحاكم المختصة في صنعاء.\n• آخر تحديث: 1 مايو 2026'),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('أوافق على الشروط'))),
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
      margin: const EdgeInsets.only(bottom: 10),
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
