import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/repositories/assessment_repository.dart';
import 'assessment_result_page.dart';

/// 答题页面
/// 功能：根据题型动态渲染UI + 提交答案 + 显示结果
class AssessmentQuestionPage extends StatefulWidget {
  final String childId;
  final AssessmentModel assessment;

  const AssessmentQuestionPage({
    super.key,
    required this.childId,
    required this.assessment,
  });

  @override
  State<AssessmentQuestionPage> createState() => _AssessmentQuestionPageState();
}

class _AssessmentQuestionPageState extends State<AssessmentQuestionPage> {
  late AssessmentModel _assessment;
  int _currentIndex = 0;
  bool _isAnswering = false;
  bool? _lastAnswerCorrect;
  final _repository = AssessmentRepository();
  final _audioPlayer = AudioPlayer(); // 音频播放器
  DateTime _questionStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _assessment = widget.assessment;
    _questionStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 释放资源
    super.dispose();
  }

  AssessmentQuestion get _currentQuestion => _assessment.questions[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: _buildQuestionContent(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('测评 ${_currentIndex + 1}/${_assessment.questions.length}'),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _confirmExit,
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / _assessment.questions.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '进度',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTypography.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = _currentQuestion;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // 题型提示
          _buildQuestionPrompt(question),
          const SizedBox(height: AppSpacing.xl),
          // 题目内容区
          Expanded(
            child: _buildQuestionBody(question),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 选项区
          _buildOptions(question),
          const SizedBox(height: AppSpacing.md),
          // 答案反馈
          if (_lastAnswerCorrect != null) _buildAnswerFeedback(),
        ],
      ),
    );
  }

  Widget _buildQuestionPrompt(AssessmentQuestion question) {
    final promptText = switch (question.questionType) {
      QuestionType.recognize => '看字选图',
      QuestionType.pinyinMatch => '听音选字',
      QuestionType.meaningSelect => '看图选字',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: AppRadius.mediumBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (question.questionType) {
              QuestionType.recognize => Icons.visibility,
              QuestionType.pinyinMatch => Icons.volume_up,
              QuestionType.meaningSelect => Icons.image,
            },
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            promptText,
            style: AppTypography.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBody(AssessmentQuestion question) {
    return switch (question.questionType) {
      QuestionType.recognize => _buildRecognizeBody(question),
      QuestionType.pinyinMatch => _buildPinyinMatchBody(question),
      QuestionType.meaningSelect => _buildMeaningSelectBody(question),
    };
  }

  // 题型1：看字选图 - 显示汉字，选择对应图片
  Widget _buildRecognizeBody(AssessmentQuestion question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 汉字大卡片
        GestureDetector(
          onTap: () => _playCharacterAudio(question),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.largeBorder,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                question.character,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '点击汉字听发音',
          style: AppTypography.caption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  // 题型2：听音选字 - 播放拼音/语音，选择正确汉字
  Widget _buildPinyinMatchBody(AssessmentQuestion question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 播放按钮
        GestureDetector(
          onTap: () => _playQuestionAudio(question),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              size: 48,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '点击播放按钮听发音',
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '找到正确的汉字',
          style: AppTypography.caption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  // 题型3：看图选字 - 显示图片，选择对应汉字
  Widget _buildMeaningSelectBody(AssessmentQuestion question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 图片展示区
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.largeBorder,
          ),
          child: Center(
            child: Icon(
              Icons.image_rounded,
              size: 80,
              color: AppColors.textHint.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '这是什么字？',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildOptions(AssessmentQuestion question) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.center,
            children: question.options.map((option) {
        final isSelected = question.userAnswer == option;
        final showResult = _lastAnswerCorrect != null;

        return _OptionButton(
          option: option,
          isSelected: isSelected,
          showResult: showResult,
          isCorrect: showResult && _lastAnswerCorrect == true && isSelected,
          isWrong: showResult && _lastAnswerCorrect == false && isSelected,
          onTap: _isAnswering ? null : () => _selectAnswer(option),
        );
      }).toList(),
    );
  }

  // 播放汉字发音
  Future<void> _playCharacterAudio(AssessmentQuestion question) async {
    final url = question.audioUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('音频暂未配置')),
        );
      }
      return;
    }

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败：$e')),
        );
      }
    }
  }

  // 播放题目音频（用于听音选字题型）
  Future<void> _playQuestionAudio(AssessmentQuestion question) async {
    final url = question.audioUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('音频暂未配置')),
        );
      }
      return;
    }

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败：$e')),
        );
      }
    }
  }

  Widget _buildAnswerFeedback() {
    if (_lastAnswerCorrect == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _lastAnswerCorrect!
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: AppRadius.mediumBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _lastAnswerCorrect! ? Icons.check_circle : Icons.refresh,
            color: _lastAnswerCorrect! ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _lastAnswerCorrect! ? '太棒了！⭐' : '再试试？',
            style: AppTypography.body.copyWith(
              color: _lastAnswerCorrect! ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastQuestion = _currentIndex >= _assessment.questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_lastAnswerCorrect != null && !isLastQuestion)
            Expanded(
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mediumBorder,
                  ),
                ),
                child: const Text('下一题'),
              ),
            ),
          if (_lastAnswerCorrect != null && isLastQuestion)
            Expanded(
              child: ElevatedButton(
                onPressed: _submitAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mediumBorder,
                  ),
                ),
                child: const Text('查看结果'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectAnswer(String answer) async {
    if (_isAnswering) return;

    setState(() => _isAnswering = true);

    final responseTime = DateTime.now().difference(_questionStartTime).inMilliseconds;

    setState(() {
      _currentQuestion.userAnswer = answer;
      _currentQuestion.responseTime = responseTime;
      // 根据正确答案判断（如果后端返回了correctAnswer）
      if (_currentQuestion.correctAnswer != null) {
        _lastAnswerCorrect = (answer == _currentQuestion.correctAnswer);
      } else {
        // 后端未返回正确答案时，暂时显示"已提交"，提交后查看结果
        _lastAnswerCorrect = null;
      }
      _isAnswering = false;
    });
  }

  void _nextQuestion() {
    setState(() {
      _lastAnswerCorrect = null;
      _currentIndex++;
      _questionStartTime = DateTime.now();
    });
  }

  Future<void> _submitAssessment() async {
    setState(() => _isAnswering = true);

    try {
      final answers = _assessment.questions.map((q) {
        return AssessmentAnswer(
          characterId: q.characterId,
          userAnswer: q.userAnswer ?? '',
          responseTime: q.responseTime,
        );
      }).toList();

      final duration = DateTime.now().difference(_assessment.startedAt).inSeconds;

      final result = await _repository.submitAnswers(
        assessmentId: _assessment.assessmentId,
        answers: answers,
        duration: duration,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AssessmentResultPage(
              assessment: _assessment,
              result: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnswering = false);
      }
    }
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出测评？'),
        content: const Text('退出后当前进度将不会保存'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续测评'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _OptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool showResult;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.option,
    required this.isSelected,
    required this.showResult,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color borderColor = AppColors.border;
    Widget? trailing;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppColors.success.withOpacity(0.2);
        borderColor = AppColors.success;
        trailing = const Icon(Icons.check_circle, color: AppColors.success, size: 20);
      } else if (isWrong) {
        bgColor = AppColors.error.withOpacity(0.2);
        borderColor = AppColors.error;
        trailing = const Icon(Icons.close, color: AppColors.error, size: 20);
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withOpacity(0.2);
      borderColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.surface,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(color: borderColor, width: isSelected || showResult ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                option,
                style: AppTypography.body.copyWith(
                  color: isSelected || showResult ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
