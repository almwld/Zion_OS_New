import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/services/zion_platform_service.dart';

class NetworkRadarScreen extends StatefulWidget {
  const NetworkRadarScreen({super.key});
  @override State<NetworkRadarScreen> createState() => _NetworkRadarScreenState();
}

class _NetworkRadarScreenState extends State<NetworkRadarScreen> with SingleTickerProviderStateMixin {
  final _platform = ZionPlatformService.instance;
  StreamSubscription<Map<String, Object?>>? _subscription;
  late final AnimationController _sweep;
  Map<String, Object?> _data = const {};
  final List<double> _rx = <double>[];
  final List<double> _tx = <double>[];
  @override void initState() {
    super.initState();
    _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _subscription = _platform.networkRadarStream().listen((sample) {
      if (!mounted) return;
      setState(() {
        _data = sample;
        _push(_rx, _number(sample['rxBytesPerSec']));
        _push(_tx, _number(sample['txBytesPerSec']));
      });
    });
  }
  void _push(List<double> list, double value) { list.add(value); if (list.length > 48) list.removeAt(0); }
  double _number(Object? value) => value is num ? value.toDouble() : 0;
  String _text(String key, [String fallback = '—']) => _data[key]?.toString() ?? fallback;
  String _rate(Object? value) {
    var v = _number(value); var i = 0; const units = ['B/s','KB/s','MB/s','GB/s'];
    while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
    return v.toStringAsFixed(i == 0 ? 0 : 1) + ' ' + units[i];
  }
  String _bytes(Object? value) {
    var v = _number(value); var i = 0; const units = ['B','KB','MB','GB','TB'];
    while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
    return v.toStringAsFixed(v >= 100 ? 0 : 1) + ' ' + units[i];
  }
  @override void dispose() { _subscription?.cancel(); _sweep.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final connected = _data['connected'] == true;
    final rssi = _data['wifiRssi'];
    return Scaffold(
      backgroundColor: const Color(0xFF05080D),
      appBar: AppBar(backgroundColor: const Color(0xFF071019), foregroundColor: Colors.white, title: const Text('الرادار الشبكي'),
        actions: [Padding(padding: const EdgeInsets.only(right: 14), child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: connected ? const Color(0xFF37F29A) : Colors.redAccent)),
          const SizedBox(width: 7), Text(connected ? 'LIVE' : 'OFFLINE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(14), children: [
        _RadarCard(animation: _sweep, active: connected, rx: _number(_data['rxBytesPerSec']), tx: _number(_data['txBytesPerSec'])),
        const SizedBox(height: 12), _metrics(rssi), const SizedBox(height: 12),
        _TrafficGraph(rx: _rx, tx: _tx), const SizedBox(height: 12), _details(),
      ])),
    );
  }
  Widget _metrics(Object? rssi) {
    final items = <List<Object>>[
      ['↓ الاستقبال', _rate(_data['rxBytesPerSec']), Icons.download], ['↑ الإرسال', _rate(_data['txBytesPerSec']), Icons.upload],
      ['الحزم ↓', _rate(_data['rxPacketsPerSec']), Icons.call_received], ['الحزم ↑', _rate(_data['txPacketsPerSec']), Icons.call_made],
      ['الواجهة', _text('interface'), Icons.lan], ['الإشارة', rssi is num ? rssi.toInt().toString() + ' dBm' : 'N/A', Icons.signal_cellular_alt],
    ];
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.85),
      itemBuilder: (_, i) => _GlassMetric(title: items[i][0] as String, value: items[i][1] as String, icon: items[i][2] as IconData));
  }
  Widget _details() => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('محلل البيانات اللحظي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12), _row('IP', _text('ipAddress')),
    _row('DNS', (_data['dns'] as List?)?.join('  •  ') ?? '—'), _row('المسارات', _text('routes', '0')),
    _row('Downlink', _text('downstreamKbps', '0') + ' Kbps'), _row('Uplink', _text('upstreamKbps', '0') + ' Kbps'),
    _row('الإجمالي ↓', _bytes(_data['rxBytes'])), _row('الإجمالي ↑', _bytes(_data['txBytes'])),
    _row('VPN', _data['vpn'] == true ? 'مفعل' : 'غير مفعل'), _row('Metered', _data['metered'] == true ? 'نعم' : 'لا'),
  ]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    SizedBox(width: 95, child: Text(label, style: const TextStyle(color: Colors.white54))), Expanded(child: Text(value, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'monospace'))),
  ]));
}

class _RadarCard extends StatelessWidget {
  final Animation<double> animation; final bool active; final double rx; final double tx;
  const _RadarCard({required this.animation, required this.active, required this.rx, required this.tx});
  static String _format(double v) { if (v >= 1048576) return (v/1048576).toStringAsFixed(1)+' MB/s'; if (v >= 1024) return (v/1024).toStringAsFixed(1)+' KB/s'; return v.toStringAsFixed(0)+' B/s'; }
  @override Widget build(BuildContext context) => _Panel(padding: EdgeInsets.zero, child: SizedBox(height: 285, child: AnimatedBuilder(animation: animation, builder: (_, __) => CustomPaint(
    painter: _RadarPainter(phase: animation.value, active: active, activity: math.min(1, (rx+tx)/1048576)),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(active ? Icons.radar : Icons.radar_outlined, size: 44, color: active ? const Color(0xFF37F29A) : Colors.white24),
      const SizedBox(height: 7), Text(active ? 'NETWORK RADAR' : 'NETWORK OFFLINE', style: TextStyle(color: active ? const Color(0xFF37F29A) : Colors.white38, fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 4), Text('LIVE  ' + _format(rx) + ' ↓   ' + _format(tx) + ' ↑', style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
    ])),
  ))));
}

