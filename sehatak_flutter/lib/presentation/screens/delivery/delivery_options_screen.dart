import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DeliveryOptionsScreen extends StatefulWidget {
  final double orderAmount;
  final String deliveryAddress;
  
  const DeliveryOptionsScreen({
    super.key,
    required this.orderAmount,
    this.deliveryAddress = 'صنعاء - شارع الزبيري',
  });

  @override
  State<DeliveryOptionsScreen> createState() => _DeliveryOptionsScreenState();
}

class _DeliveryOptionsScreenState extends State<DeliveryOptionsScreen> {
  int _selectedCompany = 0;
  int _selectedSpeed = 1; // 0=عادي، 1=سريع، 2=فوري
  
  final List<Map<String, dynamic>> _companies = [
    {
      'name': 'توصيل صحتك',
      'emoji': '🏍️',
      'color': AppColors.primary,
      'rating': 4.8,
      'reviews': 1250,
      'coverage': 'صنعاء، عدن، تعز، الحديدة',
      'insurance': true,
      'tracking': true,
      'codAvailable': true,
      'prices': {'normal': 500, 'express': 1000, 'instant': 2000},
      'time': {'normal': '2-3 أيام', 'express': '24 ساعة', 'instant': '2-4 ساعات'},
    },
    {
      'name': 'يمن إكسبريس',
      'emoji': '🚚',
      'color': AppColors.info,
      'rating': 4.5,
      'reviews': 890,
      'coverage': 'صنعاء، عدن، تعز',
      'insurance': false,
      'tracking': true,
      'codAvailable': true,
      'prices': {'normal': 400, 'express': 800, 'instant': 1800},
      'time': {'normal': '3-4 أيام', 'express': '36 ساعة', 'instant': '3-6 ساعات'},
    },
    {
      'name': 'سرعة',
      'emoji': '🛵',
      'color': AppColors.success,
      'rating': 4.6,
      'reviews': 650,
      'coverage': 'صنعاء فقط',
      'insurance': false,
      'tracking': true,
      'codAvailable': true,
      'prices': {'normal': 300, 'express': 600, 'instant': 1500},
      'time': {'normal': '1-2 أيام', 'express': '12 ساعة', 'instant': '1-2 ساعات'},
    },
    {
      'name': 'البريد اليمني',
      'emoji': '📮',
      'color': AppColors.warning,
      'rating': 3.8,
      'reviews': 3200,
      'coverage': 'جميع المحافظات',
      'insurance': true,
      'tracking': false,
      'codAvailable': false,
      'prices': {'normal': 200, 'express': 500, 'instant': null},
      'time': {'normal': '5-7 أيام', 'express': '2-3 أيام', 'instant': 'غير متاح'},
    },
  ];

  final List<Map<String, dynamic>> _speeds = [
    {'title': 'توصيل عادي', 'icon': '🐢', 'desc': 'الأرخص - يصل خلال 2-5 أيام'},
    {'title': 'توصيل سريع', 'icon': '🐇', 'desc': 'الأسرع - يصل خلال 12-36 ساعة'},
    {'title': 'توصيل فوري', 'icon': '🚀', 'desc': 'فوري - يصل خلال 1-6 ساعات'},
  ];

  String _getPrice() {
    final speed = ['normal', 'express', 'instant'][_selectedSpeed];
    final price = _companies[_selectedCompany]['prices'][speed];
    return price?.toString() ?? 'غير متاح';
  }

  String _getTime() {
    final speed = ['normal', 'express', 'instant'][_selectedSpeed];
    return _companies[_selectedCompany]['time'][speed] ?? 'غير متاح';
  }

  double _getTotal() {
    final deliveryPrice = int.tryParse(_getPrice()) ?? 0;
    return widget.orderAmount + deliveryPrice;
  }

