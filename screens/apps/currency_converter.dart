import 'package:flutter/material.dart';
import 'dart:math';

class CurrencyConverterApp extends StatefulWidget {
  const CurrencyConverterApp({super.key});

  @override
  State<CurrencyConverterApp> createState() => _CurrencyConverterAppState();
}

class _CurrencyConverterAppState extends State<CurrencyConverterApp> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  String _result = '';
  double _exchangeRate = 0;
  
  // Exchange rates (base USD)
  final Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 151.23,
    'CAD': 1.36,
    'AUD': 1.52,
    'CHF': 0.91,
    'CNY': 7.23,
    'INR': 83.12,
    'BRL': 5.03,
    'RUB': 91.45,
    'TRY': 32.15,
    'SAR': 3.75,
    'AED': 3.67,
    'EGP': 47.85,
    'KWD': 0.31,
    'QAR': 3.64,
    'OMR': 0.38,
    'BHD': 0.38,
    'JOD': 0.71,
  };
  
  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'BRL',
    'RUB', 'TRY', 'SAR', 'AED', 'EGP', 'KWD', 'QAR', 'OMR', 'BHD', 'JOD'
  ];
  
  final Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'EGP': 'Egyptian Pound',
    'KWD': 'Kuwaiti Dinar',
    'QAR': 'Qatari Riyal',
    'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar',
    'JOD': 'Jordanian Dinar',
  };
  
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'BRL': 'R\$',
    'RUB': '₽',
    'TRY': '₺',
    'SAR': '﷼',
    'AED': 'د.إ',
    'EGP': 'E£',
    'KWD': 'د.ك',
    'QAR': '﷼',
    'OMR': '﷼',
    'BHD': 'د.ب',
    'JOD': 'د.ا',
  };
  
  @override
  void initState() {
    super.initState();
    _calculate();
  }
  
  void _calculate() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double rate = _rates[_toCurrency]! / _rates[_fromCurrency]!;
    double result = amount * rate;
    
    setState(() {
      _exchangeRate = rate;
      _result = result.toStringAsFixed(2);
    });
  }
  
  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _calculate();
    });
  }
  
  Widget _buildCurrencySelector(String title, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold),
              isExpanded: true,
              items: _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Row(
                    children: [
                      Text(_currencySymbols[currency]!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(currency, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(_currencyNames[currency]!, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  onChanged(v);
                  _calculate();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Currency Converter', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _calculate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (_) => _calculate(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter amount',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Currency Selectors
            _buildCurrencySelector('From', _fromCurrency, (v) => setState(() => _fromCurrency = v)),
            
            const SizedBox(height: 10),
            
            // Swap Button
            Center(
              child: IconButton(
                onPressed: _swapCurrencies,
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz, color: Color(0xFF00BCD4), size: 28),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            _buildCurrencySelector('To', _toCurrency, (v) => setState(() => _toCurrency = v)),
            
            const SizedBox(height: 30),
            
            // Exchange Rate Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Exchange Rate',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 $_fromCurrency = ${_exchangeRate.toStringAsFixed(4)} $_toCurrency',
                    style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Result Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Converted Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currencySymbols[_toCurrency]} $_result',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_toCurrency - ${_currencyNames[_toCurrency]}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Popular Conversions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Conversions',
                    style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickConversion('USD', 'EUR'),
                      _buildQuickConversion('USD', 'GBP'),
                      _buildQuickConversion('EUR', 'USD'),
                      _buildQuickConversion('GBP', 'USD'),
                      _buildQuickConversion('USD', 'EGP'),
                      _buildQuickConversion('EUR', 'EGP'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickConversion(String from, String to) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fromCurrency = from;
          _toCurrency = to;
          _amountController.text = '1';
          _calculate();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Text(
          '$from → $to',
          style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12),
        ),
      ),
    );
  }
}
