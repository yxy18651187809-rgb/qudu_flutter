import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/character_model.dart';
import '../../../data/repositories/character_repository.dart';
import '../../../core/network/network_ui_helper.dart';
import '../../../core/network/network_interceptor.dart';
import '../../../core/di/service_locator.dart';
import 'review_page.dart';

/// 识字首页
/// 功能：级别选择 + 字卡列表 + 今日复习提醒
/// API: GET /characters（列表）, GET /learning/stats/:childId（统计）
class WordLearningPage extends StatefulWidget {
  final int? initialLevel;
  final String? childId;

  const WordLearningPage({
    super.key,
    this.initialLevel,
    this.childId,
  });

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> {
  final CharacterRepository _repository = CharacterRepository();

  int _selectedLevel = 1; // 默认 L1
  List<CharacterModel> _characters = [];
  bool _isLoading = true;
  String? _error;
  int _reviewCount = 0; // 今日待复习数
  String? _currentChildId;
  bool _isOffline = false; // 网络状态
  StreamSubscription<NetworkStatus>? _networkSubscription; // 网络状态订阅

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel ?? 1;
    // 监听网络状态
    _networkSubscription = ServiceLocator.instance.apiClient.networkStatus.listen((status) {
      if (mounted) {
        setState(() {
          _isOffline = status == NetworkStatus.offline;
        });
      }
    });
    _initChildId();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initChildId() async {
    // 优先用传入的childId，否则从本地存储获取
    final childId = widget.childId ?? await StorageService.getCurrentChildId();
    if (mounted) {
      setState(() => _currentChildId = childId);
      _loadCharacters();
    }
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 并行加载：汉字列表 + 学习统计
      final results = await Future.wait([
        _repository.getCharactersByLevel(
          _selectedLevel,
          childId: _currentChildId,
        ),
        _currentChildId != null
            ? _repository.getLearningStats(_currentChildId!)
            : Future.value(null),
      ]);

      final chars = results[0] as List<CharacterModel>;
      final stats = results[1] as LearningStats?;

      if (mounted) {
        setState(() {
          _characters = chars;
          _reviewCount = stats?.dueReview ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onLevelChanged(int level) {
    if (level == _selectedLevel) return;
    setState(() => _selectedLevel = level);
    _loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isOffline) NetworkUIHelper.buildOfflineBanner(),
            _buildReviewBanner(),
            _buildLevelSelector(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // 趣趣IP头像占位
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ipBody,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('字趣识字', style: AppTypography.h3),
                Text(
                  '每日十分钟，轻松学汉字',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          // 今日进度徽章
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: AppRadius.smallBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  '$_reviewCount 待复习',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 今日复习提醒Banner
  Widget _buildReviewBanner() {
    if (_reviewCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: _reviewCount > 0
            ? () async {
                // 获取待复习汉字，跳转复习流程
                final reviewChars = await _repository.getReviewQueue(
                  _currentChildId!,
                );
                if (mounted && reviewChars.isNotEmpty) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReviewPage(
                        childId: _currentChildId!,
                        reviewCharacters: reviewChars,
                      ),
                    ),
                  );
                  _loadCharacters(); // 复习完成，刷新列表
                }
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFFFFE082)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: AppRadius.mediumBorder,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日复习',
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_reviewCount 个汉字需要复习，巩固记忆更牢固',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 级别选择器（L1-L5 横向滚动）
  Widget _buildLevelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 5,
          itemBuilder: (context, index) {
            final level = index + 1;
            final isSelected = level == _selectedLevel;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _buildLevelChip(level, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelChip(int level, bool isSelected) {
    final color = _levelColor(level);
    return GestureDetector(
      onTap: () => _onLevelChanged(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'L$level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _levelLabel(level),
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            // 进度指示
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.4)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 0.6 : 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(int level) {
    const colors = [
      AppColors.primary,      // L1 春绿
      Color(0xFF81C784),      // L2 浅绿
      AppColors.accent,       // L3 阳光黄
      AppColors.secondary,    // L4 暖粉
      AppColors.warning,      // L5 橙红
    ];
    return colors[(level - 1) % colors.length];
  }

  String _levelLabel(int level) {
    const labels = ['启蒙古', '基础', '进阶', '提高', '熟练'];
    return labels[(level - 1) % labels.length];
  }

  /// 主内容区：字卡网格
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('加载失败', style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loadCharacters,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('暂无汉字数据', style: AppTypography.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                'L$_selectedLevel ${_levelLabel(_selectedLevel)}字表',
                style: AppTypography.h3,
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _levelColor(_selectedLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  '${_characters.length}字',
                  style: AppTypography.caption.copyWith(
                    color: _levelColor(_selectedLevel),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 字卡网格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: _characters.length,
            itemBuilder: (context, index) {
              return _buildCharCard(_characters[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 单个汉字卡片
  Widget _buildCharCard(CharacterModel char) {
    return GestureDetector(
      onTap: () => _showCharDetail(char),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 汉字
            Text(
              char.character,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            // 拼音
            Text(
              char.pinyin,
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 4),
            // 状态标签
            _buildMasteryTag(char),
          ],
        ),
      ),
    );
  }

  /// 掌握度标签
  Widget _buildMasteryTag(CharacterModel char) {
    if (char.isMastered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '✓ 掌握',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (char.needsReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '复习',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '新字',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  /// 汉字详情弹窗（示例）
  void _showCharDetail(CharacterModel char) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 汉字 + 拼音
            Text(
              char.character,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              char.pinyin,
              style: AppTypography.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 基本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoChip('${char.strokeCount}画'),
                const SizedBox(width: AppSpacing.sm),
                _infoChip('${char.radical}部'),
                const SizedBox(width: AppSpacing.sm),
                _infoChip(char.structure),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 常用词
            if (char.words.isNotEmpty) ...[
              Text('常用词', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: char.words
                    .take(5)
                    .map((w) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.smallBorder,
                          ),
                          child: Text(
                            w,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // 学习按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showToast('学习功能开发中...');
                },
                child: Text(char.isNew ? '开始学习' : '继续学习'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.smallBorder,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
