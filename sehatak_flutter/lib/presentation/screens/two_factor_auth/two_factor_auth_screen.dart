import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});
  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool _isEnabled = false;
  String _selectedMethod = 'منصة المصادقة';
  
  // كود تجريبي للعرض
  final String _secretKey = 'JBSW Y3DP EBPW C3TP';
  final List<String> _backupCodes = [
    'A1B2-C3D4-E5F6',
    'G7H8-I9J0-K1L2',
    'M3N4-O5P6-Q7R8',
    'S9T0-U1V2-W3X4',
    'Y5Z6-A7B8-C9D0',
  ];
  
  final TextEditingController _codeController = TextEditingController();
  final List<TextEditingController> _digitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _showBackupCodes = false;
  int _verificationStep = 0; // 0=disabled, 1=setup, 2=verify, 3=enabled

  @override
  void initState() {
    super.initState();
    if (_isEnabled) _verificationStep = 3;
  }

  void _startSetup() {
    setState(() => _verificationStep = 1);
  }

  void _verifySetup() {
    setState(() => _verificationStep = 2);
  }

  void _confirmCode() {
    // محاكاة التحقق من الكود
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        title: const Text('تم التفعيل بنجاح'),
        content: const Text('تم تفعيل المصادقة الثنائية. احفظ رموز الاسترداد في مكان آمن.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); setState(() { _isEnabled = true; _verificationStep = 3; }); }, child: const Text('حسناً')),
        ],
      ),
    );
  }

  void _disable2FA() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعطيل المصادقة الثنائية'),
        content: const Text('هل أنت متأكد من تعطيل المصادقة الثنائية؟ سيصبح حسابك أقل أماناً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() { _isEnabled = false; _verificationStep = 0; }); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المصادقة الثنائية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // بطاقة الحالة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _isEnabled ? [AppColors.success, AppColors.teal] : [AppColors.grey, AppColors.darkGrey]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Icon(_isEnabled ? Icons.shield : Icons.shield_outlined, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(_isEnabled ? 'المصادقة الثنائية مفعلة' : 'المصادقة الثنائية غير مفعلة', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_isEnabled ? 'حسابك محمي بدرجة عالية' : 'فعل المصادقة لحماية حسابك', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),

          // الخطوة 0: غير مفعل - زر التفعيل
          if (_verificationStep == 0) ...[
            _infoCard(
              Icons.security,
              'لماذا المصادقة الثنائية؟',
              'تضيف طبقة حماية إضافية لحسابك. حتى لو عرف أحدهم كلمة مرورك، لن يستطيع الدخول بدون رمز التحقق.',
              AppColors.info,
            ),
            const SizedBox(height: 16),
            _methodSelector(),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _startSetup, icon: const Icon(Icons.shield), label: const Text('تفعيل المصادقة الثنائية'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)))),
          ],

          // الخطوة 1: إعداد - عرض المفتاح السري
          if (_verificationStep == 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('1. امسح رمز QR أو أدخل المفتاح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                const Text('افتح منصة المصادقة (Google Authenticator) وامسح الرمز:', style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                    child: const Center(child: Icon(Icons.qr_code_2, size: 120, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 12),
                _codeBox('المفتاح السري:', _secretKey),
                const SizedBox(height: 16),
                const Text('2. أدخل رمز التحقق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                // 6 خانات للكود
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (i) => SizedBox(
                  width: 45, height: 55,
                  child: TextField(
                    controller: _digitControllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    onChanged: (v) { if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus(); },
                  ),
                ))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _confirmCode, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('تحقق وتفعيل'))),
              ]),
            ),
          ],

          // الخطوة 3: مفعل - إدارة
          if (_verificationStep == 3) ...[
            _infoCard(Icons.check_circle, 'الحالة', 'المصادقة الثنائية مفعلة. تم آخر تحقق: اليوم', AppColors.success),
            const SizedBox(height: 12),
            
            // رموز الاسترداد
            GestureDetector(
              onTap: () => setState(() => _showBackupCodes = !_showBackupCodes),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.key, color: AppColors.warning), const SizedBox(width: 8), const Text('رموز الاسترداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const Spacer(), Icon(_showBackupCodes ? Icons.expand_less : Icons.expand_more)]),
                  if (_showBackupCodes) ...[
                    const SizedBox(height: 8),
                    const Text('احفظ هذه الرموز في مكان آمن. تستخدم لمرة واحدة فقط.', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                    const SizedBox(height: 8),
                    ..._backupCodes.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [const Icon(Icons.content_copy, size: 14, color: AppColors.grey), const SizedBox(width: 8), Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2))]),
                    )),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 12),
            
            // إعادة تعيين
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('خيارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ListTile(leading: const Icon(Icons.refresh, color: AppColors.info), title: const Text('إعادة تعيين'), subtitle: const Text('توليد رموز استرداد جديدة'), onTap: () {}),
                ListTile(leading: const Icon(Icons.phone_android, color: AppColors.primary), title: const Text('تغيير الجهاز'), subtitle: const Text('إعداد على جهاز جديد'), onTap: () {}),
                ListTile(leading: const Icon(Icons.close, color: AppColors.error), title: const Text('تعطيل', style: TextStyle(color: AppColors.error)), subtitle: const Text('إلغاء المصادقة الثنائية'), onTap: _disable2FA),
              ]),
            ),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.darkGrey))]))]),
    );
  }

  Widget _methodSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('طريقة المصادقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        RadioListTile<String>(value: 'منصة المصادقة', groupValue: _selectedMethod, title: const Text('منصة المصادقة'), subtitle: const Text('Google Authenticator'), activeColor: AppColors.primary, onChanged: (v) => setState(() => _selectedMethod = v!)),
        RadioListTile<String>(value: 'رسالة نصية', groupValue: _selectedMethod, title: const Text('رسالة نصية SMS'), subtitle: const Text('رمز عبر رسالة نصية'), activeColor: AppColors.primary, onChanged: (v) => setState(() => _selectedMethod = v!)),
        RadioListTile<String>(value: 'بريد إلكتروني', groupValue: _selectedMethod, title: const Text('البريد الإلكتروني'), subtitle: const Text('رمز عبر البريد'), activeColor: AppColors.primary, onChanged: (v) => setState(() => _selectedMethod = v!)),
      ]),
    );
  }

  Widget _codeBox(String label, String code) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        const Spacer(),
        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2, color: AppColors.primary)),
        const SizedBox(width: 8),
        GestureDetector(onTap: () {}, child: const Icon(Icons.content_copy, size: 18, color: AppColors.grey)),
      ]),
    );
  }
}
