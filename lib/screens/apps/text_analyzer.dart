import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextAnalyzerApp extends StatefulWidget {
  const TextAnalyzerApp({super.key});

  @override
  State<TextAnalyzerApp> createState() => _TextAnalyzerAppState();
}

class _TextAnalyzerAppState extends State<TextAnalyzerApp> {
  final TextEditingController _textController = TextEditingController();
  
  int _charCount = 0;
  int _wordCount = 0;
  int _lineCount = 0;
  int _spaceCount = 0;
  int _vowelCount = 0;
  int _consonantCount = 0;
  int _digitCount = 0;
  int _specialCharCount = 0;
  String _longestWord = '';
  String _shortestWord = '';
  String _reversedText = '';
  
  bool _isAnalyzed = false;
  
  void _analyzeText() {
    final text = _textController.text;
    
    if (text.isEmpty) {
      setState(() {
        _isAnalyzed = false;
      });
      return;
    }
    
    // Character count (including spaces)
    final charCount = text.length;
    
    // Word count
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    
    // Line count
    final lineCount = text.split('\n').length;
    
    // Space count
    final spaceCount = ' '.allMatches(text).length;
    
    // Vowel and consonant count
    int vowelCount = 0;
    int consonantCount = 0;
    int digitCount = 0;
    int specialCharCount = 0;
    
    for (var i = 0; i < text.length; i++) {
      final char = text[i].toLowerCase();
      if ('aeiou'.contains(char)) {
        vowelCount++;
      } else if (char.contains(RegExp(r'[a-z]'))) {
        consonantCount++;
      } else if (char.contains(RegExp(r'[0-9]'))) {
        digitCount++;
      } else if (char != ' ' && char != '\n' && !char.contains(RegExp(r'[a-z0-9]'))) {
        specialCharCount++;
      }
    }
    
    // Longest and shortest word
    String longest = '';
    String shortest = words.isNotEmpty ? words.first : '';
    for (var word in words) {
      if (word.length > longest.length) longest = word;
      if (word.length < shortest.length) shortest = word;
    }
    
    // Reversed text
    final reversed = text.split('').reversed.join('');
    
    setState(() {
      _charCount = charCount;
      _wordCount = wordCount;
      _lineCount = lineCount;
      _spaceCount = spaceCount;
      _vowelCount = vowelCount;
      _consonantCount = consonantCount;
      _digitCount = digitCount;
      _specialCharCount = specialCharCount;
      _longestWord = longest;
      _shortestWord = shortest;
      _reversedText = reversed;
      _isAnalyzed = true;
    });
  }
  
  void _clearText() {
    _textController.clear();
    setState(() {
      _isAnalyzed = false;
      _charCount = 0;
      _wordCount = 0;
      _lineCount = 0;
      _spaceCount = 0;
      _vowelCount = 0;
      _consonantCount = 0;
      _digitCount = 0;
      _specialCharCount = 0;
      _longestWord = '';
      _shortestWord = '';
      _reversedText = '';
    });
  }
  
  void _copyResult() {
    final result = '''
Text Analysis Result:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Characters: $_charCount
Words: $_wordCount
Lines: $_lineCount
Spaces: $_spaceCount
Vowels: $_vowelCount
Consonants: $_consonantCount
Digits: $_digitCount
Special Characters: $_specialCharCount
Longest Word: $_longestWord
Shortest Word: $_shortestWord
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reversed Text:
$_reversedText
''';
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis copied to clipboard'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Text Analyzer', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFF00BCD4)),
            onPressed: _isAnalyzed ? _copyResult : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Enter or paste text here...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _analyzeText,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearText,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Results
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                ),
                child: _isAnalyzed
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResultRow('Characters', '$_charCount'),
                            _buildResultRow('Words', '$_wordCount'),
                            _buildResultRow('Lines', '$_lineCount'),
                            _buildResultRow('Spaces', '$_spaceCount'),
                            const Divider(color: Color(0xFF00BCD4), height: 15),
                            _buildResultRow('Vowels', '$_vowelCount'),
                            _buildResultRow('Consonants', '$_consonantCount'),
                            _buildResultRow('Digits', '$_digitCount'),
                            _buildResultRow('Special Characters', '$_specialCharCount'),
                            const Divider(color: Color(0xFF00BCD4), height: 15),
                            _buildResultRow('Longest Word', '"$_longestWord"'),
                            _buildResultRow('Shortest Word', '"$_shortestWord"'),
                            const SizedBox(height: 10),
                            const Text('Reversed Text:', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: SelectableText(
                                _reversedText,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Enter text and click Analyze',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
