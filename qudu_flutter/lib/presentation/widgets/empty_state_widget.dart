import 'package:flutter/material.dart';

/// 空状态组件 — 统一空数据展示
///
/// 参数：icon（图标）、title（标题）、subtitle（副标题）、actionText（操作按钮文字）、onAction（操作回调）。
/// 预设场景：books / children / reports / review，可直接调用工厂方法。
class EmptyStateWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  /// 绘本书架空态
  factory EmptyStateWidget.books({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: const Icon(Icons.menu_book_rounded, size: 64, color: Color(0xFFC5E8A8)),
      title: '还没有绘本哦~',
      subtitle: '先完成识字，解锁精彩绘本吧！',
      actionText: '去识字',
      onAction: onAction,
    );
  }

  /// 儿童档案空态
  factory EmptyStateWidget.children({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: const Icon(Icons.child_care_rounded, size: 64, color: Color(0xFFFFAB91)),
      title: '添加第一个小朋友吧！',
      subtitle: '为宝贝创建专属学习档案',
      actionText: '添加宝贝',
      onAction: onAction,
    );
  }

  /// 学习报告空态
  factory EmptyStateWidget.reports() {
    return const EmptyStateWidget(
      icon: Icon(Icons.assessment_rounded, size: 64, color: Color(0xFFC5E8A8)),
      title: '今天还没有学习记录',
      subtitle: '完成一次学习后，报告会自动生成哦',
    );
  }

  /// 复习完成空态
  factory EmptyStateWidget.review() {
    return const EmptyStateWidget(
      icon: Icon(Icons.celebration_rounded, size: 64, color: Color(0xFFFFD54F)),
      title: '太棒了，全部复习完啦！',
      subtitle: '继续保持，明天再来看看吧',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF757575),
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8C8C8C),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
