import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';

/// Animated Matrix-style background using Old South Arabian (Musnad) glyphs.
class CMatrixArabicBackground extends StatefulWidget {
  final Color color;
  final double opacity;
  final double speed;
  final double fontSize;
  final bool enabled;
  final bool useMusnad;
  final bool useArabicModern;

  const CMatrixArabicBackground({
    super.key,
    this.color = const Color(0xFF00BCD4),
    this.opacity = 0.15,
    this.speed = 2.2,
    this.fontSize = 18.54,
    this.enabled = true,
    this.useMusnad = true,
    this.useArabicModern = false,
  });

  @override
  State<CMatrixArabicBackground> createState() => _CMatrixArabicBackgroundState();
}

class _CMatrixArabicBackgroundState extends State<CMatrixArabicBackground>
    with SingleTickerProviderStateMixin {
  static const _musnadChars = <String>[
    '\u{10A60}', '\u{10A61}', '\u{10A62}', '\u{10A63}', '\u{10A64}',
    '\u{10A65}', '\u{10A66}', '\u{10A67}', '\u{10A68}', '\u{10A69}',
    '\u{10A6A}', '\u{10A6B}', '\u{10A6C}', '\u{10A6D}', '\u{10A6E}',
    '\u{10A6F}', '\u{10A70}', '\u{10A71}', '\u{10A72}', '\u{10A73}',
    '\u{10A74}', '\u{10A75}', '\u{10A76}', '\u{10A77}', '\u{10A78}',
    '\u{10A79}', '\u{10A7A}', '\u{10A7B}', '\u{10A7C}',
  ];
  static const _arabicChars = <String>[
    'ا','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ',
    'ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي',
  ];
  static const _extraChars = <String>[
    '٠','١','٢','٣','٤','٥','٦','٧','٨','٩','ﷺ','﷼',
  ];

  late final AnimationController _controller;
  final Random _random = Random();
  List<CMatrixColumn> _columns = const [];
  Size _lastSize = Size.zero;
  bool _fontLoaded = false;
  bool _lowBattery = false;
  StreamSubscription<BatteryState>? _batterySubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 33),
    )..addListener(_tick);
    _loadMusnadFont();
    _watchBattery();
    if (widget.enabled) _controller.repeat();
  }

  Future<void> _watchBattery() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      if (mounted) setState(() => _lowBattery = level <= 15);
      _batterySubscription = battery.onBatteryStateChanged.listen((state) async {
        try {
          final current = await battery.batteryLevel;
          if (mounted && _lowBattery != (current <= 15)) {
            setState(() => _lowBattery = current <= 15);
          }
        } catch (_) {}
      });
    } catch (_) {
      _lowBattery = false;
    }
  }

  Future<void> _loadMusnadFont() async {
    try {
      await rootBundle.load('assets/fonts/Musnad.ttf');
      if (mounted) setState(() => _fontLoaded = true);
    } catch (_) {
      if (mounted) setState(() => _fontLoaded = false);
    }
  }

  List<String> get _chars {
    if (widget.useMusnad && _fontLoaded) return [..._musnadChars, ..._extraChars];
    if (widget.useArabicModern) return [..._arabicChars, ..._extraChars];
    return [..._musnadChars, ..._arabicChars, ..._extraChars];
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final column in _columns) {
        column.tick(widget.speed);
      }
    });
  }

  void _initialize(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    final width = max(10.0, widget.fontSize * 1.2);
    final count = max(1, (size.width / width).ceil());
    _columns = List.generate(
      count,
      (i) => CMatrixColumn(
        x: i * width,
        fontSize: widget.fontSize,
        maxHeight: size.height,
        chars: _chars,
        random: _random,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CMatrixArabicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.useMusnad != widget.useMusnad ||
        oldWidget.useArabicModern != widget.useArabicModern) {
      _lastSize = Size.zero;
    }
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _lowBattery) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initialize(size);
        return RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: CMatrixArabicPainter(
              columns: _columns,
              color: widget.color,
              opacity: widget.opacity.clamp(0.0, 1.0),
              fontSize: widget.fontSize,
              useMusnad: widget.useMusnad && _fontLoaded,
            ),
          ),
        );
      },
    );
  }
}

