import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/character_model.dart';
import '../../../data/repositories/character_repository.dart';

/// 复习流程页面
/// 功能：逐个显示复习字，用户标记"已掌握"/"还需练习"
class ReviewPage extends StatefulWidget {
  final String childId;
  final List<CharacterModel> reviewCharacters;

  const ReviewPage({
    super.key,
    required this.childId,
    required this.reviewCharacters,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late CharacterRepository _repository;
  late List<CharacterModel> _chars;
  int _currentIndex = 0;
  bool _isSubmiting = false;

  @override
  void initState() {
    super.initState();
    _repository = CharacterRepository();
    _chars = List.from(widget.reviewCharacters);
  }

  @override
  Widget build(BuildContext context) {
    if (_chars.isEmpty) {
      return _buildEmptyState();
    }

    final char = _chars[_currentIndex];
    final isLast = _currentIndex >= _chars.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('复习（${_currentIndex + 1}/${_chars.length}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 进度条
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _chars.length,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
            Expanded(
              child: _buildCharacterView(char),
            ),
            _buildActionBar(char, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterView(CharacterModel char) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 汉字大字卡
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                char.character,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 拼音
          Text(
            char.pinyin,
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          // 组词
          if (char.words.isNotEmpty)
            Text(
              '组词：${char.words.join('、')}',
              style: AppTypography.body.copyWith(color: AppColors.textHint),
            ),
          const SizedBox(height: AppSpacing.md),
          // 例句
          if (char.sentences != null && char.sentences!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                char.sentences!.first,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(CharacterModel char, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmiting ? null : () => _handleReview(char, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorder,
                    ),
                  ),
                  child: const Text('还需练习'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmiting ? null : () => _handleReview(char, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorder,
                    ),
                  ),
                  child: const Text('已掌握'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleReview(CharacterModel char, bool mastered) async {
    setState(() => _isSubmiting = true);

    try {
      // 更新掌握度
      final newMastery = mastered
          ? (char.mastery + 0.3).clamp(0.0, 1.0)
          : (char.mastery - 0.1).clamp(0.0, 1.0);

      await _repository.updateCharacterMastery(
        childId: widget.childId,
        characterId: char.id,
        mastery: newMastery,
        isReview: false, // 复习完成后清除复习标记
      );

      if (mounted) {
        setState(() {
          if (_currentIndex < _chars.length - 1) {
            _currentIndex++;
          } else {
            // 全部复习完成
            _showCompletionDialog();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmiting = false);
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('复习完成！'),
        content: Text('本次共复习 ${_chars.length} 个汉字，继续加油！'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('完成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('复习'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.success.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '暂无复习汉字',
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
