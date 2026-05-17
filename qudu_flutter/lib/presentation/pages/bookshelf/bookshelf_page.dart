import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/book_model.dart';
import '../../../core/network/network_ui_helper.dart';
import '../../bloc/bookshelf/bookshelf_bloc.dart';
import '../../bloc/bookshelf/bookshelf_event.dart';
import '../../bloc/bookshelf/bookshelf_state.dart';

/// 绘本书架页
/// Tab 2 — 显示当前级别绘本列表，支持按级别筛选
/// TODO: 插画师设计稿到位后替换 UI 样式
class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookshelfBloc()..add(const BookshelfLoadData()),
      child: const _BookshelfView(),
    );
  }
}

class _BookshelfView extends StatelessWidget {
  const _BookshelfView();

  /// 级别选项（从 L1 到 L5）
  static const List<String> _levels = ['L1', 'L2', 'L3', 'L4', 'L5'];

  /// 级别对应的难度标签
  static const Map<String, String> _levelLabels = {
    'L1': '🌱 启蒙',
    'L2': '🌿 基础',
    'L3': '🌳 进阶',
    'L4': '🌲 提升',
    'L5': '🏔️ 挑战',
  };

  /// 点击绘本卡片 — 跳转阅读器
  void _onBookTap(BuildContext context, BookModel book) {
    context.push('/book-reader/${book.id}');
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookshelfBloc, BookshelfState>(
      listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载失败：${state.errorMessage}'), backgroundColor: AppColors.error),
          );
        }
      },
      child: BlocBuilder<BookshelfBloc, BookshelfState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  if (state.isOffline) NetworkUIHelper.buildOfflineBanner(),
                  // --- 顶部标题 + 推荐 Banner ---
                  _buildHeader(state),

                  // --- 级别筛选器 ---
                  _buildLevelFilter(state),

                  // --- 绘本网格 ---
                  Expanded(
                    child: state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          )
                        : state.books.isEmpty
                            ? _buildEmptyState(state)
                            : RefreshIndicator(
                                onRefresh: () async {
                                  context.read<BookshelfBloc>().add(const BookshelfRefreshData());
                                },
                                color: AppColors.primary,
                                child: _buildBookGrid(state),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 顶部标题区
  Widget _buildHeader(BookshelfState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 我的书架', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.recommendedBooks.isNotEmpty
                ? '为你推荐 ${state.recommendedBooks.map((b) => '《${b.title}》').join('、')}'
                : '选择级别，开始阅读',
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 级别筛选器（横向滚动）
  Widget _buildLevelFilter(BookshelfState state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = level == state.selectedLevel;
          return GestureDetector(
            onTap: () => context.read<BookshelfBloc>().add(BookshelfLevelChanged(level)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: AppRadius.mediumBorder,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _levelLabels[level] ?? level,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 绘本网格（响应式列数）
  /// 手机 ≤600dp：2列  |  平板 600–900dp：3列  |  大屏 ≥900dp：4列
  Widget _buildBookGrid(BookshelfState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount;
        double childAspectRatio;
        double padding;

        if (width >= 900) {
          // 大平板 / 桌面：4列，卡片略宽
          crossAxisCount = 4;
          childAspectRatio = 0.75;
          padding = AppSpacing.lg;
        } else if (width >= 600) {
          // 平板：3列
          crossAxisCount = 3;
          childAspectRatio = 0.72;
          padding = AppSpacing.lg;
        } else {
          // 手机：2列
          crossAxisCount = 2;
          childAspectRatio = 0.72;
          padding = AppSpacing.md;
        }

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: state.books.length,
          itemBuilder: (context, index) {
            return _BookCard(
              book: state.books[index],
              onTap: () => _onBookTap(context, state.books[index]),
            );
          },
        );
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState(BookshelfState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, size: 56, color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('暂无 ${state.selectedLevel} 级别绘本', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '敬请期待更多绘本上线~',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _BookCard — 绘本卡片组件
// 设计参考：插画师绘本02上色指南
// TODO: 插画师设计稿到位后替换为封面图+更丰富的UI
// =============================================================================
class _BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 进度百分比
    final progress = book.masteryProgress;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- 封面区（占高度65%）---
            Expanded(
              flex: 65,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: book.cover.isNotEmpty
                    ? Image.network(
                        book.cover.startsWith('http')
                            ? book.cover
                            : 'http://localhost:3000${book.cover}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress
                                              .cumulativeBytesLoaded /
                                          loadingProgress
                                              .expectedTotalBytes!
                                      : null,
                              color: _getLevelColor(book.level),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCoverPlaceholder(book);
                        },
                      )
                    : _buildCoverPlaceholder(book),
              ),
            ),

            // --- 底部信息区（占高度35%）---
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 书名
                    Text(
                      book.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 新字数标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${book.newWords.length}新字',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // 进度条
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (book.isCompleted) ...[
                              const Icon(Icons.check_circle,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    book.isCompleted
                                        ? AppColors.primary
                                        : AppColors.accent,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.isCompleted
                              ? '已读完'
                              : '${book.readCount}次阅读',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封面占位符（封面图加载失败时用）
  Widget _buildCoverPlaceholder(BookModel book) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _getLevelColor(book.level).withOpacity(0.15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 48,
            color: _getLevelColor(book.level),
          ),
          const SizedBox(height: 8),
          Text(
            book.levelLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getLevelColor(book.level),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    const colors = {
      'L1': AppColors.accent,   // 橙黄 — 启蒙
      'L2': AppColors.primary,   // 绿色 — 基础
      'L3': AppColors.secondary, // 蓝色 — 进阶
      'L4': Color(0xFF8B5CF6),  // 紫色 — 提升
      'L5': Color(0xFFEF4444),  // 红色 — 挑战
    };
    return colors[level] ?? AppColors.accent;
  }
}
