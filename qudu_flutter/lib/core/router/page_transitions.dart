import 'package:flutter/material.dart';

/// 页面过渡动画工具
///
/// 返回自定义 Page 子类，适配 GoRouter 的 pageBuilder。
/// 预设4种过渡类型，时长统一 300ms，使用 Curves.easeOutCubic。
class PageTransitions {
  PageTransitions._();

  /// 底部滑入 — 适用于设置页、详情页
  static Page slideUp(Widget child, {LocalKey? key}) {
    return _AnimatedPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// 右侧滑入 — 适用于列表→详情
  static Page slideRight(Widget child, {LocalKey? key}) {
    return _AnimatedPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// 淡入淡出 — 适用于Tab切换、同级页面
  static Page fadeThrough(Widget child, {LocalKey? key}) {
    return _AnimatedPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  /// 缩放弹出 — 适用于弹窗、完成页
  static Page scale(Widget child, {LocalKey? key}) {
    return _AnimatedPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// 自定义动画页面 — 继承 Page 并重写 createRoute
class _AnimatedPage extends Page {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
      transitionsBuilder;

  const _AnimatedPage({
    super.key,
    required this.child,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    required this.transitionsBuilder,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (_, __, ___) => child,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
