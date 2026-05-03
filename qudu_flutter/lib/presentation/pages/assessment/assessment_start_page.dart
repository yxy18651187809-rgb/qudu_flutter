import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/repositories/assessment_repository.dart';
import 'assessment_question_page.dart';

/// 测评首页
/// 功能：选择级别 + 开始测评
class AssessmentStartPage extends StatefulWidget {
  final String childId;
  final AssessmentType assessmentType;
  /// 绘本ID（type=review 时必须传入）
  final String? bookId;

  const AssessmentStartPage({
    super.key,
    required this.childId,
    this.assessmentType = AssessmentType.initial,
    this.bookId,
  });

  @override
  State<AssessmentStartPage> createState() => _AssessmentStartPageState();
}

class _AssessmentStartPageState extends State<AssessmentStartPage> {
  final AssessmentRepository _repository = AssessmentRepository();

  int _selectedLevel = 1;
  int _questionCount = 20;
  bool _isLoading = false;

  // 级别信息
  static final _levelInfo = [
    (level: 1, label: 'L1 启蒙', desc: '认识基础汉字', icon: '🌱'),
    (level: 2, label: 'L2 基础', desc: '巩固常用字', icon: '🌿'),
    (level: 3, label: 'L3 进阶', desc: '扩展阅读词汇', icon: '🌳'),
    (level: 4, label: 'L4 提升', desc: '深入理解字义', icon: '🎀'),
    (level: 5, label: 'L5 挑战', desc: '无障碍阅读', icon: '🏆'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('识字测评'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLevelSelector(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuestionCountSelector(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTypeInfo(),
                  ],
                ),
              ),
            ),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.quiz_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '看看你认识多少字！',
            style: AppTypography.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '完成测评可获得星星和金币奖励',
            style: AppTypography.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择级别',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._levelInfo.map((info) {
          final isSelected = _selectedLevel == info.level;
          return _LevelCard(
            level: info.level,
            label: info.label,
            desc: info.desc,
            icon: info.icon,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedLevel = info.level),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '题目数量',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [10, 20, 30].map((count) {
            final isSelected = _questionCount == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$count题'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _questionCount = count),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeInfo() {
    final typeName = widget.assessmentType.displayName;
    final typeDesc = switch (widget.assessmentType) {
      AssessmentType.initial => '首次使用时的识字量评估，用于确定起始级别',
      AssessmentType.review => '绘本阅读后的小测验，检验新字掌握情况',
      AssessmentType.levelTest => '完成级别所有绘本后的晋级评估',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: AppRadius.mediumBorder,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  typeDesc,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startAssessment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBorder,
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('开始测评 🎯'),
      ),
    );
  }

  Future<void> _startAssessment() async {
    setState(() => _isLoading = true);

    try {
      final assessment = await _repository.startAssessment(
        childId: widget.childId,
        type: widget.assessmentType,
        targetLevel: _selectedLevel,
        questionCount: _questionCount,
        bookId: widget.bookId,
      );

      if (mounted) {
        if (assessment != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AssessmentQuestionPage(
                childId: widget.childId,
                assessment: assessment,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建测评失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String label;
  final String desc;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.label,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
