import 'package:flutter/material.dart';

class UnitConverterApp extends StatefulWidget {
  const UnitConverterApp({super.key});

  @override
  State<UnitConverterApp> createState() => _UnitConverterAppState();
}

class _UnitConverterAppState extends State<UnitConverterApp> {
  int _selectedCategory = 0;
  final TextEditingController _inputController = TextEditingController(text: '1');
  String _fromUnit = '';
  String _toUnit = '';
  String _result = '';
  String _categoryName = 'Length';
  
  final List<String> _categories = ['Length', 'Weight', 'Temperature', 'Area', 'Volume', 'Speed', 'Time', 'Data'];
  
  // Length units
  final List<String> _lengthUnits = ['Meter', 'Kilometer', 'Centimeter', 'Millimeter', 'Mile', 'Yard', 'Foot', 'Inch'];
  final Map<String, double> _lengthRates = {
    'Meter': 1.0,
    'Kilometer': 0.001,
    'Centimeter': 100.0,
    'Millimeter': 1000.0,
    'Mile': 0.000621371,
    'Yard': 1.09361,
    'Foot': 3.28084,
    'Inch': 39.3701,
  };
  
  // Weight units
  final List<String> _weightUnits = ['Kilogram', 'Gram', 'Milligram', 'Pound', 'Ounce', 'Ton', 'Carat'];
  final Map<String, double> _weightRates = {
    'Kilogram': 1.0,
    'Gram': 1000.0,
    'Milligram': 1000000.0,
    'Pound': 2.20462,
    'Ounce': 35.274,
    'Ton': 0.001,
    'Carat': 5000.0,
  };
  
  // Area units
  final List<String> _areaUnits = ['Square Meter', 'Square Kilometer', 'Square Centimeter', 'Square Foot', 'Acre', 'Hectare'];
  final Map<String, double> _areaRates = {
    'Square Meter': 1.0,
    'Square Kilometer': 0.000001,
    'Square Centimeter': 10000.0,
    'Square Foot': 10.7639,
    'Acre': 0.000247105,
    'Hectare': 0.0001,
  };
  
  // Volume units
  final List<String> _volumeUnits = ['Liter', 'Milliliter', 'Cubic Meter', 'Gallon', 'Quart', 'Pint', 'Cup'];
  final Map<String, double> _volumeRates = {
    'Liter': 1.0,
    'Milliliter': 1000.0,
    'Cubic Meter': 0.001,
    'Gallon': 0.264172,
    'Quart': 1.05669,
    'Pint': 2.11338,
    'Cup': 4.22675,
  };
  
  // Speed units
  final List<String> _speedUnits = ['km/h', 'mph', 'm/s', 'ft/s', 'knot'];
  final Map<String, double> _speedRates = {
    'km/h': 1.0,
    'mph': 0.621371,
    'm/s': 0.277778,
    'ft/s': 0.911344,
    'knot': 0.539957,
  };
  
  // Time units
  final List<String> _timeUnits = ['Second', 'Minute', 'Hour', 'Day', 'Week', 'Month', 'Year'];
  final Map<String, double> _timeRates = {
    'Second': 1.0,
    'Minute': 1.0 / 60,
    'Hour': 1.0 / 3600,
    'Day': 1.0 / 86400,
    'Week': 1.0 / 604800,
    'Month': 1.0 / 2592000,
    'Year': 1.0 / 31536000,
  };
  
  // Data units
  final List<String> _dataUnits = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  final Map<String, double> _dataRates = {
    'B': 1.0,
    'KB': 1.0 / 1024,
    'MB': 1.0 / (1024 * 1024),
    'GB': 1.0 / (1024 * 1024 * 1024),
    'TB': 1.0 / (1024 * 1024 * 1024 * 1024),
    'PB': 1.0 / (1024 * 1024 * 1024 * 1024 * 1024),
  };
  
  List<String> get _currentUnits {
    switch (_selectedCategory) {
      case 0: return _lengthUnits;
      case 1: return _weightUnits;
      case 2: return _weightUnits; // Temperature handled separately
      case 3: return _areaUnits;
      case 4: return _volumeUnits;
      case 5: return _speedUnits;
      case 6: return _timeUnits;
      case 7: return _dataUnits;
      default: return _lengthUnits;
    }
  }
  