class _RadarPainter extends CustomPainter {
  final double phase; final bool active; final double activity;
  _RadarPainter({required this.phase, required this.active, required this.activity});
  @override void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2); final radius = math.min(size.width, size.height)*.39;
    final grid = Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0xFF37F29A).withOpacity(.12);
    for (var i=1;i<=4;i++) { canvas.drawCircle(center, radius*i/4, grid); }
    canvas.drawLine(Offset(center.dx-radius,center.dy),Offset(center.dx+radius,center.dy),grid); canvas.drawLine(Offset(center.dx,center.dy-radius),Offset(center.dx,center.dy+radius),grid);
    final sweep=Paint()..shader=SweepGradient(startAngle:-math.pi/2,endAngle:math.pi*1.5,colors:[const Color(0x0037F29A),const Color(0x5537F29A),const Color(0x0037F29A)],stops:[0,.08,.18]).createShader(Rect.fromCircle(center:center,radius:radius));
    canvas.save(); canvas.translate(center.dx,center.dy); canvas.rotate(phase*math.pi*2); canvas.drawCircle(Offset.zero,radius,sweep); canvas.restore();
    if(active){ final p=.5+.5*math.sin(phase*math.pi*2); final dot=Paint()..color=const Color(0xFF37F29A).withOpacity(.45+p*.45)..maskFilter=const MaskFilter.blur(BlurStyle.normal,7); canvas.drawCircle(center,4+activity*5,dot); }
  }
  @override bool shouldRepaint(covariant _RadarPainter old) => old.phase!=phase || old.active!=active || old.activity!=activity;
}

class _TrafficGraph extends StatelessWidget {
  final List<double> rx; final List<double> tx; const _TrafficGraph({required this.rx,required this.tx});
  @override Widget build(BuildContext context)=>_Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('حركة البيانات — مباشر',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),const SizedBox(height:12),
    SizedBox(height:105,child:CustomPaint(painter:_GraphPainter(rx:rx,tx:tx),child:const SizedBox.expand())),const SizedBox(height:8),
    const Row(children:[_LegendDot(color:Color(0xFF37F29A),label:'RX'),SizedBox(width:18),_LegendDot(color:Color(0xFF58A6FF),label:'TX')]),
  ]));
}
class _GraphPainter extends CustomPainter {
  final List<double> rx; final List<double> tx; _GraphPainter({required this.rx,required this.tx});
  @override void paint(Canvas canvas,Size size){ final all=[...rx,...tx]; final maxValue=math.max(1024.0,all.fold<double>(0,math.max));
    void draw(List<double> v,Paint p){if(v.length<2)return;final path=Path();for(var i=0;i<v.length;i++){final x=i*size.width/47;final y=size.height-(v[i]/maxValue)*size.height;if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}canvas.drawPath(path,p);}
    draw(rx,Paint()..color=const Color(0xFF37F29A)..strokeWidth=2..style=PaintingStyle.stroke);draw(tx,Paint()..color=const Color(0xFF58A6FF)..strokeWidth=2..style=PaintingStyle.stroke);
  } @override bool shouldRepaint(covariant _GraphPainter old)=>true;
}
class _GlassMetric extends StatelessWidget {
  final String title,value; final IconData icon; const _GlassMetric({required this.title,required this.value,required this.icon});
  @override Widget build(BuildContext context)=>_Panel(padding:const EdgeInsets.all(10),child:Row(children:[Icon(icon,color:const Color(0xFF37F29A),size:19),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(title,style:const TextStyle(color:Colors.white54,fontSize:11)),const SizedBox(height:2),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:12,fontFamily:'monospace'))]))]));
}
class _LegendDot extends StatelessWidget { final Color color; final String label; const _LegendDot({required this.color,required this.label}); @override Widget build(BuildContext context)=>Row(children:[Container(width:8,height:8,decoration:BoxDecoration(color:color,shape:BoxShape.circle)),const SizedBox(width:5),Text(label,style:const TextStyle(color:Colors.white54,fontSize:11))]); }
class _Panel extends StatelessWidget { final Widget child; final EdgeInsets padding; const _Panel({required this.child,this.padding=const EdgeInsets.all(14)}); @override Widget build(BuildContext context)=>Container(padding:padding,decoration:BoxDecoration(color:const Color(0xFF0B141C).withOpacity(.92),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFF37F29A).withOpacity(.12)),boxShadow:const[BoxShadow(color:Colors.black45,blurRadius:18,offset:Offset(0,8))]),child:child); }