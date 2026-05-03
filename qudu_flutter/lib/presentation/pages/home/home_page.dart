/// 首页 — 学习进度总览 + 快捷入口
/// Tab 0 of HomeShell
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/learning_stats_model.dart';
import '../../../data/repositories/children_repository.dart';
import '../../../data/repositories/learning_repository.dart';
import 'home_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChildrenRepository _childrenRepository = ServiceLocator.instance.childrenRepository;
  final LearningRepository _learningRepository = ServiceLocator.instance.learningRepository;
  List<ChildModel> _children = [];
  LearningStatsModel? _stats;
  bool _isLoading = true;

  /// 学习数据（从API获取）
  int get _todayWords => _stats?.today.records ?? 0;
  int get _totalWords => (_stats?.mastery.newCount ?? 0) + (_stats?.mastery.mastered ?? 0);
  int get _todayBooks => _stats?.today.stars ?? 0;
  int get _totalBooks => _stats?.overview.totalStars ?? 0;
  int get _streakDays => _stats?.overview.streakDays ?? 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final children = await _childrenRepository.getChildren();
      if (mounted && children.isNotEmpty) {
        final stats = await _learningRepository.getStats(children.first.id);
        setState(() {
          _children = children;
          _stats = stats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ChildModel? get _activeChild => _children.isNotEmpty ? _children.first : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsGrid(),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.lg),
                _buildStreakSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildRecentActivity(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 顶部问候区
  Widget _buildHeader() {
    final childName = _activeChild?.name ?? '小朋友';
    final greeting = _getGreeting();

    return Row(
      children: [
        // 趣趣IP头像（占位）
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting，$childName！',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                '今天也要加油学汉字哦 💪',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // 设置入口
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// 学习统计网格（4个指标）
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('学习概览', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(value: '$_todayWords', label: '今日新字', color: AppColors.accent),
              _StatItem(value: '$_totalWords', label: '累计识字', color: AppColors.primary),
              _StatItem(value: '$_totalBooks', label: '获得星星', color: AppColors.secondary),
              _StatItem(value: '$_streakDays', label: '连续学习', color: const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  /// 快速操作区
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快速开始', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.menu_book_rounded,
                label: '继续阅读',
                subtitle: '上次读到这里',
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.auto_stories_rounded,
                label: '今日识字',
                subtitle: '$_todayWords个新字',
                color: AppColors.accent,
                onTap: () {
                  // 跳转到识字Tab
                  _switchToTab(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.quiz_rounded,
                label: '汉字测评',
                subtitle: '检验学习成果',
                color: AppColors.secondary,
                onTap: () {
                  final childId = _activeChild?.id;
                  if (childId == null || childId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请先添加孩子档案')),
                    );
                    return;
                  }
                  context.go(
                    '/assessment/start?childId=$childId&type=initial',
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.star_rounded,
                label: '每日挑战',
                subtitle: '${_streakDays}天连胜',
                color: const Color(0xFF8B5CF6),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 连续学习打卡
  Widget _buildStreakSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              Text('连续学习 $_streakDays 天', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isChecked = index < _streakDays % 7;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isChecked ? AppColors.primary : AppColors.disabled,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isChecked ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ['一', '二', '三', '四', '五', '六', '日'][index],
                    style: TextStyle(
                      fontSize: 10,
                      color: isChecked ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 最近动态（基于weeklyTrend数据）
  Widget _buildRecentActivity() {
    final trend = _stats?.weeklyTrend ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近学习', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mediumBorder,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: trend.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('暂无学习记录，快去学习吧！', style: AppTypography.bodySmall),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < trend.length; i++) ...[
                      if (i > 0) const Divider(height: AppSpacing.md),
                      _ActivityRow(
                        icon: Icons.auto_stories,
                        iconColor: AppColors.primary,
                        text: '${trend[i].date} 学习了${trend[i].count}个字，获得${trend[i].stars}颗星',
                        time: _formatDate(trend[i].date),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// 格式化日期为友好文本
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return '今天';
      if (diff == 1) return '昨天';
      if (diff < 7) return '$diff天前';
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /// 跳转到指定Tab
  void _switchToTab(int index) {
    final homeShell = context.findAncestorStateOfType<HomeShellState>();
    homeShell?.switchToTab(index);
  }
}

// =============================================================================
// 子组件
// =============================================================================

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
        Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }
}
