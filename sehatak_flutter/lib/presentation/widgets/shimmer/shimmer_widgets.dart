import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// تأثير Shimmer للتطبيق بالكامل

class ShimmerContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  
  const ShimmerContainer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    final base = widget.baseColor ?? Colors.grey.shade200;
    final highlight = widget.highlightColor ?? Colors.grey.shade100;
    _animation = ColorTween(begin: base, end: highlight).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _animation.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ========== Shimmer للصفحة الرئيسية ==========
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ShimmerContainer(height: 44, borderRadius: 14),
        const SizedBox(height: 16),
        const ShimmerContainer(height: 160, borderRadius: 16),
        const SizedBox(height: 22),
        const ShimmerContainer(height: 20, width: 100),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(5, (_) => const ShimmerContainer(width: 50, height: 50, borderRadius: 25))),
        const SizedBox(height: 22),
        const ShimmerContainer(height: 20, width: 100),
        const SizedBox(height: 10),
        ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerContainer(height: 80, borderRadius: 14))),
        const SizedBox(height: 22),
        const ShimmerContainer(height: 20, width: 100),
        const SizedBox(height: 10),
        ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerContainer(height: 60, borderRadius: 12))),
      ]),
    );
  }
}

// ========== Shimmer لقائمة الأطباء ==========
class DoctorsShimmer extends StatelessWidget {
  const DoctorsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 50, child: Padding(padding: EdgeInsets.all(10), child: ShimmerContainer( borderRadius: 12))),
      const SizedBox(height: 10),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: 6, itemBuilder: (_, __) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Column(children: [
        ShimmerContainer(width: 60, height: 60, borderRadius: 30),
        SizedBox(height: 8),
        ShimmerContainer(height: 14, width: 100),
        SizedBox(height: 4),
        ShimmerContainer(height: 10, width: 70),
        Spacer(),
        ShimmerContainer(height: 30, borderRadius: 8),
      ])))),
    ]);
  }
}

// ========== Shimmer للصيدلية ==========
class PharmacyShimmer extends StatelessWidget {
  const PharmacyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Padding(padding: EdgeInsets.all(10), child: ShimmerContainer(height: 44, borderRadius: 12)),
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 6),
            child: ShimmerContainer(width: 70, height: 32, borderRadius: 16),
          ),
        ),
      ),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(10), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: 6, itemBuilder: (_, __) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Column(children: [
        ShimmerContainer(width: 40, height: 40, borderRadius: 20),
        SizedBox(height: 6),
        ShimmerContainer(height: 12),
        SizedBox(height: 4),
        ShimmerContainer(height: 12, width: 80),
        Spacer(),
        ShimmerContainer(height: 20, width: 60),
        SizedBox(height: 6),
        ShimmerContainer(height: 28, borderRadius: 8),
      ])))),
    ]);
  }
}

// ========== Shimmer للمواعيد ==========
class AppointmentsShimmer extends StatelessWidget {
  const AppointmentsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 50, child: Padding(padding: EdgeInsets.all(10), child: ShimmerContainer( borderRadius: 12))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(10), itemCount: 4, itemBuilder: (_, __) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Column(children: [
        Row(children: [ShimmerContainer(width: 48, height: 48, borderRadius: 24), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ShimmerContainer(height: 14, width: 120), SizedBox(height: 4), ShimmerContainer(height: 10, width: 80)]))]),
        SizedBox(height: 10),
        Row(children: [Expanded(child: ShimmerContainer(height: 34, borderRadius: 8)), SizedBox(width: 8), Expanded(child: ShimmerContainer(height: 34, borderRadius: 8))]),
      ])))),
    ]);
  }
}

// ========== Shimmer لصحتي ==========
class HealthShimmer extends StatelessWidget {
  const HealthShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ShimmerContainer(height: 180, borderRadius: 16),
      const SizedBox(height: 16),
      const ShimmerContainer(height: 60, borderRadius: 14),
      const SizedBox(height: 16),
      const ShimmerContainer(height: 20, width: 100),
      const SizedBox(height: 10),
      Row(children: List.generate(3, (_) => const Expanded(child: Padding(padding: EdgeInsets.only(right: 8), child: ShimmerContainer(height: 80, borderRadius: 12))))),
      const SizedBox(height: 16),
      const ShimmerContainer(height: 20, width: 100),
      const SizedBox(height: 10),
      ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 6), child: ShimmerContainer(height: 44, borderRadius: 10))),
    ]));
  }
}

// ========== Shimmer للدردشة ==========
class ChatShimmer extends StatelessWidget {
  const ChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: 6, itemBuilder: (_, i) {
        final isMe = i % 2 == 0;
        return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: isMe ? const Radius.circular(18) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(18))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ShimmerContainer(width: isMe ? 120 : 180, height: 12), const SizedBox(height: 4), ShimmerContainer(width: isMe ? 80 : 60, height: 8)])));
      })),
      Container(padding: const EdgeInsets.all(10), child: const ShimmerContainer(height: 48, borderRadius: 24)),
    ]);
  }
}

// ========== Shimmer للمزيد ==========
class MoreShimmer extends StatelessWidget {
  const MoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(14), child: Column(children: [
      const SizedBox(height: 20),
      Center(child: Column(children: [const ShimmerContainer(width: 80, height: 80, borderRadius: 40), const SizedBox(height: 12), const ShimmerContainer(width: 150, height: 18), const SizedBox(height: 4), const ShimmerContainer(width: 100, height: 12)])),
      const SizedBox(height: 20),
      ...List.generate(8, (_) => const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerContainer(height: 56, borderRadius: 14))),
    ]));
  }
}
