import 'package:flutter/material.dart';
import 'dart:math';

class GamesCenter extends StatefulWidget {
  const GamesCenter({super.key});

  @override
  State<GamesCenter> createState() => _GamesCenterState();
}

class _GamesCenterState extends State<GamesCenter> {
  final List<Map<String, dynamic>> _games = [
    {'name': 'تخمين الرقم', 'icon': Icons.numbers, 'color': 0xFF00FF41, 'description': 'خمن الرقم العشوائي'},
    {'name': 'الذاكرة', 'icon': Icons.memory, 'color': 0xFF00FF41, 'description': 'اختبر ذاكرتك'},
    {'name': 'ردة الفعل', 'icon': Icons.timer, 'color': 0xFF00FF41, 'description': 'اختبر سرعة رد فعلك'},
    {'name': 'تحدي الألوان', 'icon': Icons.color_lens, 'color': 0xFF00FF41, 'description': 'اختر اللون الصحيح'},
    {'name': 'آلة حاسبة', 'icon': Icons.calculate, 'color': 0xFF00FF41, 'description': 'تحدي الرياضيات'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مركز الألعاب', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return GestureDetector(
            onTap: () {
              if (game['name'] == 'تخمين الرقم') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuessNumberGame()));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(game['color']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(game['icon'], color: Color(game['color']), size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(game['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(game['description'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// لعبة تخمين الرقم
class GuessNumberGame extends StatefulWidget {
  const GuessNumberGame({super.key});

  @override
  State<GuessNumberGame> createState() => _GuessNumberGameState();
}

class _GuessNumberGameState extends State<GuessNumberGame> {
  final Random _random = Random();
  late int _targetNumber;
  late int _attempts;
  String _message = 'خمن رقم بين 1 و 100';
  final TextEditingController _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _targetNumber = _random.nextInt(100) + 1;
    _attempts = 0;
    _message = 'خمن رقم بين 1 و 100';
    _guessController.clear();
    setState(() {});
  }

  void _checkGuess() {
    final guess = int.tryParse(_guessController.text);
    if (guess == null) {
      setState(() => _message = 'الرجاء إدخال رقم صحيح');
      return;
    }

    _attempts++;
    if (guess == _targetNumber) {
      setState(() => _message = '🎉 تهانينا! لقد فزت في $_attempts محاولات 🎉');
    } else if (guess < _targetNumber) {
      setState(() => _message = 'الرقم أكبر من $guess');
    } else {
      setState(() => _message = 'الرقم أصغر من $guess');
    }
    _guessController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('تخمين الرقم', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FF41), width: 2),
              ),
              child: Center(
                child: Text(
                  '$_attempts',
                  style: const TextStyle(color: Color(0xFF00FF41), fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(_message, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 30),
            TextField(
              controller: _guessController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'أدخل رقم',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00FF41)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.5)),
                ),
              ),
              onSubmitted: (_) => _checkGuess(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkGuess,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text('تحقق', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _newGame,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    child: const Text('لعبة جديدة', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