  Map<String, double> get _currentRates {
    switch (_selectedCategory) {
      case 0: return _lengthRates;
      case 1: return _weightRates;
      case 3: return _areaRates;
      case 4: return _volumeRates;
      case 5: return _speedRates;
      case 6: return _timeRates;
      case 7: return _dataRates;
      default: return _lengthRates;
    }
  }

  @override
  void initState() {
    super.initState();
    _fromUnit = _lengthUnits[0];
    _toUnit = _lengthUnits[1];
    _convert();
  }

  void _convert() {
    final input = double.tryParse(_inputController.text) ?? 0;
    double result = 0;
    
    if (_selectedCategory == 2) {
      // Temperature conversion
      result = _convertTemperature(input);
    } else {
      final rates = _currentRates;
      final fromRate = rates[_fromUnit] ?? 1;
      final toRate = rates[_toUnit] ?? 1;
      result = input / fromRate * toRate;
    }
    
    setState(() {
      _result = _formatResult(result);
    });
  }
  
  double _convertTemperature(double value) {
    if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') return value * 9 / 5 + 32;
    if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') return value + 273.15;
    if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') return (value - 32) * 5 / 9;
    if (_fromUnit == 'Fahrenheit' && _toUnit == 'Kelvin') return (value - 32) * 5 / 9 + 273.15;
    if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') return value - 273.15;
    if (_fromUnit == 'Kelvin' && _toUnit == 'Fahrenheit') return (value - 273.15) * 9 / 5 + 32;
    return value;
  }
  
  String _formatResult(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(4)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(4)}K';
    return value.toStringAsFixed(4);
  }
  
  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = _selectedCategory == 2 
        ? ['Celsius', 'Fahrenheit', 'Kelvin'] 
        : _currentUnits;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Unit Converter', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Categories
            Container(
              height: 45,
              margin: const EdgeInsets.only(bottom: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = index;
                        _fromUnit = units[0];
                        _toUnit = units.length > 1 ? units[1] : units[0];
                        _convert();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : const Color(0xFF00BCD4).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFF00BCD4),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Input Field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _convert(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter value',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                  Text(_fromUnit, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // From/To Selectors
            Row(
              children: [
                Expanded(
                  child: _buildUnitSelector('From', _fromUnit, units, (value) {
                    setState(() {
                      _fromUnit = value!;
                      _convert();
                    });
                  }),
                ),
                IconButton(
                  onPressed: _swapUnits,
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
                  child: _buildUnitSelector('To', _toUnit, units, (value) {
                    setState(() {
                      _toUnit = value!;
                      _convert();
                    });
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Result
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('RESULT', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(
                    '$_result $_toUnit',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '= ${_inputController.text} $_fromUnit',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Common Conversions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Common Conversions', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getCommonConversions().map((conv) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _fromUnit = conv['from'] ?? "";
                          _toUnit = conv['to'] ?? "";
                          _inputController.text = '1';
                          _convert();
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
                          conv['label'] ?? "",
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
  
  Widget _buildUnitSelector(String label, String value, List<String> units, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
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
              style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14),
              isExpanded: true,
              items: units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
  
  List<Map<String, String>> _getCommonConversions() {
    switch (_selectedCategory) {
      case 0: return [
        {'from': 'Meter', 'to': 'Foot', 'label': 'Meter → Foot'},
        {'from': 'Kilometer', 'to': 'Mile', 'label': 'KM → Mile'},
        {'from': 'Inch', 'to': 'Centimeter', 'label': 'Inch → CM'},
      ];
      case 1: return [
        {'from': 'Kilogram', 'to': 'Pound', 'label': 'KG → LB'},
        {'from': 'Gram', 'to': 'Ounce', 'label': 'Gram → Ounce'},
        {'from': 'Ton', 'to': 'Kilogram', 'label': 'Ton → KG'},
      ];
      case 2: return [
        {'from': 'Celsius', 'to': 'Fahrenheit', 'label': '°C → °F'},
        {'from': 'Fahrenheit', 'to': 'Celsius', 'label': '°F → °C'},
        {'from': 'Celsius', 'to': 'Kelvin', 'label': '°C → K'},
      ];
      case 7: return [
        {'from': 'GB', 'to': 'MB', 'label': 'GB → MB'},
        {'from': 'MB', 'to': 'KB', 'label': 'MB → KB'},
        {'from': 'TB', 'to': 'GB', 'label': 'TB → GB'},
      ];
      default: return [
        {'from': 'Meter', 'to': 'Foot', 'label': 'Meter → Foot'},
      ];
    }
  }
}
