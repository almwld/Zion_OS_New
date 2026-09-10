import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class TranslatorApp extends StatefulWidget {
  const TranslatorApp({super.key});

  @override
  State<TranslatorApp> createState() => _TranslatorAppState();
}

class _TranslatorAppState extends State<TranslatorApp> {
  final _sourceController = TextEditingController();
  String _translatedText = '';
  String _fromLanguage = 'en';
  String _toLanguage = 'ar';
  bool _isLoading = false;
  String? _error;

  static const _endpoint = String.fromEnvironment('TRANSLATION_API_URL');

  final Map<String, String> _languages = const {
    'en': 'English', 'ar': 'Arabic', 'fr': 'French', 'es': 'Spanish',
    'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'ru': 'Russian',
    'zh': 'Chinese', 'ja': 'Japanese', 'ko': 'Korean', 'tr': 'Turkish',
    'nl': 'Dutch', 'pl': 'Polish', 'sv': 'Swedish', 'hi': 'Hindi',
    'ur': 'Urdu', 'fa': 'Persian', 'he': 'Hebrew', 'el': 'Greek',
  };

  List<String> get _languageCodes => _languages.keys.toList(growable: false);

  Future<void> _translate() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _translatedText = '';
          _error = null;
        });
      }
      return;
    }
    if (_endpoint.isEmpty) {
      if (mounted) {
        setState(() {
          _translatedText = '';
          _error = 'الترجمة غير مُهيأة: أضف TRANSLATION_API_URL لخدمة ترجمة حقيقية.';
        });
      }
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _translatedText = '';
    });
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': _fromLanguage,
          'target': _toLanguage,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final translated = data['translatedText'];
      if (translated is! String || translated.trim().isEmpty) {
        throw Exception('Invalid translation response');
      }
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'تعذر الحصول على ترجمة حقيقية من الخدمة: $e';
        });
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final t = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = t;
    });
    _translate();
  }

  void _copyTranslation() {
    if (_translatedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الترجمة')),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Translator',
          style: TextStyle(color: Color(0xFF00BCD4)),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Color(0xFF00BCD4)),
            onPressed: () {
              _sourceController.clear();
              setState(() {
                _translatedText = '';
                _error = null;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _selector(
                  'From',
                  _fromLanguage,
                  (v) {
                    if (v == null) return;
                    setState(() => _fromLanguage = v);
                    _translate();
                  },
                ),
              ),
              IconButton(
                onPressed: _swapLanguages,
                icon: const Icon(Icons.swap_horiz, color: Color(0xFF00BCD4)),
              ),
              Expanded(
                child: _selector(
                  'To',
                  _toLanguage,
                  (v) {
                    if (v == null) return;
                    setState(() => _toLanguage = v);
                    _translate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _panel(
            child: TextField(
              controller: _sourceController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'أدخل النص...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _translate,
              icon: const Icon(Icons.translate),
              label: const Text('ترجمة حقيقية'),
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _languages[_toLanguage]!,
                        style: const TextStyle(color: Color(0xFF00BCD4)),
                      ),
                    ),
                    IconButton(
                      onPressed: _copyTranslation,
                      icon: const Icon(Icons.copy, color: Colors.white54),
                    ),
                  ],
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.orangeAccent),
                  )
                else
                  SelectableText(
                    _translatedText.isEmpty
                        ? 'لا توجد نتيجة بعد.'
                        : _translatedText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'حالة الخدمة',
            style: TextStyle(
              color: Color(0xFF00BCD4),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _endpoint.isEmpty
                ? 'NOT_CONFIGURED — لم يتم ضبط مزود ترجمة.'
                : 'READY — سيتم استخدام نقطة الترجمة المهيأة.',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _selector(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
        ),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items: _languageCodes
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(_languages[c]!),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BCD4).withOpacity(.25),
        ),
      ),
      child: child,
    );
  }
}
