import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class GamesService {
  static final GamesService _instance = GamesService._internal();
  factory GamesService() => _instance;
  GamesService._internal();
  
  final Random _random = Random();
  
  // Game scores storage
  Map<String, Map<String, dynamic>> _highScores = {};
  
  Future<void> init() async {
    await _loadHighScores();
  }
  
  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    // Load scores from preferences if needed
  }
  
  Future<void> saveHighScore(String gameName, int score, String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${gameName}_highscore', score);
    await prefs.setString('${gameName}_player', playerName);
  }
  
  Future<int> getHighScore(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameName}_highscore') ?? 0;
  }
  
  // Guess Number Game
  int _targetNumber = 0;
  int _attempts = 0;
  
  void initGuessNumber() {
    _targetNumber = _random.nextInt(100) + 1;
    _attempts = 0;
  }
  
  GuessResult checkGuess(int guess) {
    _attempts++;
    if (guess == _targetNumber) {
      return GuessResult.correct(attempts: _attempts);
    } else if (guess < _targetNumber) {
      return GuessResult.tooLow();
    } else {
      return GuessResult.tooHigh();
    }
  }
  
  // Memory Game
  List<int> _memoryCards = [];
  List<int> _flippedCards = [];
  List<int> _matchedCards = [];
  int _moveCount = 0;
  
  void initMemoryGame() {
    final numbers = List.generate(8, (i) => i + 1);
    _memoryCards = [...numbers, ...numbers];
    _memoryCards.shuffle(_random);
    _flippedCards = [];
    _matchedCards = [];
    _moveCount = 0;
  }
  
  void memoryCardTapped(int index) {
    if (_flippedCards.contains(index)) return;
    if (_matchedCards.contains(index)) return;
    if (_flippedCards.length == 2) return;
    
    _flippedCards.add(index);
    _moveCount++;
    
    if (_flippedCards.length == 2) {
      final card1 = _memoryCards[_flippedCards[0]];
      final card2 = _memoryCards[_flippedCards[1]];
      
      if (card1 == card2) {
        _matchedCards.addAll(_flippedCards);
        _flippedCards.clear();
      }
    }
  }
  
  void resetFlippedCards() {
    _flippedCards.clear();
  }
  
  bool isMemoryGameComplete() {
    return _matchedCards.length == _memoryCards.length;
  }
  
  List<int> get memoryCards => _memoryCards;
  List<int> get flippedCards => _flippedCards;
  List<int> get matchedCards => _matchedCards;
  int get moveCount => _moveCount;
  
  // Reaction Game
  DateTime? _reactionStartTime;
  int _reactionTime = 0;
  bool _reactionWaiting = false;
  
  void startReactionGame() {
    _reactionWaiting = true;
    Future.delayed(Duration(milliseconds: _random.nextInt(3000) + 1000), () {
      if (_reactionWaiting) {
        _reactionStartTime = DateTime.now();
      }
    });
  }
  
  int tapReaction() {
    if (_reactionStartTime != null) {
      _reactionTime = DateTime.now().difference(_reactionStartTime!).inMilliseconds;
      _reactionWaiting = false;
      _reactionStartTime = null;
      return _reactionTime;
    }
    return -1;
  }
  
  void resetReaction() {
    _reactionWaiting = false;
    _reactionStartTime = null;
  }
  
  // Color Match Game
  final List<String> _colors = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'];
  String? _currentColor;
  String? _currentColorName;
  
  void initColorMatch() {
    _currentColor = _colors[_random.nextInt(_colors.length)];
    _currentColorName = _colors[_random.nextInt(_colors.length)];
  }
  
  bool checkColorMatch(String selectedColor) {
    final isMatch = selectedColor == _currentColorName;
    initColorMatch();
    return isMatch;
  }
  
  String get currentColor => _currentColor ?? 'Red';
  String get currentColorName => _currentColorName ?? 'Red';
  
  // Tic Tac Toe
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String _winner = '';
  
  void initTicTacToe() {
    _board = List.filled(9, '');
    _currentPlayer = 'X';
    _winner = '';
  }
  
  bool ticTacToeMove(int index) {
    if (_board[index].isNotEmpty) return false;
    if (_winner.isNotEmpty) return false;
    
    _board[index] = _currentPlayer;
    
    if (_checkWinner(_currentPlayer)) {
      _winner = _currentPlayer;
    } else if (_board.every((cell) => cell.isNotEmpty)) {
      _winner = 'Tie';
    } else {
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    }
    
    return true;
  }
  
  bool _checkWinner(String player) {
    const winPatterns = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6]
    ];
    
    for (final pattern in winPatterns) {
      if (_board[pattern[0]] == player &&
          _board[pattern[1]] == player &&
          _board[pattern[2]] == player) {
        return true;
      }
    }
    return false;
  }
  
  List<String> get board => _board;
  String get currentPlayer => _currentPlayer;
  String get winner => _winner;
}

class GuessResult {
  final bool isCorrect;
  final bool isTooLow;
  final bool isTooHigh;
  final int? attempts;
  
  GuessResult._({required this.isCorrect, required this.isTooLow, required this.isTooHigh, this.attempts});
  
  factory GuessResult.correct({required int attempts}) {
    return GuessResult._(isCorrect: true, isTooLow: false, isTooHigh: false, attempts: attempts);
  }
  
  factory GuessResult.tooLow() {
    return GuessResult._(isCorrect: false, isTooLow: true, isTooHigh: false);
  }
  
  factory GuessResult.tooHigh() {
    return GuessResult._(isCorrect: false, isTooLow: false, isTooHigh: true);
  }
}
