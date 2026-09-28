import 'dart:async';
import 'dart:math';

class CryptoTransaction {
  final String id;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final String status;
  final DateTime timestamp;

  CryptoTransaction({required this.id, required this.from, required this.to, required this.amount, required this.currency, required this.status, required this.timestamp});
}

class CryptoLaundering {
  final List<CryptoTransaction> _transactions = [];
  bool _isLaundering = false;
  int _mixProgress = 0;
  final List<String> _wallets = [
    'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
    '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb2',
    'XMR:48Q5gZ2KfF3d8YjW9R4sH7tN6mL1pVxJcBvCn',
  ];

  List<CryptoTransaction> get transactions => _transactions;
  bool get isLaundering => _isLaundering;
  int get mixProgress => _mixProgress;
  List<String> get wallets => _wallets;

  Future<void> startLaundering(double amount, String currency) async {
    _isLaundering = true;
    _mixProgress = 0;
    final random = Random();

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mixProgress = i;
    }

    _transactions.add(CryptoTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      from: _wallets[0],
      to: _wallets[random.nextInt(_wallets.length)],
      amount: amount,
      currency: currency,
      status: 'completed',
      timestamp: DateTime.now(),
    ));

    _isLaundering = false;
  }

  Future<String> generateNewWallet(String currency) async {
    final random = Random();
    final chars = 'abcdef0123456789';
    String wallet = '';
    if (currency == 'BTC') {
      wallet = 'bc1${List.generate(38, (_) => chars[random.nextInt(chars.length)]).join()}';
    } else if (currency == 'ETH') {
      wallet = '0x${List.generate(40, (_) => chars[random.nextInt(chars.length)]).join()}';
    } else if (currency == 'XMR') {
      wallet = '4${List.generate(94, (_) => chars[random.nextInt(chars.length)]).join()}';
    }
    _wallets.add(wallet);
    return wallet;
  }
}
