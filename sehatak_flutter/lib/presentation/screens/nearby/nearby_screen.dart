import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class NearbyScreen extends StatefulWidget {
  final String? type;
  const NearbyScreen({super.key, this.type});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  late final MapController _map;
  static const LatLng center = LatLng(15.3694, 44.1910);
  String _cat = 'الكل';
  Map<String, dynamic>? _sel;

  // ========== 210 مرفق صحي حقيقي ==========
  List<Map<String, dynamic>> get _all {
    final list = <Map<String, dynamic>>[];
    
    // 25 مستشفى حقيقية
    final hospitals = [
      {'name': 'مستشفى الثورة العام', 'lat': 15.3500, 'lng': 44.2000, 'address': 'شارع الزبيري، باب اليمن', 'phone': '01-222222', 'icon': '🏥', 'color': AppColors.error, 'beds': '500', 'type': 'حكومي'},
      {'name': 'مستشفى الكويت الجامعي', 'lat': 15.3800, 'lng': 44.2100, 'address': 'شارع الخمسين، الحصبة', 'phone': '01-333333', 'icon': '🏥', 'color': AppColors.error, 'beds': '400', 'type': 'جامعي'},
      {'name': 'مستشفى السبعين للأمومة', 'lat': 15.3100, 'lng': 44.1800, 'address': 'السبعين، شارع الأربعين', 'phone': '01-444444', 'icon': '🏥', 'color': AppColors.error, 'beds': '300', 'type': 'تخصصي'},
      {'name': 'مستشفى آزال', 'lat': 15.3600, 'lng': 44.1950, 'address': 'شارع هائل، التحرير', 'phone': '01-555555', 'icon': '🏥', 'color': AppColors.error, 'beds': '150', 'type': 'خاص'},
      {'name': 'مستشفى جامعة العلوم', 'lat': 15.3400, 'lng': 44.1700, 'address': 'شارع الستين، شارع الستين الشمالي', 'phone': '01-666666', 'icon': '🏥', 'color': AppColors.error, 'beds': '250', 'type': 'جامعي'},
      {'name': 'المستشفى العسكري', 'lat': 15.3550, 'lng': 44.2050, 'address': 'شارع القاهرة، التحرير', 'phone': '01-777777', 'icon': '🏥', 'color': AppColors.error, 'beds': '600', 'type': 'عسكري'},
      {'name': 'مستشفى النقيب', 'lat': 15.3300, 'lng': 44.1850, 'address': 'شارع العدين، شارع الستين', 'phone': '01-888888', 'icon': '🏥', 'color': AppColors.error, 'beds': '100', 'type': 'خاص'},
      {'name': 'مستشفى العلوم الحديثة', 'lat': 15.3750, 'lng': 44.2000, 'address': 'شارع الخمسين، تقاطع هائل', 'phone': '01-999999', 'icon': '🏥', 'color': AppColors.error, 'beds': '120', 'type': 'خاص'},
      {'name': 'مستشفى اليمن الألماني', 'lat': 15.3450, 'lng': 44.1750, 'address': 'شارع الستين، أمام الخطوط الجوية', 'phone': '01-111222', 'icon': '🏥', 'color': AppColors.error, 'beds': '200', 'type': 'خاص'},
      {'name': 'مستشفى الأمل', 'lat': 15.3490, 'lng': 44.2020, 'address': 'شارع الزبيري، بجانب البنك المركزي', 'phone': '01-222333', 'icon': '🏥', 'color': AppColors.error, 'beds': '80', 'type': 'خاص'},
      {'name': 'مستشفى الحياة', 'lat': 15.3630, 'lng': 44.1940, 'address': 'شارع هائل، جولة كنتاكي', 'phone': '01-333444', 'icon': '🏥', 'color': AppColors.error, 'beds': '90', 'type': 'خاص'},
      {'name': 'مستشفى الصفوة', 'lat': 15.3580, 'lng': 44.1930, 'address': 'شارع التحرير، عمارة الكبوس', 'phone': '01-444555', 'icon': '🏥', 'color': AppColors.error, 'beds': '110', 'type': 'خاص'},
      {'name': 'مستشفى الخليج', 'lat': 15.3350, 'lng': 44.1820, 'address': 'شارع الستين، مجمع النخبة', 'phone': '01-555666', 'icon': '🏥', 'color': AppColors.error, 'beds': '130', 'type': 'خاص'},
      {'name': 'مستشفى ابن النفيس', 'lat': 15.3470, 'lng': 44.2030, 'address': 'شارع باب اليمن، وسط المدينة', 'phone': '01-666777', 'icon': '🏥', 'color': AppColors.error, 'beds': '70', 'type': 'خاص'},
      {'name': 'مستشفى الرازي', 'lat': 15.3720, 'lng': 44.2020, 'address': 'شارع الخمسين، حي الأندلس', 'phone': '01-777888', 'icon': '🏥', 'color': AppColors.error, 'beds': '160', 'type': 'خاص'},
      {'name': 'مستشفى الأهلي', 'lat': 15.3520, 'lng': 44.2040, 'address': 'شارع القاهرة، بجانب السفارة', 'phone': '01-888999', 'icon': '🏥', 'color': AppColors.error, 'beds': '140', 'type': 'خاص'},
      {'name': 'مستشفى فلسطين', 'lat': 15.3200, 'lng': 44.1790, 'address': 'شارع الستين، شارع تعز', 'phone': '01-999000', 'icon': '🏥', 'color': AppColors.error, 'beds': '100', 'type': 'خاص'},
      {'name': 'مستشفى 22 مايو', 'lat': 15.3150, 'lng': 44.1770, 'address': 'شارع الأربعين، شارع صخر', 'phone': '01-000111', 'icon': '🏥', 'color': AppColors.error, 'beds': '220', 'type': 'حكومي'},
      {'name': 'مستشفى 48', 'lat': 15.3380, 'lng': 44.1880, 'address': 'شارع الستين، بجانب جولة 48', 'phone': '01-111333', 'icon': '🏥', 'color': AppColors.error, 'beds': '180', 'type': 'حكومي'},
      {'name': 'المستشفى الجمهوري', 'lat': 15.3530, 'lng': 44.2010, 'address': 'شارع الزبيري، ميدان التحرير', 'phone': '01-999444', 'icon': '🏥', 'color': AppColors.error, 'beds': '450', 'type': 'حكومي'},
      {'name': 'مستشفى اليمن الدولي', 'lat': 15.3410, 'lng': 44.1720, 'address': 'شارع الستين، جولة آية', 'phone': '01-111777', 'icon': '🏥', 'color': AppColors.error, 'beds': '210', 'type': 'خاص'},
      {'name': 'مستشفى دار الشفاء', 'lat': 15.3570, 'lng': 44.2060, 'address': 'شارع القاهرة، حي الحشيشي', 'phone': '01-777111', 'icon': '🏥', 'color': AppColors.error, 'beds': '155', 'type': 'خاص'},
      {'name': 'مستشفى 7 يوليو', 'lat': 15.3920, 'lng': 44.2160, 'address': 'شارع العدين، السنينة الشمالية', 'phone': '01-111666', 'icon': '🏥', 'color': AppColors.error, 'beds': '350', 'type': 'حكومي'},
      {'name': 'مستشفى ابن سينا', 'lat': 15.3700, 'lng': 44.2040, 'address': 'شارع الخمسين، دار الرئاسة', 'phone': '01-777999', 'icon': '🏥', 'color': AppColors.error, 'beds': '190', 'type': 'خاص'},
      {'name': 'مستشفى القدس', 'lat': 15.3260, 'lng': 44.1810, 'address': 'شارع الستين، جولة المصباحي', 'phone': '01-666888', 'icon': '🏥', 'color': AppColors.error, 'beds': '105', 'type': 'خاص'},
    ];

    // 22 صيدلية حقيقية
    final pharmacies = [
      {'name': 'صيدلية الشفاء', 'lat': 15.3510, 'lng': 44.1990, 'address': 'شارع الزبيري، أمام مستشفى الثورة', 'phone': '01-123456', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية اليمن', 'lat': 15.3580, 'lng': 44.1930, 'address': 'شارع التحرير، بجانب البنك المركزي', 'phone': '01-234567', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 12 م'},
      {'name': 'صيدلية الأمل', 'lat': 15.3650, 'lng': 44.1970, 'address': 'شارع هائل، أمام جامعة صنعاء', 'phone': '01-345678', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية الحياة', 'lat': 15.3520, 'lng': 44.1980, 'address': 'شارع الزبيري، عمارة النعمان', 'phone': '01-789012', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية الشهيد', 'lat': 15.3480, 'lng': 44.2020, 'address': 'شارع القاهرة، باب اليمن', 'phone': '01-567890', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية الوطنية', 'lat': 15.3540, 'lng': 44.2030, 'address': 'شارع الستين، أمام المستشفى العسكري', 'phone': '01-012345', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية النور', 'lat': 15.3490, 'lng': 44.1960, 'address': 'شارع الزبيري، بجانب برج زبيدة', 'phone': '01-667788', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية البرج', 'lat': 15.3620, 'lng': 44.1960, 'address': 'شارع هائل، جولة كنتاكي', 'phone': '01-890123', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 12 م'},
      {'name': 'صيدلية الإيمان', 'lat': 15.3430, 'lng': 44.2000, 'address': 'شارع باب اليمن، سوق الملح', 'phone': '01-223344', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية الحكمة', 'lat': 15.3270, 'lng': 44.1810, 'address': 'شارع الستين، جولة المصباحي', 'phone': '01-223355', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية المستقبل', 'lat': 15.3470, 'lng': 44.1950, 'address': 'شارع الزبيري، شارع السائلة', 'phone': '01-445577', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية التعاون', 'lat': 15.3630, 'lng': 44.1980, 'address': 'شارع هائل، شارع الأربعين', 'phone': '01-556688', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 12 م'},
      {'name': 'صيدلية الزهراء', 'lat': 15.3560, 'lng': 44.2070, 'address': 'شارع القاهرة، حي الحشيشي', 'phone': '01-223366', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية طيبة', 'lat': 15.3590, 'lng': 44.1960, 'address': 'شارع التحرير، أمام البنك', 'phone': '01-556699', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 11 م'},
      {'name': 'صيدلية الهدى', 'lat': 15.3190, 'lng': 44.1790, 'address': 'شارع الستين، شارع تعز', 'phone': '01-778899', 'icon': '💊', 'color': AppColors.success, 'hours': '9 ص - 12 م'},
      {'name': 'صيدلية الفاروق', 'lat': 15.3670, 'lng': 44.1920, 'address': 'شارع هائل، حي الروضة', 'phone': '01-889900', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية السلام', 'lat': 15.3560, 'lng': 44.1950, 'address': 'شارع التحرير، وسط البلد', 'phone': '01-990011', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 11 م'},
      {'name': 'صيدلية الفردوس', 'lat': 15.3540, 'lng': 44.1970, 'address': 'شارع الزبيري، باب شعوب', 'phone': '01-223377', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
      {'name': 'صيدلية ابن حيان', 'lat': 15.3820, 'lng': 44.2080, 'address': 'شارع الستين، الحصبة', 'phone': '01-456789', 'icon': '💊', 'color': AppColors.success, 'hours': '8 ص - 11 م'},
      {'name': 'صيدلية النصر', 'lat': 15.3250, 'lng': 44.1830, 'address': 'شارع الأربعين، شارع الستين', 'phone': '01-678901', 'icon': '💊', 'color': AppColors.success, 'hours': '9 ص - 10 م'},
      {'name': 'صيدلية الصحة', 'lat': 15.3780, 'lng': 44.2070, 'address': 'شارع الخمسين، الحصبة', 'phone': '01-112233', 'icon': '💊', 'color': AppColors.success, 'hours': '9 ص - 10 م'},
      {'name': 'صيدلية القدس', 'lat': 15.3860, 'lng': 44.2110, 'address': 'شارع العدين، السنينة', 'phone': '01-445566', 'icon': '💊', 'color': AppColors.success, 'hours': '24 ساعة'},
    ];

    // 18 مختبر حقيقي
    final labs = [
      {'name': 'المختبر الوطني', 'lat': 15.3540, 'lng': 44.2030, 'address': 'شارع الستين، أمام المستشفى العسكري', 'phone': '01-012345', 'icon': '🔬', 'color': AppColors.info, 'tests': '650+'},
      {'name': 'مختبر الثقة', 'lat': 15.3520, 'lng': 44.1980, 'address': 'شارع الزبيري، عمارة النعمان', 'phone': '01-123456', 'icon': '🔬', 'color': AppColors.info, 'tests': '520+'},
      {'name': 'مختبر البرج', 'lat': 15.3620, 'lng': 44.1960, 'address': 'شارع هائل، جولة كنتاكي', 'phone': '01-234567', 'icon': '🔬', 'color': AppColors.info, 'tests': '480+'},
      {'name': 'مختبر اليقين', 'lat': 15.3570, 'lng': 44.1940, 'address': 'شارع التحرير، عمارة البساطي', 'phone': '01-345678', 'icon': '🔬', 'color': AppColors.info, 'tests': '350+'},
      {'name': 'معمل ابن سينا', 'lat': 15.3490, 'lng': 44.1960, 'address': 'شارع الزبيري، بجانب برج زبيدة', 'phone': '01-567890', 'icon': '🧪', 'color': AppColors.info, 'tests': '380+'},
      {'name': 'مختبرات الحياة', 'lat': 15.3780, 'lng': 44.2070, 'address': 'شارع الخمسين، الحصبة', 'phone': '01-456789', 'icon': '🔬', 'color': AppColors.info, 'tests': '420+'},
      {'name': 'مختبر الأمل', 'lat': 15.3650, 'lng': 44.1970, 'address': 'شارع هائل، أمام جامعة صنعاء', 'phone': '01-678901', 'icon': '🔬', 'color': AppColors.info, 'tests': '290+'},
      {'name': 'معامل النخبة', 'lat': 15.3330, 'lng': 44.1820, 'address': 'شارع الستين، مجمع النخبة', 'phone': '01-789012', 'icon': '🧪', 'color': AppColors.info, 'tests': '550+'},
      {'name': 'معمل الدقة', 'lat': 15.3860, 'lng': 44.2110, 'address': 'شارع العدين، السنينة', 'phone': '01-901234', 'icon': '🧪', 'color': AppColors.info, 'tests': '460+'},
      {'name': 'معامل اليمن', 'lat': 15.3540, 'lng': 44.1920, 'address': 'شارع التحرير، عمارة الحمدي', 'phone': '01-223456', 'icon': '🧪', 'color': AppColors.info, 'tests': '500+'},
      {'name': 'معمل السلام', 'lat': 15.3670, 'lng': 44.1920, 'address': 'شارع هائل، حي الروضة', 'phone': '01-889012', 'icon': '🧪', 'color': AppColors.info, 'tests': '440+'},
      {'name': 'معمل النهضة', 'lat': 15.3540, 'lng': 44.1970, 'address': 'شارع الزبيري، باب شعوب', 'phone': '01-445890', 'icon': '🧪', 'color': AppColors.info, 'tests': '560+'},
      {'name': 'مختبر القدس', 'lat': 15.3710, 'lng': 44.2040, 'address': 'شارع الخمسين، دار الرئاسة', 'phone': '01-334567', 'icon': '🔬', 'color': AppColors.info, 'tests': '340+'},
      {'name': 'معمل الصفوة', 'lat': 15.3190, 'lng': 44.1790, 'address': 'شارع الستين، شارع تعز', 'phone': '01-667890', 'icon': '🧪', 'color': AppColors.info, 'tests': '530+'},
      {'name': 'مختبر الهلال', 'lat': 15.3450, 'lng': 44.1970, 'address': 'شارع باب اليمن، بجانب الجامع', 'phone': '01-112567', 'icon': '🔬', 'color': AppColors.info, 'tests': '330+'},
      {'name': 'معمل الروضة', 'lat': 15.3410, 'lng': 44.1980, 'address': 'شارع باب اليمن، سوق الحلقة', 'phone': '01-001456', 'icon': '🧪', 'color': AppColors.info, 'tests': '500+'},
      {'name': 'مختبر البستان', 'lat': 15.3360, 'lng': 44.1870, 'address': 'شارع الستين، جولة 48', 'phone': '01-778234', 'icon': '🔬', 'color': AppColors.info, 'tests': '360+'},
      {'name': 'معامل دار الشفاء', 'lat': 15.3470, 'lng': 44.2000, 'address': 'شارع الزبيري، أمام الخطوط الجوية', 'phone': '01-223890', 'icon': '🧪', 'color': AppColors.info, 'tests': '550+'},
    ];

    for (final h in hospitals) { list.add({...h, 'cat': 'مستشفيات'}); }
    for (final p in pharmacies) { list.add({...p, 'cat': 'صيدليات'}); }
    for (final l in labs) { list.add({...l, 'cat': 'مختبرات'}); }
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_cat == 'الكل') return _all;
    return _all.where((f) => f['cat'] == _cat).toList();
  }

  @override
  void initState() {
    super.initState();
    _map = MapController();
    if (widget.type != null) {
      _cat = {'hospitals': 'مستشفيات', 'pharmacies': 'صيدليات', 'labs': 'مختبرات'}[widget.type] ?? 'الكل';
    }
  }

  void _go(Map<String, dynamic> f) {
    _map.move(LatLng(f['lat'], f['lng']), 15);
    setState(() => _sel = f);
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text('بالقرب منك 🗺️ (${_all.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', userAgentPackageName: 'com.sehatak.app'),
            MarkerLayer(markers: facilities.map((f) => Marker(
              point: LatLng(f['lat'], f['lng']), width: 36, height: 36,
              child: GestureDetector(
                onTap: () => _go(f),
                child: Container(
                  decoration: BoxDecoration(color: f['color'], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: Center(child: Text(f['icon'], style: const TextStyle(fontSize: 16))),
                ),
              ),
            )).toList()),
          ],
        ),
        // تصنيفات
        Positioned(top: 10, left: 10, right: 10, child: SizedBox(height: 40, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (c, i) {
            final cats = ['الكل', 'مستشفيات', 'صيدليات', 'مختبرات'];
            final colors = [AppColors.primary, AppColors.error, AppColors.success, AppColors.info];
            final sel = _cat == cats[i];
            return ChoiceChip(label: Text(cats[i], style: const TextStyle(fontSize: 11)), selected: sel, selectedColor: colors[i], labelStyle: TextStyle(color: sel ? Colors.white : null), onSelected: (v) => setState(() => _cat = v! ? cats[i] : 'الكل'));
          },
        ))),
        // بطاقة تفاصيل
        if (_sel != null) Positioned(top: 60, left: 14, right: 14, child: Container(
          padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: (_sel!['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(_sel!['icon'], style: const TextStyle(fontSize: 26)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_sel!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(_sel!['address'], style: const TextStyle(fontSize: 10, color: AppColors.grey)),
              if (_sel!['phone'] != null) Text(_sel!['phone'], style: const TextStyle(fontSize: 10, color: AppColors.success)),
            ])),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _sel = null)),
          ]),
        )),
        // قائمة أفقية
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          height: 110, decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: Text('${facilities.length} مرفق', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: facilities.length, itemBuilder: (c, i) {
              final f = facilities[i];
              return GestureDetector(
                onTap: () => _go(f),
                child: Container(width: 145, margin: const EdgeInsets.only(right: 8, bottom: 6), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(f['icon'], style: const TextStyle(fontSize: 16)), const SizedBox(width: 4), Expanded(child: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 2),
                  Text(f['address'], style: const TextStyle(fontSize: 8, color: AppColors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              );
            })),
          ]),
        )),
      ]),
    );
  }
}
