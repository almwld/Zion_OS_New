import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});
  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  bool _wouldRecommend = true;
  final TextEditingController _feedbackController = TextEditingController();
  List<String> _selectedTags = [];

  final List<String> _tags = ['سهل الاستخدام', 'مفيد', 'تصميم جميل', 'سريع', 'منظم', 'ممتاز', 'يحتاج تحسين'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم التطبيق', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          const SizedBox(height: 10),
          const Icon(Icons.star, size: 70, color: AppColors.amber),
          const SizedBox(height: 16),
          const Text('ما رأيك في منصة صحتك؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('تقييمك يساعدنا في التحسين', style: TextStyle(color: AppColors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          // النجوم
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Icon(i < _rating ? Icons.star : Icons.star_border, color: AppColors.amber, size: 48),
          ))),
          if (_rating > 0) ...[
            const SizedBox(height: 6),
            Text(_ratingText, style: TextStyle(fontWeight: FontWeight.bold, color: _rating >= 4 ? AppColors.success : _rating >= 3 ? AppColors.warning : AppColors.error)),
          ],
          const SizedBox(height: 24),

          // هل توصي؟
          Text('هل توصي أصدقاءك بالتطبيق؟', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            _recommendButton('نعم 👍', true),
            const SizedBox(width: 10),
            _recommendButton('لا 👎', false),
          ]),
          const SizedBox(height: 16),

          // وسوم
          Text('أضف وصفاً', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _tags.map((t) => FilterChip(
            label: Text(t, style: const TextStyle(fontSize: 11)),
            selected: _selectedTags.contains(t),
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            onSelected: (v) => setState(() => v ? _selectedTags.add(t) : _selectedTags.remove(t)),
          )).toList()),
          const SizedBox(height: 14),

          // ملاحظات
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'أخبرنا المزيد عن تجربتك...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainerLow.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك! 🤍'), backgroundColor: AppColors.success)); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('إرسال التقييم', style: TextStyle(fontSize: 16)))),
        ]),
      ),
    );
  }

  String get _ratingText {
    switch (_rating) {
      case 1: return 'سيء جداً 😞';
      case 2: return 'سيء 😐';
      case 3: return 'متوسط 🙂';
      case 4: return 'جيد 😊';
      case 5: return 'ممتاز 🤩';
      default: return '';
    }
  }

  Widget _recommendButton(String label, bool value) {
    final selected = _wouldRecommend == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _wouldRecommend = value),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 2 : 1)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? AppColors.primary : AppColors.darkGrey))),
      ),
    );
  }
}