class CMatrixColumn {
  final double x;
  final double fontSize;
  final double maxHeight;
  final List<String> chars;
  final Random random;
  double y = 0;
  double _speed = 1;
  late int length;
  late List<String> columnChars;

  CMatrixColumn({
    required this.x,
    required this.fontSize,
    required this.maxHeight,
    required this.chars,
    required this.random,
  }) {
    _reset();
  }

  void _reset() {
    y = -random.nextDouble() * maxHeight;
    _speed = 0.5 + random.nextDouble() * 1.5;
    length = 18 + random.nextInt(28);
    columnChars = List.generate(length, (_) => chars[random.nextInt(chars.length)]);
  }

  void tick(double globalSpeed) {
    y += _speed * globalSpeed * 3.2;
    if (y - length * fontSize > maxHeight) _reset();
    if (random.nextDouble() < 0.10 && columnChars.isNotEmpty) {
      columnChars[random.nextInt(columnChars.length)] = chars[random.nextInt(chars.length)];
    }
  }
}

class CMatrixArabicPainter extends CustomPainter {
  final List<CMatrixColumn> columns;
  final Color color;
  final double opacity;
  final double fontSize;
  final bool useMusnad;

  const CMatrixArabicPainter({
    required this.columns,
    required this.color,
    required this.opacity,
    required this.fontSize,
    required this.useMusnad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final family = useMusnad ? 'Musnad' : 'monospace';
    for (final column in columns) {
      for (var i = 0; i < column.columnChars.length; i++) {
        final y = column.y + i * fontSize * 1.3;
        if (y < -fontSize || y > size.height) continue;
        final head = i == column.columnChars.length - 1;
        final nearHead = i >= column.columnChars.length - 3;
        final alpha = head
            ? (opacity * 4).clamp(0.0, 1.0)
            : nearHead
                ? (opacity * 2.2).clamp(0.0, 1.0)
                : (opacity * (1 - i / column.columnChars.length) * 0.9)
                    .clamp(0.0, 1.0);
        final text = TextPainter(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          text: TextSpan(
            text: column.columnChars[i],
            style: TextStyle(
              fontFamily: family,
              fontSize: fontSize,
              fontWeight: head ? FontWeight.bold : FontWeight.normal,
              color: head
                  ? color.withOpacity(alpha)
                  : color.withOpacity(alpha),
              shadows: head
                  ? [
                      Shadow(color: color, blurRadius: 10),
                      Shadow(color: color.withOpacity(0.5), blurRadius: 20),
                    ]
                  : nearHead
                      ? [Shadow(color: color.withOpacity(0.5), blurRadius: 5)]
                      : null,
            ),
          ),
        )..layout();
        final x = column.x + fontSize * 0.75 - text.width / 2;
        text.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CMatrixArabicPainter oldDelegate) => true;
}

class CMatrixArabicSettings {
  final bool enabled;
  final bool useMusnad;
  final bool useArabicModern;
  final Color color;
  final double opacity;
  final double speed;
  final double fontSize;

  const CMatrixArabicSettings({
    this.enabled = true,
    this.useMusnad = true,
    this.useArabicModern = false,
    this.color = const Color(0xFF00FF41),
    this.opacity = 0.15,
    this.speed = 1.0,
    this.fontSize = 18,
  });

  CMatrixArabicSettings copyWith({
    bool? enabled,
    bool? useMusnad,
    bool? useArabicModern,
    Color? color,
    double? opacity,
    double? speed,
    double? fontSize,
  }) => CMatrixArabicSettings(
    enabled: enabled ?? this.enabled,
    useMusnad: useMusnad ?? this.useMusnad,
    useArabicModern: useArabicModern ?? this.useArabicModern,
    color: color ?? this.color,
    opacity: opacity ?? this.opacity,
    speed: speed ?? this.speed,
    fontSize: fontSize ?? this.fontSize,
  );
}
