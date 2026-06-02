import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class HealthShopScreen extends StatefulWidget {
  const HealthShopScreen({super.key});
  @override
  State<HealthShopScreen> createState() => _HealthShopScreenState();
}

class _HealthShopScreenState extends State<HealthShopScreen> {
  String _cat = 'الكل';
  int _cart = 0;

  final List<Map<String, dynamic>> _products = const [
    {'name': 'جهاز قياس ضغط', 'price': '8,500', 'cat': 'أجهزة', 'brand': 'Omron', 'rating': 4.8, 'img': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300'},
    {'name': 'جهاز قياس سكر', 'price': '6,200', 'cat': 'أجهزة', 'brand': 'Accu-Chek', 'rating': 4.7, 'img': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=300'},
    {'name': 'ميزان ذكي', 'price': '9,900', 'cat': 'أجهزة', 'brand': 'Xiaomi', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300'},
    {'name': 'مكملات بروتين', 'price': '4,500', 'cat': 'مكملات', 'brand': 'Optimum', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1622485831126-4b4f58abc8a6?w=300'},
    {'name': 'فيتامينات متعددة', 'price': '1,800', 'cat': 'مكملات', 'brand': 'Centrum', 'rating': 4.7, 'img': 'https://images.unsplash.com/photo-1585662040415-8a6b5dc52f50?w=300'},
    {'name': 'وسادة طبية', 'price': '3,200', 'cat': 'راحة', 'brand': 'Tempur', 'rating': 4.5, 'img': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=300'},
    {'name': 'جهاز بخار', 'price': '5,800', 'cat': 'أجهزة', 'brand': 'Philips', 'rating': 4.6, 'img': 'https://images.unsplash.com/photo-1585336261022-680e530ce3fe?w=300'},
    {'name': 'مساج كهربائي', 'price': '7,900', 'cat': 'راحة', 'brand': 'Beurer', 'rating': 4.7, 'img': 'https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=300'},
    {'name': 'جهاز تنفس', 'price': '12,500', 'cat': 'أجهزة', 'brand': 'ResMed', 'rating': 4.8, 'img': 'https://images.unsplash.com/photo-1583911860205-72f8ac8dee0e?w=300'},
    {'name': 'أوميغا 3', 'price': '2,200', 'cat': 'مكملات', 'brand': 'Nordic', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1577174881658-0f30ed549adc?w=300'},
    {'name': 'كرسي مساج', 'price': '25,000', 'cat': 'راحة', 'brand': 'Ogawa', 'rating': 4.6, 'img': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=300'},
    {'name': 'كمادات طبية', 'price': '900', 'cat': 'راحة', 'brand': '3M', 'rating': 4.4, 'img': 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=300'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _cat == 'الكل' ? _products : _products.where((p) => p['cat'] == _cat).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر الصحي', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [Stack(children: [IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {}), if (_cart > 0) Positioned(right: 4, top: 4, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle), child: Text('$_cart', style: const TextStyle(color: Colors.white, fontSize: 9))))])],
      ),
      body: Column(children: [
        SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 6), itemBuilder: (c, i) {
          final cats = ['الكل', 'أجهزة', 'مكملات', 'راحة'];
          return ChoiceChip(label: Text(cats[i], style: const TextStyle(fontSize: 10)), selected: _cat == cats[i], selectedColor: AppColors.primary, labelStyle: TextStyle(color: _cat == cats[i] ? Colors.white : null), onSelected: (v) => setState(() => _cat = v! ? cats[i] : 'الكل'));
        })),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: filtered.length,
            itemBuilder: (c, i) {
              final p = filtered[i];
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(p['img'], height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: AppColors.primary.withOpacity(0.08), child: const Center(child: Icon(Icons.medical_services, size: 40, color: AppColors.primary)))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['brand'], style: const TextStyle(fontSize: 9, color: AppColors.grey)),
                      Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 12), Text(' ${p['rating']}', style: const TextStyle(fontSize: 10))]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${p['price']} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                        GestureDetector(
                          onTap: () => setState(() => _cart++),
                          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16)),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
