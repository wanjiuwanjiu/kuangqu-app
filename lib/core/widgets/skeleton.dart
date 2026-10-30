import 'package:flutter/material.dart';

/// 骨架屏：柔和呼吸动画（单个控制器，开销极小）
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 0.75)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE9EAEF) : const Color(0xFF2A2A2E),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// 帖子卡片骨架
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(height: 18, width: 48, radius: 9),
              const SizedBox(width: 8),
              const SkeletonBox(height: 14, width: 70),
              const Spacer(),
              const SkeletonBox(height: 12, width: 44),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(height: 14),
          const SizedBox(height: 8),
          const SkeletonBox(height: 14, width: 180),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonBox(height: 16, width: 46),
              const SizedBox(width: 18),
              const SkeletonBox(height: 16, width: 46),
            ],
          ),
        ],
      ),
    );
  }
}
