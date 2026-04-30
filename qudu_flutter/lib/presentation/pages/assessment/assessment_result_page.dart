import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/assessment_model.dart';

/// 测评结果页
/// 功能：显示正确率、新字掌握情况、鼓励动画、奖励
class AssessmentResultPage extends StatefulWidget {
  final AssessmentModel assessment;
  final AssessmentResult? result;

  const AssessmentResultPage({
    super.key,
    required this.assessment,
    this.result,
  });

  @override
  State<AssessmentResultPage> createState() => _AssessmentResultPageState();
}

class _AssessmentResultPageState extends State<AssessmentResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final accuracy = result?.accuracy ?? 0;
    final correctCount = result?.correctCount ?? 0;
    final totalCount = result?.totalCount ?? widget.assessment.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _buildCelebration(accuracy),
                    const SizedBox(height: AppSpacing.xl),
                    _buildScoreCard(correctCount, totalCount, accuracy),
                    const SizedBox(height: AppSpacing.lg),
                    if (result != null) _buildRewardCard(result),
                    const SizedBox(height: AppSpacing.lg),
                    if (result != null) _buildLevelInfo(result),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebration(int accuracy) {
    final message = accuracy >= 80
        ? '太棒了！'
        : accuracy >= 60
            ? '不错哦！'
            : '继续加油！';

    final emoji = accuracy >= 80
        ? '🎉'
        : accuracy >= 60
            ? '😊'
            : '💪';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.h2.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int correct, int total, int accuracy) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.largeBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '答题结果',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreItem(
                  label: '答对',
                  value: '$correct',
                  unit: '题',
                  color: AppColors.success,
                ),
                _ScoreItem(
                  label: '总题数',
                  value: '$total',
                  unit: '题',
                  color: AppColors.textSecondary,
                ),
                _ScoreItem(
                  label: '正确率',
                  value: '$accuracy',
                  unit: '%',
                  color: accuracy >= 80
                      ? AppColors.success
                      : accuracy >= 60
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(AssessmentResult result) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.1),
              AppColors.primary.withOpacity(0.1),
            ],
          ),
          borderRadius: AppRadius.largeBorder,
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '获得奖励',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RewardItem(
                  icon: Icons.star_rounded,
                  color: AppColors.accent,
                  value: '${result.starsEarned}',
                  label: '星星',
                ),
                _RewardItem(
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.warning,
                  value: '${result.coinsEarned}',
                  label: '金币',
                ),
                _RewardItem(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.primary,
                  value: '${result.estimatedWordCount}',
                  label: '识字量',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelInfo(AssessmentResult result) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorder,
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推荐级别',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'L${result.recommendedLevel}',
                    style: AppTypography.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Text(
              '继续加油！',
              style: AppTypography.body.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mediumBorder,
                ),
              ),
              child: const Text('返回首页'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              // 重新开始测评
              Navigator.of(context).pop();
            },
            child: const Text('再测一次'),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _RewardItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
