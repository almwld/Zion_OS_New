import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class StressMeterScreen extends StatefulWidget {
  const StressMeterScreen({super.key});
  @override
  State<StressMeterScreen> createState() => _StressMeterScreenState();
}

class _StressMeterScreenState extends State<StressMeterScreen> {
  int _currentStep = 0; // 0=info, 1=test, 2=result
  int _score = 0;
  
  // 15 سؤال للتقييم النفسي
  final List<Map<String, dynamic>> _questions = const [
    {'q': 'أشعر بالتوتر والقلق معظم الوقت', 'weight': 3},
    {'q': 'أجد صعوبة في النوم أو الاستمرار في النوم', 'weight': 3},
    {'q': 'أشعر بالإرهاق والتعب بدون سبب واضح', 'weight': 2},
    {'q': 'أجد صعوبة في التركيز على المهام اليومية', 'weight': 2},
    {'q': 'أشعر بسرعة الانفعال والغضب من أبسط الأمور', 'weight': 2},
    {'q': 'فقدت الاهتمام بالأنشطة التي كنت أستمتع بها', 'weight': 3},
    {'q': 'أشعر بآلام جسدية (صداع، ظهر، معدة) بدون سبب طبي', 'weight': 2},
    {'q': 'تغيرت شهيتي بشكل ملحوظ (زيادة أو نقصان)', 'weight': 1},
    {'q': 'أشعر بالعزلة والوحدة حتى مع وجود الآخرين', 'weight': 2},
    {'q': 'أجد صعوبة في اتخاذ القرارات البسيطة', 'weight': 1},
    {'q': 'أشعر بأن الأمور خارجة عن السيطرة', 'weight': 2},
    {'q': 'أستيقظ متعباً حتى بعد النوم الكافي', 'weight': 2},
    {'q': 'أشعر بالخوف من المستقبل باستمرار', 'weight': 3},
    {'q': 'أفقد أعصابي بسهولة مع العائلة والأصدقاء', 'weight': 2},
    {'q': 'أشعر أن الضغوط تفوق قدرتي على التحمل', 'weight': 3},
  ];

  List<int> _answers = List.filled(15, -1);

  int get _totalScore {
    int total = 0;
    for (int i = 0; i < _questions.length; i++) {
      total += _answers[i] * (_questions[i]['weight'] as int);
    }
    return total;
  }

  String get _stressLevel {
    if (_totalScore <= 20) return 'منخفض';
    if (_totalScore <= 50) return 'متوسط';
    if (_totalScore <= 80) return 'مرتفع';
    return 'شديد';
  }

  Color get _stressColor {
    switch (_stressLevel) {
      case 'منخفض': return AppColors.success;
      case 'متوسط': return AppColors.warning;
      case 'مرتفع': return AppColors.error;
      case 'شديد': return const Color(0xFFB71C1C);
      default: return AppColors.grey;
    }
  }

  String get _stressEmoji {
    switch (_stressLevel) {
      case 'منخفض': return '😊';
      case 'متوسط': return '😐';
      case 'مرتفع': return '😟';
      case 'شديد': return '😰';
      default: return '🤔';
    }
  }

  List<String> get _recommendations {
    final list = <String>[];
    if (_totalScore <= 20) {
      list.add('• أنت في حالة جيدة! استمر في نمط حياتك الصحي');
      list.add('• مارس التأمل والاسترخاء بانتظام');
      list.add('• حافظ على توازن العمل والحياة');
    } else if (_totalScore <= 50) {
      list.add('• خذ استراحة قصيرة كل ساعة عمل');
      list.add('• مارس الرياضة 30 دقيقة يومياً');
      list.add('• تحدث مع صديق تثق به عن مشاعرك');
      list.add('• جرب تمارين التنفس العميق');
    } else if (_totalScore <= 80) {
      list.add('• ننصحك بمراجعة أخصائي نفسي');
      list.add('• قلل من الكافيين والمنبهات');
      list.add('• نظم وقتك وحدد أولوياتك');
      list.add('• مارس تمارين الاسترخاء والتأمل');
      list.add('• احصل على قسط كاف من النوم');
    } else {
      list.add('• تواصل مع أخصائي نفسي في أقرب وقت');
      list.add('• لا تتردد في طلب المساعدة');
      list.add('• تحدث مع شخص تثق به');
      list.add('• خذ إجازة للراحة والاستجمام');
      list.add('• تذكر أن الصحة النفسية مثل الجسدية تماماً');
    }
    return list;
  }

  void _startTest() => setState(() { _currentStep = 1; _answers = List.filled(15, -1); _score = 0; });

  void _submitTest() {
    bool allAnswered = _answers.every((a) => a >= 0);
    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى الإجابة على جميع الأسئلة')));
      return;
    }
    setState(() { _score = _totalScore; _currentStep = 2; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقياس التوتر', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _currentStep == 0
          ? _buildInfoScreen()
          : _currentStep == 1
              ? _buildTestScreen()
              : _buildResultScreen(),
    );
  }

