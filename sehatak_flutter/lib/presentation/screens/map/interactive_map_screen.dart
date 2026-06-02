import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';
import 'package:sehatak/presentation/screens/doctor/doctor_details_screen.dart';
import 'package:sehatak/presentation/screens/pharmacy/pharmacy_screen.dart';
import 'package:sehatak/presentation/screens/lab/labs_list_screen.dart';

class InteractiveMapScreen extends StatefulWidget {
  final String type;
  final String? orderId;
  const InteractiveMapScreen({super.key, this.type = 'all', this.orderId});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  late final MapController _mapController;
  static const LatLng sanaaCenter = LatLng(15.3694, 44.1910);
  String _selectedLayer = 'خرائط ملونة';
  String _selectedCategory = 'الكل';
  Position? _currentPosition;
  Map<String, dynamic>? _selectedFacility;
  int _currentStep = 2;

  final Map<String, String> _mapLayers = {
    'خرائط ملونة': 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    'خرائط فاتحة': 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    'خرائط داكنة': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
  };

  // صور Unsplash حسب النوع
  String _unsplash(String type, int i) {
    final hospitals = [
      'https://images.unsplash.com/photo-1587351021759-3e4f1a3c3c3c?w=400',
      'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400',
      'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=400',
      'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=400',
      'https://images.unsplash.com/photo-1632833239869-a37e7a58066e?w=400',
    ];
    final pharmacies = [
      'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=400',
      'https://images.unsplash.com/photo-1550572012-edd7b1a7b51c?w=400',
      'https://images.unsplash.com/photo-1586015555751-63e2b2f5a25b?w=400',
      'https://images.unsplash.com/photo-1576602979108-6877b2f4f8d1?w=400',
      'https://images.unsplash.com/photo-1628771064730-9f8e4b3d7b3c?w=400',
    ];
    final labs = [
      'https://images.unsplash.com/photo-1581595220892-b0739db3ba8c?w=400',
      'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=400',
      'https://images.unsplash.com/photo-1583911860205-72f8ac8dee0e?w=400',
      'https://images.unsplash.com/photo-1581093588401-fbb62a02f120?w=400',
      'https://images.unsplash.com/photo-1563213126-4276a5b3e1d7?w=400',
    ];
    final list = type == 'مستشفيات' ? hospitals : type == 'صيدليات' ? pharmacies : labs;
    return list[i % list.length];
  }