  @override
  Widget build(BuildContext context) {
    final company = _companies[_selectedCompany];
    final deliveryPrice = _getPrice();
    final deliveryTime = _getTime();
    final total = _getTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('خيارات التوصيل', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ========== اختيار شركة التوصيل ==========
          const Text('اختر شركة التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('شركات توصيل موثوقة في اليمن', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 12),
          
          ...List.generate(_companies.length, (i) {
            final c = _companies[i];
            final sel = _selectedCompany == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedCompany = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? c['color'].withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? c['color'] : Colors.transparent, width: sel ? 2 : 0),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: c['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(c['emoji'], style: const TextStyle(fontSize: 26)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c['color'])),
                        if (c['insurance']) ...[
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('مؤمن', style: TextStyle(fontSize: 8, color: AppColors.success))),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        _starMini(c['rating']),
                        const SizedBox(width: 4),
                        Text('(${c['reviews']})', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                      ]),
                      Text('التغطية: ${c['coverage']}', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                    ])),
                    if (sel) Icon(Icons.check_circle, color: c['color'], size: 28),
                  ]),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _miniPrice(c, 'عادي', 'normal'),
                    _miniPrice(c, 'سريع', 'express'),
                    _miniPrice(c, 'فوري', 'instant'),
                  ]),
                ]),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ========== سرعة التوصيل ==========
          const Text('سرعة التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: List.generate(3, (i) {
            final sel = _selectedSpeed == i;
            final s = _speeds[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSpeed = i),
                child: Container(
                  margin: EdgeInsets.only(left: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.outlineVariant, width: sel ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(s['icon'], style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(s['title'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? AppColors.primary : AppColors.darkGrey)),
                    const SizedBox(height: 2),
                    Text(s['desc'], style: const TextStyle(fontSize: 9, color: AppColors.grey), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            );
          })),

          const SizedBox(height: 24),

          // ========== ملخص الطلب ==========
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _summaryRow('قيمة الطلب', '${widget.orderAmount} ر.ي'),
              _summaryRow('شركة التوصيل', company['name']),
              _summaryRow('سرعة التوصيل', _speeds[_selectedSpeed]['title']),
              _summaryRow('رسوم التوصيل', deliveryPrice == 'غير متاح' ? 'غير متاح' : '$deliveryPrice ر.ي'),
              _summaryRow('الوقت المتوقع', deliveryTime),
              if (company['codAvailable'] == true)
                Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.06), borderRadius: BorderRadius.circular(6)), child: const Row(children: [Icon(Icons.check, color: AppColors.success, size: 14), SizedBox(width: 4), Text('الدفع عند الاستلام متاح', style: TextStyle(fontSize: 10, color: AppColors.success))])),
              const Divider(height: 16),
              _summaryRow('الإجمالي النهائي', deliveryPrice == 'غير متاح' ? '${widget.orderAmount} ر.ي' : '$total ر.ي', bold: true, color: AppColors.primary),
            ]),
          ),

          const SizedBox(height: 20),

          // ========== عنوان التوصيل ==========
          const Text('عنوان التوصيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
            child: Row(children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المنزل', style: TextStyle(fontWeight: FontWeight.bold)), Text('صنعاء - شارع الزبيري - أمام مستشفى الثورة', style: TextStyle(fontSize: 11, color: AppColors.grey))])),
              TextButton(onPressed: () {}, child: const Text('تغيير')),
            ]),
          ),

          const SizedBox(height: 24),

          // ========== زر تأكيد الطلب ==========
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: deliveryPrice == 'غير متاح' ? null : () {
                Navigator.pop(context, {
                  'company': company['name'],
                  'speed': _speeds[_selectedSpeed]['title'],
                  'deliveryPrice': deliveryPrice,
                  'total': total,
                  'time': deliveryTime,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم تأكيد الطلب! التوصيل عبر ${company['name']} - $deliveryTime'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🚀', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('تأكيد الطلب وإتمام الدفع (${deliveryPrice == 'غير متاح' ? widget.orderAmount : total} ر.ي)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _miniPrice(Map<String, dynamic> c, String label, String key) {
    final price = c['prices'][key];
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey)),
      Text(price != null ? '$price ر.ي' : '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: price != null ? AppColors.primary : AppColors.grey)),
    ]);
  }

  Widget _starMini(double rating) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, color: AppColors.amber, size: 12), const SizedBox(width: 2), Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))]);
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
}
