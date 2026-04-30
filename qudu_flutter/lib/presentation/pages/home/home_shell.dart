import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../wordbook/word_learning_page.dart';
import '../bookshelf/bookshelf_page.dart';
import 'home_page.dart';
import '../profile/profile_page.dart';

/// 首页TabBar壳 — 包含4个底部导航Tab
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  /// 切换Tab
  void switchToTab(int index) {
    if (index < 0 || index > 3) return;
    setState(() => _currentIndex = index);
  }

  /// 4个Tab页面
  static const List<_TabItem> _tabs = [
    _TabItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: '首页'),
    _TabItem(icon: Icons.auto_stories_rounded, activeIcon: Icons.auto_stories_rounded, label: '识字'),
    _TabItem(icon: Icons.menu_book_rounded, activeIcon: Icons.menu_book_rounded, label: '书架'),
    _TabItem(icon: Icons.person_rounded, activeIcon: Icons.person_rounded, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: 首页 ✅ 真实页面已接入
          const HomePage(),
          // Tab 1: 识字首页 ✅ 真实页面已接入
          const WordLearningPage(),
          // Tab 2: 书架 ✅ 真实页面已接入（等插画师封面图素材替换图标placeholder）
          const BookshelfPage(),
          // Tab 3: 我的 ✅ 真实页面已接入
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = _currentIndex == index;
                return _buildTabItem(tab, isSelected, index);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(_TabItem tab, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面数据模型
class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
