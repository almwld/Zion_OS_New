import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class FontSizeScreen extends StatefulWidget {
  const FontSizeScreen({super.key});
  @override
  State<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends State<FontSizeScreen> {
  double _fontScale = 1.0;
  String _fontSize = 'متوسط';

  final String _previewText = 'مرحباً بك في منصة صحتك\nهذا النص يوضح حجم الخط الحالي\nيمكنك تعديل حجم الخط من هنا';

  void _updateFontSize(double scale) {
    setState(() {
      _fontScale = scale;
      if (scale <= 0.85) {
        _fontSize = 'صغير جداً';
      } else if (scale <= 0.95) {
        _fontSize = 'صغير';
      } else if (scale <= 1.05) {
        _fontSize = 'متوسط';
      } else if (scale <= 1.2) {
        _fontSize = 'كبير';
      } else {
        _fontSize = 'كبير جداً';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجم الخط', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // معاينة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), const Text('معاينة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _previewText,
                  textAlign: TextAlign.right,
                  textScaleFactor: _fontScale,
                  style: TextStyle(fontSize: 14, color: AppColors.darkGrey, height: 1.8),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                  child: Text(_fontSize, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // شريط التحكم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('A', style: TextStyle(fontSize: 14)), Text('A', style: TextStyle(fontSize: 24))]),
              const SizedBox(height: 8),
              Slider(
                value: _fontScale,
                min: 0.8,
                max: 1.3,
                divisions: 10,
                activeColor: AppColors.primary,
                label: _fontSize,
                onChanged: _updateFontSize,
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                Text('صغير', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                Text('متوسط', style: TextStyle(fontSize: 10, color: AppColors.grey)),
                Text('كبير', style: TextStyle(fontSize: 10, color: AppColors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // أمثلة
          Text('أمثلة على أحجام مختلفة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _exampleCard('عنوان رئيسي', 20 * _fontScale, FontWeight.bold),
          _exampleCard('عنوان فرعي', 16 * _fontScale, FontWeight.w600),
          _exampleCard('نص عادي', 14 * _fontScale, FontWeight.normal),
          _exampleCard('نص صغير', 11 * _fontScale, FontWeight.normal),
          const SizedBox(height: 24),

          // زر الحفظ
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ حجم الخط'), backgroundColor: AppColors.success)); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('حفظ', style: TextStyle(fontSize: 16)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { setState(() => _updateFontSize(1.0)); }, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('إعادة للافتراضي'))),
        ]),
      ),
    );
  }

  Widget _exampleCard(String label, double fontSize, FontWeight weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: AppColors.darkGrey)),
        const Spacer(),
        Text('${fontSize.toStringAsFixed(0)}px', style: const TextStyle(fontSize: 10, color: AppColors.grey)),
      ]),
    );
  }
}
