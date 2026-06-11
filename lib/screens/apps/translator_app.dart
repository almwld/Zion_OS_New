import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslatorApp extends StatefulWidget {
  const TranslatorApp({super.key});

  @override
  State<TranslatorApp> createState() => _TranslatorAppState();
}

class _TranslatorAppState extends State<TranslatorApp> {
  final TextEditingController _sourceController = TextEditingController();
  String _translatedText = '';
  String _fromLanguage = 'en';
  String _toLanguage = 'ar';
  bool _isLoading = false;
  String _detectedLanguage = '';
  
  final Map<String, String> _languages = {
    'en': 'English',
    'ar': 'Arabic',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'pl': 'Polish',
    'sv': 'Swedish',
    'hi': 'Hindi',
    'ur': 'Urdu',
    'fa': 'Persian',
    'he': 'Hebrew',
    'el': 'Greek',
  };
  
  final List<String> _languageCodes = [
    'en', 'ar', 'fr', 'es', 'de', 'it', 'pt', 'ru', 'zh', 'ja',
    'ko', 'tr', 'nl', 'pl', 'sv', 'hi', 'ur', 'fa', 'he', 'el'
  ];
  
  final List<String> _commonPhrases = [
    'Hello, how are you?',
    'Thank you very much',
    'What is your name?',
    'Where is the bathroom?',
    'How much does this cost?',
    'I love you',
    'Good morning',
    'Good night',
    'See you later',
    'Help me please',
  ];

  Future<void> _translate() async {
    final sourceText = _sourceController.text.trim();
    if (sourceText.isEmpty) {
      setState(() {
        _translatedText = 'Enter text to translate';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _translatedText = '';
    });
    
    try {
      // Simulated translation (using API would require API key)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simple simulated translation (for demo)
      final simulated = _simulateTranslation(sourceText, _fromLanguage, _toLanguage);
      
      setState(() {
        _translatedText = simulated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Translation failed. Please try again.';
        _isLoading = false;
      });
    }
  }
  
  String _simulateTranslation(String text, String from, String to) {
    // Simple demo translation
    if (text.toLowerCase() == 'hello' && to == 'ar') return 'مرحباً';
    if (text.toLowerCase() == 'hello' && to == 'fr') return 'Bonjour';
    if (text.toLowerCase() == 'hello' && to == 'es') return 'Hola';
    if (text.toLowerCase() == 'thank you' && to == 'ar') return 'شكراً جزيلاً';
    if (text.toLowerCase() == 'good morning' && to == 'ar') return 'صباح الخير';
    if (text.toLowerCase() == 'good night' && to == 'ar') return 'تصبح على خير';
    if (text.toLowerCase() == 'i love you' && to == 'ar') return 'أحبك';
    
    return '[$to] $text (Simulated translation)';
  }
  
  void _swapLanguages() {
    setState(() {
      String temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
      _translate();
    });
  }
  
  void _clearText() {
    _sourceController.clear();
    setState(() {
      _translatedText = '';
    });
  }
  
  void _copyTranslation() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Translation copied'), backgroundColor: Color(0xFF00BCD4)),
    );
  }
  
  void _speakTranslation() {
    // Text-to-speech would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text-to-speech coming soon'), backgroundColor: Color(0xFF00BCD4)),
    );
  }
  
  void _useCommonPhrase(String phrase) {
    setState(() {
      _sourceController.text = phrase;
      _translate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Translator', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Color(0xFF00BCD4)),
            onPressed: _clearText,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Source Language Selector
            Row(
              children: [
                Expanded(
                  child: _buildLanguageSelector('From', _fromLanguage, (value) {
                    setState(() => _fromLanguage = value!);
                    _translate();
                  }),
                ),
                IconButton(
                  onPressed: _swapLanguages,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Color(0xFF00BCD4)),
                  ),
                ),
                Expanded(
                  child: _buildLanguageSelector('To', _toLanguage, (value) {
                    setState(() => _toLanguage = value!);
                    _translate();
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Source Text Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _languages[_fromLanguage]!,
                    style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sourceController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Enter text to translate...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _translate(),
                  ),
                  if (_detectedLanguage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Detected: ${_languages[_detectedLanguage]}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Translation Result
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _languages[_toLanguage]!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                            onPressed: _copyTranslation,
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.white, size: 18),
                            onPressed: _speakTranslation,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : SelectableText(
                          _translatedText.isEmpty ? 'Translation will appear here...' : _translatedText,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Common Phrases
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Common Phrases',
                    style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonPhrases.map((phrase) => GestureDetector(
                      onTap: () => _useCommonPhrase(phrase),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                        ),
                        child: Text(
                          phrase,
                          style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageSelector(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14),
              isExpanded: true,
              items: _languageCodes.map((code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text(_languages[code]!),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
