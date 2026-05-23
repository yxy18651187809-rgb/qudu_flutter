import 'package:flutter/material.dart';

/// 骨架屏加载组件 — 自实现，无第三方依赖
///
/// 使用线性渐变 + AnimationController 实现从左到右的闪烁动画（1.5s loop）。
/// 色系适配字趣阅读品牌：primaryLight(#C5E8A8) → surface(#FFFFFF)。
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: const [0.4, 0.5, 0.6],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: const _ShimmerPlaceholder(),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFE8E8E8));
  }
}

/// 单个骨架块
///
/// [width] 为 null 时自适应父容器宽度
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: const ShimmerLoading(),
      ),
    );
  }
}

/// 卡片式骨架（横向排列多块骨架）
class ShimmerCard extends StatelessWidget {
  final int childCount;

  const ShimmerCard({super.key, this.childCount = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              childCount,
              (i) => const ShimmerBox(width: 72, height: 88, borderRadius: 12),
            ),
          ),
          const SizedBox(height: 16),
          const ShimmerBox(height: 16),
          const SizedBox(height: 8),
          const ShimmerBox(height: 16),
          const SizedBox(height: 8),
          const ShimmerBox(width: 160, height: 16),
        ],
      ),
    );
  }
}

/// 列表式骨架（竖向排列多行）
class ShimmerList extends StatelessWidget {
  final int itemCount;

  const ShimmerList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const ShimmerBox(height: 72, borderRadius: 12),
    );
  }
}
