import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../wordbook/word_learning_page.dart';
import '../bookshelf/bookshelf_page.dart';
import 'home_page.dart';
import '../profile/profile_page.dart';
import '../../../core/network/network_aware_mixin.dart';
import '../../../core/network/offline_cache.dart';
import '../../../data/repositories/children_repository.dart';
import '../../../data/repositories/books_repository.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../core/di/service_locator.dart';

/// 首页TabBar壳 — 包含4个底部导航Tab
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell>
    with NetworkAwareMixin {
  int _currentIndex = 0;

  /// 切换Tab
  void switchToTab(int index) {
    if (index < 0 || index > 3) return;
    setState(() => _currentIndex = index);
  }

  /// 4个Tab页面
  static const List<_TabItem> _tabs = [
    _TabItem(
      icon: 'assets/icons/tab_home.svg',
      activeIcon: 'assets/icons/tab_home_active.svg',
      label: '首页',
    ),
    _TabItem(
      icon: 'assets/icons/tab_learn.svg',
      activeIcon: 'assets/icons/tab_learn_active.svg',
      label: '识字',
    ),
    _TabItem(
      icon: 'assets/icons/tab_bookshelf.svg',
      activeIcon: 'assets/icons/tab_bookshelf_active.svg',
      label: '书架',
    ),
    _TabItem(
      icon: 'assets/icons/tab_profile.svg',
      activeIcon: 'assets/icons/tab_profile_active.svg',
      label: '我的',
    ),
  ];

  @override
  void initState() {
    super.initState();
    initNetworkAware(); // 初始化网络状态监听
    _preloadData(); // 预加载关键数据
  }

  @override
  void dispose() {
    disposeNetworkAware(); // 取消网络状态订阅
    super.dispose();
  }

  /// 预加载关键数据（在有网络时）
  Future<void> _preloadData() async {
    if (isOffline) return; // 离线时不预加载

    try {
      final childrenRepo = ChildrenRepository(apiClient: ServiceLocator.instance.apiClient);
      final booksRepo = BooksRepository();
      final learningRepo = LearningRepository(apiClient: ServiceLocator.instance.apiClient);

      // 获取儿童列表，提取 ID
      final children = await childrenRepo.getChildren();
      final childIds = children.map((c) => c.id).toList();

      // 调用 OfflineCache 预加载
      await OfflineCache().preloadEssentialData(
        fetchChildren: () async {
          await childrenRepo.getChildren();
        },
        fetchBooks: () async {
          await booksRepo.getBooks();
          await booksRepo.getRecommendedBooks();
        },
        fetchStats: (childId) async {
          await learningRepo.getStats(childId);
        },
        childIds: childIds,
      );
    } catch (e) {
      // 预加载失败，不影响主流程
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
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
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppRadius.small),
      splashColor: AppColors.primary.withOpacity(0.2),
      highlightColor: AppColors.primary.withOpacity(0.1),
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
            SvgPicture.asset(
              isSelected ? tab.activeIcon : tab.icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? AppColors.primary : AppColors.textSecondary,
                BlendMode.srcIn,
              ),
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

/// Tab 数据模型（使用SVG图标）
class _TabItem {
  final String icon;
  final String activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