  // ============ شاشة المعلومات الأولية ============
  Widget _buildInfoScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]), shape: BoxShape.circle),
            child: const Icon(Icons.psychology, color: Colors.white, size: 50),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('مقياس التوتر والضغط النفسي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        const Center(child: Text('DASS-21 المعدل', style: TextStyle(fontSize: 12, color: AppColors.grey))),
        const SizedBox(height: 24),

        // معلومات عن الاختبار
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.info.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('عن الاختبار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('• 15 سؤالاً لقياس مستوى التوتر', style: TextStyle(fontSize: 13)),
            Text('• مدة الاختبار: 3-5 دقائق', style: TextStyle(fontSize: 13)),
            Text('• يعتمد على مقياس DASS-21 العلمي', style: TextStyle(fontSize: 13)),
            Text('• هذا اختبار مساعد فقط وليس تشخيصاً طبياً', style: TextStyle(fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),

        // مستويات التوتر
        Text('مستويات النتائج', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _levelInfo('منخفض (0-20)', '😊', 'حالتك النفسية جيدة. استمر في عاداتك الصحية.', AppColors.success),
        _levelInfo('متوسط (21-50)', '😐', 'لديك بعض التوتر. جرب تقنيات الاسترخاء.', AppColors.warning),
        _levelInfo('مرتفع (51-80)', '😟', 'مستوى توتر مرتفع. ننصح باستشارة مختص.', AppColors.error),
        _levelInfo('شديد (81+)', '😰', 'توتر شديد. يرجى التواصل مع أخصائي نفسي.', const Color(0xFFB71C1C)),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _startTest,
          icon: const Icon(Icons.play_arrow),
          label: const Text('ابدأ الاختبار'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18)),
        )),
      ]),
    );
  }

  // ============ شاشة الاختبار ============
  Widget _buildTestScreen() {
    return Column(children: [
      LinearProgressIndicator(value: _answers.where((a) => a >= 0).length / _questions.length, backgroundColor: AppColors.surfaceContainerLow, color: AppColors.primary, minHeight: 6),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: _questions.length,
          itemBuilder: (context, idx) {
            final q = _questions[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: _answers[idx] >= 0 ? AppColors.primary : AppColors.grey.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text('${idx + 1}', style: TextStyle(fontSize: 11, color: _answers[idx] >= 0 ? Colors.white : AppColors.grey)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q['q'], style: const TextStyle(fontSize: 14, height: 1.4))),
                ]),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _answerButton(idx, 0, 'أبداً', '0'),
                  _answerButton(idx, 1, 'أحياناً', '1'),
                  _answerButton(idx, 2, 'غالباً', '2'),
                  _answerButton(idx, 3, 'دائماً', '3'),
                ]),
              ]),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.all(14),
        color: Colors.white,
        child: Row(children: [
          Text('${_answers.where((a) => a >= 0).length}/${_questions.length} تمت الإجابة', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          const Spacer(),
          ElevatedButton.icon(onPressed: _submitTest, icon: const Icon(Icons.check), label: const Text('عرض النتيجة'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary)),
        ]),
      ),
    ]);
  }

  // ============ شاشة النتيجة ============
  Widget _buildResultScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        const SizedBox(height: 10),
        // بطاقة النتيجة
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_stressColor.withOpacity(0.8), _stressColor]), borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text(_stressEmoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 10),
            const Text('مستوى التوتر', style: TextStyle(color: Colors.white70, fontSize: 16)),
            Text(_stressLevel, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_totalScore نقطة', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 16),

        // مقياس بصري
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Column(children: [
            Row(children: [
              const Text('منخفض', style: TextStyle(fontSize: 10, color: AppColors.success)),
              Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 10, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0)), child: Slider(value: _totalScore.toDouble(), min: 0, max: 132, activeColor: _stressColor, inactiveColor: AppColors.surfaceContainerLow, onChanged: null))),
              const Text('شديد', style: TextStyle(fontSize: 10, color: Color(0xFFB71C1C))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // شرح النتيجة
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _stressColor.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: _stressColor.withOpacity(0.2))),
          child: Row(children: [Icon(Icons.info, color: _stressColor), const SizedBox(width: 8), Expanded(child: Text(_getResultDescription(), style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.darkGrey)))]),
        ),
        const SizedBox(height: 16),

        // توصيات
        Text('توصيات لك', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _recommendations.map((r) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(r, style: const TextStyle(fontSize: 13, height: 1.4)))).toList()),
        ),
        const SizedBox(height: 20),

        // أزرار
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _startTest, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('إعادة الاختبار'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.psychology), label: const Text('استشر مختص'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)))),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _answerButton(int idx, int value, String label, String number) {
    final selected = _answers[idx] == value;
    return GestureDetector(
      onTap: () => setState(() => _answers[idx] = value),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Column(children: [
          Text(number, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.darkGrey)),
          Text(label, style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : AppColors.grey)),
        ]),
      ),
    );
  }

  Widget _levelInfo(String title, String emoji, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)), Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.grey))])),
      ]),
    );
  }

  String _getResultDescription() {
    switch (_stressLevel) {
      case 'منخفض': return 'نتيجتك تشير إلى مستوى توتر منخفض. أنت تتعامل مع الضغوط بشكل جيد. حافظ على نمط حياتك الصحي.';
      case 'متوسط': return 'نتيجتك تشير إلى مستوى توتر متوسط. قد تحتاج إلى بعض تقنيات الاسترخاء وإدارة الوقت.';
      case 'مرتفع': return 'نتيجتك تشير إلى مستوى توتر مرتفع. ننصحك بالتحدث مع مختص نفسي ومنصة تقنيات إدارة التوتر.';
      case 'شديد': return 'نتيجتك تشير إلى مستوى توتر شديد. ننصحك بشدة بالتواصل مع أخصائي نفسي في أقرب وقت. أنت لست وحدك.';
      default: return '';
    }
  }
}
