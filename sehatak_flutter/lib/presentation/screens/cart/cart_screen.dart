import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'باراسيتامول 500mg', 'price': 500, 'qty': 2, 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=100'},
    {'name': 'فيتامين د 1000IU', 'price': 1200, 'qty': 1, 'image': 'https://images.unsplash.com/photo-1550572012-edd7b1a7b51c?w=100'},
    {'name': 'جهاز قياس ضغط', 'price': 8500, 'qty': 1, 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=100'},
  ];

  int get _total => _items.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));
  int _selectedPayment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _items.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.grey), SizedBox(height: 16), Text('السلة فارغة', style: TextStyle(fontSize: 18, color: AppColors.grey))]))
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                      child: Row(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${item['price']} ر.ي', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ])),
                        Row(children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => setState(() { if (item['qty'] > 1) item['qty']--; else _items.removeAt(i); })),
                          Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.success), onPressed: () => setState(() => item['qty']++)),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
              // طرق الدفع اليمنية
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('طرق الدفع', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _paymentOption(0, 'محفظة فلوسك', 'FLOSWK', 'https://play.google.com/store/apps/details?id=com.floswk'),
                  _paymentOption(1, 'محفظة كاش', 'CASH', 'https://cashwallet.com'),
                  _paymentOption(2, 'محفظة جوالي', 'JAWALI', 'https://jawali.com'),
                  _paymentOption(3, 'الدفع عند الاستلام', 'COD', ''),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('$_total ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تقديم الطلب بنجاح!'), backgroundColor: AppColors.success)); setState(() => _items.clear()); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('إتمام الشراء', style: TextStyle(fontSize: 16)))),
                ]),
              ),
            ]),
    );
  }

  Widget _paymentOption(int index, String name, String code, String url) {
    final selected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: selected ? AppColors.primary.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant)),
        child: Row(children: [
          Radio(value: index, groupValue: _selectedPayment, activeColor: AppColors.primary, onChanged: (v) => setState(() => _selectedPayment = v!)),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(code, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }
}
