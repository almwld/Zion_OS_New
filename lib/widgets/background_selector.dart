import 'package:flutter/material.dart';

class BackgroundSelector extends StatefulWidget {
  const BackgroundSelector({super.key});

  @override
  State<BackgroundSelector> createState() => _BackgroundSelectorState();
}

class _BackgroundSelectorState extends State<BackgroundSelector> {
  final List<Color> _gradients = [Colors.black, Colors.blueGrey, Colors.teal, Colors.deepPurple, Colors.indigo];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Background', style: TextStyle(color: Color(0xFF00BCD4))),
      backgroundColor: Colors.black,
      content: Wrap(
        spacing: 12,
        children: List.generate(_gradients.length, (i) => GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: Container(width: 50, height: 50, decoration: BoxDecoration(color: _gradients[i], borderRadius: BorderRadius.circular(12), border: _selectedIndex == i ? Border.all(color: const Color(0xFF00BCD4), width: 2) : null)),
        )),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Apply', style: TextStyle(color: Color(0xFF00BCD4))))],
    );
  }
}
