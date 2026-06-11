import 'package:flutter/material.dart';
import '../../core/services/games_service.dart';

class GamesCenter extends StatefulWidget {
  const GamesCenter({super.key});

  @override
  State<GamesCenter> createState() => _GamesCenterState();
}

class _GamesCenterState extends State<GamesCenter> {
  late GamesService _games;
  
  // Guess Number
  final TextEditingController _guessController = TextEditingController();
  String _guessMessage = 'Guess a number between 1 and 100';
  int _guessAttempts = 0;
  
  // Memory Game
  bool _memoryGameStarted = false;
  
  // Reaction Game
  String _reactionMessage = 'Wait for green...';
  Color _reactionColor = Colors.red;
  
  // Color Match
  String _colorMatchMessage = 'Tap the matching color';
  int _colorMatchScore = 0;
  
  // Tic Tac Toe
  bool _ticTacToeStarted = false;

  @override
  void initState() {
    super.initState();
    _games = GamesService();
    _games.init();
    _games.initGuessNumber();
  }
  
  void _checkGuess() {
    final guess = int.tryParse(_guessController.text);
    if (guess == null) {
      setState(() => _guessMessage = 'Please enter a valid number');
      return;
    }
    
    final result = _games.checkGuess(guess);
    if (result.isCorrect) {
      setState(() {
        _guessMessage = '🎉 Congratulations! You won in ${result.attempts} attempts! 🎉';
        _guessAttempts = result.attempts!;
      });
      _games.initGuessNumber();
    } else if (result.isTooLow) {
      setState(() => _guessMessage = '📈 Too low! Try a higher number');
    } else {
      setState(() => _guessMessage = '📉 Too high! Try a lower number');
    }
    _guessController.clear();
  }
  
  void _newGuessGame() {
    _games.initGuessNumber();
    setState(() {
      _guessMessage = 'Guess a number between 1 and 100';
      _guessAttempts = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Games Center', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFF00BCD4),
              unselectedLabelColor: Colors.white54,
              indicatorColor: Color(0xFF00BCD4),
              tabs: [
                Tab(icon: Icon(Icons.numbers), text: 'Guess'),
                Tab(icon: Icon(Icons.memory), text: 'Memory'),
                Tab(icon: Icon(Icons.timer), text: 'Reaction'),
                Tab(icon: Icon(Icons.color_lens), text: 'Color'),
                Tab(icon: Icon(Icons.grid_on), text: 'TicTacToe'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGuessNumberTab(),
                  _buildMemoryGameTab(),
                  _buildReactionGameTab(),
                  _buildColorMatchTab(),
                  _buildTicTacToeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGuessNumberTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.numbers, color: Colors.white, size: 50),
                const SizedBox(height: 10),
                Text(
                  '$_guessAttempts',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text('Attempts', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(_guessMessage, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextField(
            controller: _guessController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter your guess',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00BCD4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: const Color(0xFF00BCD4).withOpacity(0.5)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
                  child: const Text('Guess'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _newGuessGame,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  child: const Text('New Game'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoryGameTab() {
    if (!_memoryGameStarted) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            _games.initMemoryGame();
            setState(() => _memoryGameStarted = true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
          child: const Text('Start Memory Game'),
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Moves: ${_games.moveCount}', style: const TextStyle(color: Color(0xFF00BCD4))),
              if (_games.isMemoryGameComplete())
                const Text('Complete! 🎉', style: TextStyle(color: Colors.green)),
              ElevatedButton(
                onPressed: () => setState(() => _memoryGameStarted = false),
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _games.memoryCards.length,
            itemBuilder: (context, index) {
              final isFlipped = _games.flippedCards.contains(index) || _games.matchedCards.contains(index);
              final isMatched = _games.matchedCards.contains(index);
              
              return GestureDetector(
                onTap: () {
                  if (!isMatched && _games.flippedCards.length < 2) {
                    _games.memoryCardTapped(index);
                    setState(() {});
                    
                    if (_games.flippedCards.length == 2) {
                      Future.delayed(const Duration(seconds: 1), () {
                        _games.resetFlippedCards();
                        setState(() {});
                      });
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isFlipped
                        ? const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)])
                        : const LinearGradient(colors: [Colors.grey, Color(0xFF333333)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isFlipped ? '${_games.memoryCards[index]}' : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildReactionGameTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              final time = _games.tapReaction();
              if (time > 0) {
                setState(() {
                  _reactionMessage = 'Your reaction time: $time ms';
                  _reactionColor = Colors.blue;
                });
              } else if (_games._reactionWaiting) {
                setState(() {
                  _reactionMessage = 'Too soon! Wait for green';
                  _reactionColor = Colors.red;
                });
              }
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _reactionColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _reactionColor.withOpacity(0.5), blurRadius: 20),
                ],
              ),
              child: const Center(
                child: Text('TAP', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(_reactionMessage, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _games.resetReaction();
              _games.startReactionGame();
              setState(() {
                _reactionMessage = 'Wait for green...';
                _reactionColor = Colors.red;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorMatchTab() {
    if (_games.currentColor == null) {
      _games.initColorMatch();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _getColorFromName(_games.currentColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _getColorFromName(_games.currentColor).withOpacity(0.5), blurRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Tap: ${_games.currentColorName}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 10,
            children: [
              'Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'
            ].map((color) => ElevatedButton(
              onPressed: () {
                final isCorrect = _games.checkColorMatch(color);
                if (isCorrect) {
                  setState(() => _colorMatchScore++);
                } else {
                  setState(() => _colorMatchScore = 0);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColorFromName(color),
                foregroundColor: Colors.white,
              ),
              child: Text(color),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Score: $_colorMatchScore', style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18)),
        ],
      ),
    );
  }
  
  Widget _buildTicTacToeTab() {
    if (!_ticTacToeStarted) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            _games.initTicTacToe();
            setState(() => _ticTacToeStarted = true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
          child: const Text('Start Tic Tac Toe'),
        ),
      );
    }
    
    return Column(
      children: [
        if (_games.winner.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.2),
            child: Text(
              _games.winner == 'Tie' ? 'Game Tie!' : 'Player ${_games.winner} Wins!',
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (_games.winner.isEmpty) {
                    _games.ticTacToeMove(index);
                    setState(() {});
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _games.board[index],
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              _games.initTicTacToe();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
            child: const Text('New Game'),
          ),
        ),
      ],
    );
  }
  
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