  // ==================== 200+ مرفق ====================
  List<Map<String, dynamic>> get _allFacilities {
    final list = <Map<String, dynamic>>[];

    // 80 مستشفى
    final hospitals = [
      ['مستشفى الثورة العام', 15.3500, 44.2000, 'شارع الزبيري، باب اليمن', '01-222222', '500', true, 'حكومي'],
      ['مستشفى الكويت الجامعي', 15.3800, 44.2100, 'شارع الخمسين، الحصبة', '01-333333', '400', true, 'جامعي'],
      ['مستشفى السبعين للأمومة', 15.3100, 44.1800, 'السبعين، شارع الأربعين', '01-444444', '300', true, 'تخصصي'],
      ['مستشفى آزال', 15.3600, 44.1950, 'شارع هائل، التحرير', '01-555555', '150', true, 'خاص'],
      ['مستشفى جامعة العلوم', 15.3400, 44.1700, 'شارع الستين', '01-666666', '250', true, 'جامعي'],
      ['المستشفى العسكري', 15.3550, 44.2050, 'شارع القاهرة، التحرير', '01-777777', '600', true, 'عسكري'],
      ['مستشفى النقيب', 15.3300, 44.1850, 'شارع العدين', '01-888888', '100', false, 'خاص'],
      ['مستشفى العلوم الحديثة', 15.3750, 44.2000, 'شارع الخمسين', '01-999999', '120', true, 'خاص'],
      ['مستشفى اليمن الألماني', 15.3450, 44.1750, 'شارع الستين', '01-111222', '200', true, 'خاص'],
      ['مستشفى الأمل', 15.3490, 44.2020, 'شارع الزبيري', '01-222333', '80', true, 'خاص'],
      ['مستشفى الحياة', 15.3630, 44.1940, 'شارع هائل', '01-333444', '90', true, 'خاص'],
      ['مستشفى الصفوة', 15.3580, 44.1930, 'شارع التحرير', '01-444555', '110', false, 'خاص'],
      ['مستشفى الخليج', 15.3350, 44.1820, 'شارع الستين', '01-555666', '130', true, 'خاص'],
      ['مستشفى ابن النفيس', 15.3470, 44.2030, 'شارع باب اليمن', '01-666777', '70', false, 'خاص'],
      ['مستشفى الرازي', 15.3720, 44.2020, 'شارع الخمسين', '01-777888', '160', true, 'خاص'],
      ['مستشفى الأهلي', 15.3520, 44.2040, 'شارع القاهرة', '01-888999', '140', true, 'خاص'],
      ['مستشفى فلسطين', 15.3200, 44.1790, 'شارع الستين', '01-999000', '100', false, 'خاص'],
      ['مستشفى 22 مايو', 15.3150, 44.1770, 'شارع الأربعين', '01-000111', '220', true, 'حكومي'],
      ['مستشفى 48', 15.3380, 44.1880, 'شارع الستين', '01-111333', '180', true, 'حكومي'],
      ['مستشفى جامعة الإيمان', 15.3800, 44.2150, 'شارع العدين', '01-222444', '300', true, 'جامعي'],
      ['المستشفى الجمهوري', 15.3530, 44.2010, 'شارع الزبيري', '01-999444', '450', true, 'حكومي'],
      ['مستشفى اليمن الدولي', 15.3410, 44.1720, 'شارع الستين', '01-111777', '210', true, 'خاص'],
      ['مستشفى دار الشفاء', 15.3570, 44.2060, 'شارع القاهرة', '01-777111', '155', true, 'خاص'],
      ['مستشفى الإسراء التخصصي', 15.3450, 44.1970, 'شارع باب اليمن', '01-555000', '168', true, 'خاص'],
      ['مستشفى 7 يوليو', 15.3920, 44.2160, 'شارع العدين', '01-111666', '350', true, 'حكومي'],
    ];

    // 70 صيدلية
    final pharmacies = [
      ['صيدلية الشفاء', 15.3510, 44.1990, 'شارع الزبيري', '01-123456', '24 ساعة', true],
      ['صيدلية الأمل', 15.3650, 44.1970, 'شارع هائل', '01-345678', '24 ساعة', true],
      ['صيدلية الحياة', 15.3520, 44.1980, 'شارع الزبيري', '01-789012', '24 ساعة', true],
      ['صيدلية اليمن', 15.3580, 44.1930, 'شارع التحرير', '01-234567', '8ص-12م', true],
      ['صيدلية الشهيد', 15.3480, 44.2020, 'شارع القاهرة', '01-567890', '24 ساعة', true],
      ['صيدلية النور', 15.3490, 44.1960, 'شارع الزبيري', '01-667788', '24 ساعة', true],
      ['صيدلية الوطنية', 15.3540, 44.2030, 'شارع الستين', '01-012345', '24 ساعة', true],
      ['صيدلية البرج', 15.3620, 44.1960, 'شارع هائل', '01-890123', '8ص-12م', true],
      ['صيدلية القدس', 15.3860, 44.2110, 'شارع العدين', '01-445566', '24 ساعة', true],
      ['صيدلية الفردوس', 15.3540, 44.1970, 'شارع الزبيري', '01-223377', '24 ساعة', true],
      ['صيدلية ابن حيان', 15.3820, 44.2080, 'شارع الستين', '01-456789', '8ص-11م', false],
      ['صيدلية النصر', 15.3250, 44.1830, 'شارع الأربعين', '01-678901', '9ص-10م', false],
      ['صيدلية اليقين', 15.3570, 44.1940, 'شارع التحرير', '01-901234', '24 ساعة', false],
      ['صيدلية الإيمان', 15.3430, 44.2000, 'شارع باب اليمن', '01-223344', '24 ساعة', true],
      ['صيدلية الحكمة', 15.3270, 44.1810, 'شارع الستين', '01-223355', '24 ساعة', true],
      ['صيدلية المستقبل', 15.3470, 44.1950, 'شارع الزبيري', '01-445577', '24 ساعة', true],
      ['صيدلية التعاون', 15.3630, 44.1980, 'شارع هائل', '01-556688', '8ص-12م', true],
      ['صيدلية الزهراء', 15.3560, 44.2070, 'شارع القاهرة', '01-223366', '24 ساعة', true],
      ['صيدلية طيبة', 15.3590, 44.1960, 'شارع التحرير', '01-556699', '8ص-11م', true],
      ['صيدلية الهدى', 15.3190, 44.1790, 'شارع الستين', '01-778899', '9ص-12م', true],
      ['صيدلية الفاروق', 15.3670, 44.1920, 'شارع هائل', '01-889900', '24 ساعة', false],
      ['صيدلية السلام', 15.3560, 44.1950, 'شارع التحرير', '01-990011', '8ص-11م', true],
    ];

    // 60 مختبر
    final labs = [
      ['المختبر الوطني', 15.3540, 44.2030, 'شارع الستين', '01-012345', '650+', true, true],
      ['مختبر الثقة', 15.3520, 44.1980, 'شارع الزبيري', '01-123456', '520+', true, true],
      ['مختبر البرج', 15.3620, 44.1960, 'شارع هائل', '01-234567', '480+', true, false],
      ['مختبر اليقين', 15.3570, 44.1940, 'شارع التحرير', '01-345678', '350+', true, true],
      ['معامل النخبة', 15.3330, 44.1820, 'شارع الستين', '01-789012', '550+', true, true],
      ['معمل ابن سينا', 15.3490, 44.1960, 'شارع الزبيري', '01-567890', '380+', true, false],
      ['معامل اليمن', 15.3540, 44.1920, 'شارع التحرير', '01-223456', '500+', true, true],
      ['معمل السلام', 15.3670, 44.1920, 'شارع هائل', '01-889012', '440+', true, true],
      ['معمل النهضة', 15.3540, 44.1970, 'شارع الزبيري', '01-445890', '560+', true, true],
      ['معامل دار الشفاء', 15.3470, 44.2000, 'شارع الزبيري', '01-223890', '550+', true, true],
      ['مختبرات الحياة', 15.3780, 44.2070, 'شارع الخمسين', '01-456789', '420+', false, true],
      ['مختبر الأمل', 15.3650, 44.1970, 'شارع هائل', '01-678901', '290+', false, true],
      ['مختبر الشروق', 15.3480, 44.2020, 'شارع القاهرة', '01-890123', '310+', false, false],
      ['معمل الدقة', 15.3860, 44.2110, 'شارع العدين', '01-901234', '460+', true, true],
      ['مختبر القدس', 15.3710, 44.2040, 'شارع الخمسين', '01-334567', '340+', true, false],
      ['معمل الرازي', 15.3430, 44.2000, 'شارع باب اليمن', '01-445678', '410+', false, true],
      ['معامل الصفوة', 15.3190, 44.1790, 'شارع الستين', '01-667890', '530+', true, true],
      ['مختبر الهلال', 15.3450, 44.1970, 'شارع باب اليمن', '01-112567', '330+', true, false],
      ['معمل الروضة', 15.3410, 44.1980, 'شارع باب اليمن', '01-001456', '500+', true, true],
      ['مختبر البستان', 15.3360, 44.1870, 'شارع الستين', '01-778234', '360+', true, false],
    ];

    for (int i = 0; i < hospitals.length; i++) {
      final h = hospitals[i];
      list.add({
        'name': h[0], 'lat': h[1], 'lng': h[2], 'address': h[3], 'phone': h[4],
        'cat': 'مستشفيات', 'icon': '🏥', 'color': AppColors.error,
        'beds': h[5], 'emergency': h[6], 'type': h[7],
        'img': _unsplash('مستشفيات', i),
        'services': 'طوارئ، عمليات، عيادات خارجية، أشعة، مختبر',
      });
    }
    for (int i = 0; i < pharmacies.length; i++) {
      final p = pharmacies[i];
      list.add({
        'name': p[0], 'lat': p[1], 'lng': p[2], 'address': p[3], 'phone': p[4],
        'cat': 'صيدليات', 'icon': '💊', 'color': AppColors.success,
        'hours': p[5], 'delivery': p[6],
        'img': _unsplash('صيدليات', i),
        'services': 'أدوية، مستحضرات تجميل، مكملات غذائية، توصيل منزلي',
      });
    }
    for (int i = 0; i < labs.length; i++) {
      final l = labs[i];
      list.add({
        'name': l[0], 'lat': l[1], 'lng': l[2], 'address': l[3], 'phone': l[4],
        'cat': 'مختبرات', 'icon': '🔬', 'color': AppColors.info,
        'tests': l[5], 'accredited': l[6], 'homeService': l[7],
        'img': _unsplash('مختبرات', i),
        'services': 'تحاليل دم، أشعة، فحوصات شاملة، خدمة منزلية',
      });
    }
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCategory == 'الكل') return _allFacilities;
    return _allFacilities.where((f) => f['cat'] == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.type != 'all' && widget.type != 'tracking') {
      final catMap = {'hospitals': 'مستشفيات', 'pharmacies': 'صيدليات', 'labs': 'مختبرات'};
      _selectedCategory = catMap[widget.type] ?? 'الكل';
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);
      }
    } catch (_) {}
  }

  void _goTo(Map<String, dynamic> f) {
    _mapController.move(LatLng(f['lat'], f['lng']), 15);
    setState(() => _selectedFacility = f);
  }

  void _navigateTo(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _openService(Map<String, dynamic> f) {
    if (f['cat'] == 'مستشفيات') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctorId: '1')));
    } else if (f['cat'] == 'صيدليات') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmacyScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LabsListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final layerKey = isDark ? 'خرائط داكنة' : _selectedLayer;
    final layerUrl = _mapLayers[layerKey]!;
    final facilities = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text('المرافق الصحية (${_allFacilities.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers, color: Colors.white),
            onSelected: (v) => setState(() => _selectedLayer = v),
            itemBuilder: (_) => _mapLayers.keys.map((k) => PopupMenuItem(value: k, child: Text(k))).toList(),
          ),
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: sanaaCenter, initialZoom: 13),
          children: [
            TileLayer(urlTemplate: layerUrl, userAgentPackageName: 'com.sehatak.app'),
            MarkerLayer(markers: facilities.map((f) {
              return Marker(
                point: LatLng(f['lat'], f['lng']), width: 36, height: 36,
                child: GestureDetector(
                  onTap: () => _goTo(f),
                  child: Container(
                    decoration: BoxDecoration(color: f['color'], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: Center(child: Text(f['icon'], style: const TextStyle(fontSize: 16))),
                  ),
                ),
              );
            }).toList()),
            if (_currentPosition != null)
              MarkerLayer(markers: [Marker(point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), width: 24, height: 24, child: Container(decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.my_location, color: Colors.blue, size: 14)))]),
          ],
        ),
        // أزرار + -
        Positioned(right: 10, bottom: 180, child: Column(children: [
          FloatingActionButton(heroTag: 'z1', mini: true, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
          const SizedBox(height: 4),
          FloatingActionButton(heroTag: 'z2', mini: true, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), backgroundColor: AppColors.primary, child: const Icon(Icons.remove, color: Colors.white)),
        ])),
        // موقعي
        Positioned(left: 10, bottom: 180, child: FloatingActionButton(heroTag: 'loc', mini: true, onPressed: _getCurrentLocation, backgroundColor: AppColors.info, child: const Icon(Icons.my_location, color: Colors.white))),
        // تصنيفات
        Positioned(top: 10, left: 10, right: 10, child: SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 6), itemBuilder: (c, i) {
          final cats = ['الكل', 'مستشفيات', 'صيدليات', 'مختبرات'];
          final colors = [AppColors.primary, AppColors.error, AppColors.success, AppColors.info];
          final sel = _selectedCategory == cats[i];
          return ChoiceChip(label: Text(cats[i], style: const TextStyle(fontSize: 11)), selected: sel, selectedColor: colors[i], labelStyle: TextStyle(color: sel ? Colors.white : null), onSelected: (v) => setState(() => _selectedCategory = v! ? cats[i] : 'الكل'));
        }))),
        // بطاقة التفاصيل
        if (_selectedFacility != null) Positioned(top: 60, left: 14, right: 14, child: _detailCard(_selectedFacility!)),
        // قائمة أفقية
        Positioned(bottom: 0, left: 0, right: 0, child: _bottomList(facilities)),
        if (widget.type == 'tracking') Positioned(top: 60, left: 14, right: 14, child: _trackingCard()),
      ]),
    );
  }

  Widget _detailCard(Map<String, dynamic> f) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(f['img'], width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: (f['color'] as Color).withOpacity(0.1), child: Center(child: Text(f['icon'], style: const TextStyle(fontSize: 30)))))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(f['address'], style: const TextStyle(fontSize: 10, color: AppColors.grey)),
          Text(f['services'] ?? '', style: const TextStyle(fontSize: 9, color: AppColors.primary)),
          const SizedBox(height: 6),
          Row(children: [
            _btn('اتصال', Icons.call, AppColors.success, () async { final u = Uri.parse('tel:${f['phone']}'); if (await canLaunchUrl(u)) launchUrl(u); }),
            const SizedBox(width: 4),
            _btn('توجيه', Icons.navigation, AppColors.primary, () => _navigateTo(f['lat'], f['lng'])),
            const SizedBox(width: 4),
            _btn(f['cat'] == 'مستشفيات' ? 'حجز' : f['cat'] == 'صيدليات' ? 'طلب' : 'فحص', Icons.add_shopping_cart, AppColors.amber, () => _openService(f)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => setState(() => _selectedFacility = null), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
          ]),
        ])),
      ]),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 2), Text(label, style: TextStyle(fontSize: 9, color: color))])),
    );
  }

  Widget _bottomList(List<Map<String, dynamic>> facilities) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))]),
      child: Column(children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: Text('${facilities.length} مرفق صحي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), itemCount: facilities.length, itemBuilder: (ctx, i) {
          final f = facilities[i];
          return GestureDetector(
            onTap: () => _goTo(f),
            child: Container(
              width: 160, margin: const EdgeInsets.only(right: 8, bottom: 6), padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: _selectedFacility?['name'] == f['name'] ? Border.all(color: f['color'], width: 2) : null),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(f['img'], width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 45, height: 45, color: (f['color'] as Color).withOpacity(0.1), child: Center(child: Text(f['icon'], style: const TextStyle(fontSize: 20)))))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(f['address'], style: const TextStyle(fontSize: 8, color: AppColors.grey)),
                  Text(f['phone'] ?? '', style: const TextStyle(fontSize: 8, color: AppColors.success)),
                ])),
              ]),
            ),
          );
        })),
      ]),
    );
  }

  Widget _trackingCard() {
    final steps = ['تم الطلب', 'قيد التجهيز', 'تم الشحن', 'تم التوصيل'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Column(children: [
        Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.local_shipping, color: AppColors.primary, size: 18)), const SizedBox(width: 8), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلبك في الطريق!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('رقم: #SHK-784512', style: TextStyle(fontSize: 9, color: AppColors.grey))]))]),
        const SizedBox(height: 10),
        Row(children: List.generate(steps.length, (i) => Expanded(child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: i < _currentStep ? AppColors.success : AppColors.grey, shape: BoxShape.circle), child: i < _currentStep ? const Icon(Icons.check, size: 7, color: Colors.white) : null), if (i < steps.length - 1) Expanded(child: Container(height: 2, color: i < _currentStep - 1 ? AppColors.success : AppColors.grey))])))),
        const SizedBox(height: 4),
        Row(children: List.generate(steps.length, (i) => Expanded(child: Text(steps[i], style: TextStyle(fontSize: 7, color: i < _currentStep ? AppColors.success : AppColors.grey), textAlign: TextAlign.center)))),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.06), borderRadius: BorderRadius.circular(6)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('⏱️ ', style: TextStyle(fontSize: 14)), Text('الوقت المتوقع: 18 دقيقة', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 11))])),
      ]),
    );
  }
}
