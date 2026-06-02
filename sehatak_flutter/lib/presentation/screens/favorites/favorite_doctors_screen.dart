import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/chat/chat_screen.dart';

class FavoriteDoctorsScreen extends StatelessWidget {
  const FavoriteDoctorsScreen({super.key});

  final List<Map<String, dynamic>> _favs = const [
    {'name': 'د. علي المولد', 'specialty': 'باطنية وأطفال', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=100', 'online': true, 'next': 'اليوم 4:30 م'},
    {'name': 'د. حسن رضا', 'specialty': 'طبيب عام', 'rating': 4.8, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=100', 'online': true, 'next': 'اليوم 5:00 م'},
    {'name': 'د. عائشة ملك', 'specialty': 'جلدية', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=100', 'online': false, 'next': 'غداً 10:00 ص'},
    {'name': 'د. فاطمة صديقي', 'specialty': 'أطفال', 'rating': 4.9, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=100', 'online': true, 'next': 'اليوم 2:30 م'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أطبائي المفضلين', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView.builder(padding: const EdgeInsets.all(14), itemCount: _favs.length, itemBuilder: (c, i) {
        final d = _favs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(radius: 28, backgroundImage: NetworkImage(d['img'])),
              if (d['online']) Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(d['specialty'], style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 14), Text(' ${d['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
              Text(d['next'], style: TextStyle(fontSize: 10, color: d['online'] ? Colors.green : Colors.orange)),
            ])),
            Column(children: [
              IconButton(icon: const Icon(Icons.favorite, color: AppColors.error), onPressed: () {}),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero), child: const Text('استشر', style: TextStyle(fontSize: 10))),
            ]),
          ]),
        );
      }),
    );
  }
}
