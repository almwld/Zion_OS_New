import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final String planName;
  final String planPrice;
  final String planEmoji;
  
  const SubscriptionPaymentScreen({
    super.key,
    required this.planName,
    required this.planPrice,
    required this.planEmoji,
  });

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  int _selectedWallet = 0;
  bool _processing = false;
  bool _success = false;

  final List<Map<String, dynamic>> _wallets = [
    {'name': 'فلوسك', 'code': 'FLOSWK', 'emoji': '💳', 'color': const Color(0xFF1A73E8), 'number': '**** 4582', 'balance': '12,500 ر.ي'},
    {'name': 'محفظة كاش', 'code': 'CASH', 'emoji': '💰', 'color': const Color(0xFF00A86B), 'number': '**** 7891', 'balance': '8,200 ر.ي'},
    {'name': 'محفظة جوالي', 'code': 'JAWALI', 'emoji': '📱', 'color': const Color(0xFFFF6B00), 'number': '**** 3456', 'balance': '4,300 ر.ي'},
    {'name': 'محفظة جيب', 'code': 'JEEB', 'emoji': '👛', 'color': const Color(0xFFE91E63), 'number': '**** 9012', 'balance': '0 ر.ي'},
    {'name': 'محفظة إيزي', 'code': 'EASY', 'emoji': '🏧', 'color': const Color(0xFF0277BD), 'number': '**** 5678', 'balance': '0 ر.ي'},
  ];

  void _confirmPayment() {
    setState(() => _processing = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _processing = false;
        _success = true;
      });
    });
  }

  void _goBack() {
    Navigator.pop(context, true); // يرجع true للإشارة أن الدفع تم
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الدفع', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // بطاقة الخطة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Text(widget.planEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(widget.planName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('اشتراك شهري', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Text('${widget.planPrice} ر.ي', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const Text('شهرياً', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),

          const SizedBox(height: 24),

          // اختيار المحفظة
          const Text('اختر طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('المحافظ الإلكترونية اليمنية المدعومة', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 12),

          ...List.generate(_wallets.length, (i) {
            final w = _wallets[i];
            final sel = _selectedWallet == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedWallet = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? w['color'].withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? w['color'] : AppColors.outlineVariant, width: sel ? 2 : 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                ),
                child: Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: w['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(w['emoji'], style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(w['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: w['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(w['code'], style: TextStyle(fontSize: 8, color: w['color']))),
                      ]),
                      Text(w['number'], style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                      Text('الرصيد: ${w['balance']}', style: TextStyle(fontWeight: FontWeight.bold, color: w['color'], fontSize: 12)),
                    ]),
                  ),
                  if (sel) Icon(Icons.check_circle, color: w['color'], size: 28),
                ]),
              ),
            );
          }),

          const SizedBox(height: 8),

          // إضافة محفظة جديدة
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            label: const Text('ربط محفظة جديدة', style: TextStyle(color: AppColors.primary)),
          ),

          const SizedBox(height: 20),

          // ملخص الدفع
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _summaryRow('الباقة', widget.planName),
              _summaryRow('المدة', 'شهري'),
              _summaryRow('السعر', '${widget.planPrice} ر.ي'),
              const Divider(),
              _summaryRow('الإجمالي', '${widget.planPrice} ر.ي', bold: true, color: AppColors.primary),
            ]),
          ),

          const SizedBox(height: 20),

          // زر الدفع
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _processing ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: _processing
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('جاري الدفع...', style: TextStyle(fontSize: 17)),
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('💳', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('ادفع ${widget.planPrice} ر.ي عبر ${_wallets[_selectedWallet]['name']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  // ========== شاشة النجاح ==========
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // أيقونة النجاح
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.success, AppColors.teal]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 30)],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 30),
              const Text('تم الدفع بنجاح! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('أنت الآن مشترك في ${widget.planName}', style: const TextStyle(fontSize: 16, color: AppColors.grey)),
              const SizedBox(height: 20),

              // تفاصيل الاشتراك
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                ),
                child: Column(children: [
                  _detailRow('الباقة', widget.planName),
                  _detailRow('المبلغ', '${widget.planPrice} ر.ي'),
                  _detailRow('طريقة الدفع', _wallets[_selectedWallet]['name']),
                  _detailRow('تاريخ التجديد', '${DateTime.now().add(const Duration(days: 30)).day} ${_monthName(DateTime.now().add(const Duration(days: 30)).month)} ${DateTime.now().add(const Duration(days: 30)).year}'),
                ]),
              ),
              const SizedBox(height: 30),

              // أزرار
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _goBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ابدأ الاستخدام الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goBack,
                child: const Text('العودة للرئيسية', style: TextStyle(color: AppColors.grey)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.darkGrey)),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  String _monthName(int month) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1];
  }
}
