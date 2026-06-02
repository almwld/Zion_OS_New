import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  double _balance = 25000;
  final _amountCtrl = TextEditingController();
  bool _showTopUp = false;
  String _topUpWallet = 'فلوسك';
  String _topUpMethod = 'بطاقة ائتمان';

  final List<Map<String, dynamic>> _wallets = const [
    {'name': 'فلوسك', 'code': 'FLOSWK', 'icon': '💳', 'color': Color(0xFF1A73E8), 'number': '**** 4582', 'balance': '12,500 ر.ي'},
    {'name': 'محفظة كاش', 'code': 'CASH', 'icon': '💰', 'color': Color(0xFF00A86B), 'number': '**** 7891', 'balance': '8,200 ر.ي'},
    {'name': 'محفظة جوالي', 'code': 'JAWALI', 'icon': '📱', 'color': Color(0xFFFF6B00), 'number': '**** 3456', 'balance': '4,300 ر.ي'},
    {'name': 'محفظة جيب', 'code': 'JEEB', 'icon': '👛', 'color': Color(0xFFE91E63), 'number': '**** 9012', 'balance': '0 ر.ي'},
    {'name': 'محفظة إيزي', 'code': 'EASY', 'icon': '🏧', 'color': Color(0xFF0277BD), 'number': '**** 5678', 'balance': '0 ر.ي'},
  ];

  void _topUp() {
    final a = int.tryParse(_amountCtrl.text);
    if (a == null || a <= 0) return;
    setState(() { _balance += a; _showTopUp = false; _amountCtrl.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم شحن $a ر.ي'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة الإلكترونية', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الرصيد الإجمالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text('$_balance ر.ي', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _btn('شحن', Icons.add_circle, () => setState(() => _showTopUp = true)),
              _btn('تحويل', Icons.swap_horiz, () {}),
              _btn('سجل', Icons.receipt_long, () {}),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Text('محافظي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        for (final w in _wallets) Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: (w['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(w['icon'], style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(w['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('${w['code']} • ${w['number']}', style: const TextStyle(fontSize: 10, color: AppColors.grey)), Text(w['balance'], style: TextStyle(fontWeight: FontWeight.bold, color: w['color'], fontSize: 13))])),
            ElevatedButton(onPressed: () { setState(() => _topUpWallet = w['name']); _showTopUp = true; }, style: ElevatedButton.styleFrom(backgroundColor: w['color'], padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero), child: const Text('شحن', style: TextStyle(fontSize: 10, color: Colors.white))),
          ]),
        ),
      ])),
      bottomSheet: _showTopUp ? Container(
        padding: const EdgeInsets.all(20), color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('شحن $_topUpWallet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _showTopUp = false))]),
          const SizedBox(height: 10),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ (ر.ي)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _topUp, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('تأكيد الشحن', style: TextStyle(fontSize: 16)))),
        ]),
      ) : null,
    );
  }

  Widget _btn(String l, IconData i, VoidCallback t) => GestureDetector(onTap: t, child: Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(i, color: Colors.white, size: 22)), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 10))]));
}
