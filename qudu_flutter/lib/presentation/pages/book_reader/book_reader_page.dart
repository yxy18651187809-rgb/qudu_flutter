import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/repositories/book_reader_repository.dart';
import '../assessment/assessment_start_page.dart';

/// 绘本阅读器主页面
/// 功能：全屏翻页 + 文字标注 + 新字高亮 + 阅读进度 + 阅读完成记录
/// TODO：插画师设计稿到位后替换 UI 样式（参考04-设计/绘本阅读器UI设计稿_v1.md）
class BookReaderPage extends StatefulWidget {
  /// 绘本ID
  final String bookId;
  /// 儿童ID（用于记录进度）
  final String? childId;

  const BookReaderPage({
    super.key,
    required this.bookId,
    this.childId,
  });

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage>
    with SingleTickerProviderStateMixin {
  final BookReaderRepository _repository = BookReaderRepository();

  // 状态
  BookDetailModel? _bookDetail;
  int _currentPageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;

  // 动画
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 新字集合（用于标记）
  late Set<String> _newWordSet;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadBookDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _repository.getBookDetail(
        widget.bookId,
        childId: widget.childId,
      );
      if (mounted) {
        setState(() {
          _bookDetail = detail;
          _newWordSet = detail?.newWords.toSet() ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败：$e';
          _isLoading = false;
        });
      }
    }
  }

  /// 翻到下一页
  void _goToNextPage() {
    if (_bookDetail == null) return;
    if (_currentPageIndex >= _bookDetail!.pages.length - 1) {
      _showCompletionDialog();
      return;
    }
    _animateToPage(_currentPageIndex + 1);
  }

  /// 翻到上一页
  void _goToPrevPage() {
    if (_currentPageIndex <= 0) return;
    _animateToPage(_currentPageIndex - 1);
  }

  void _animateToPage(int index) {
    _fadeController.reverse().then((_) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _fadeController.forward();
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  /// 显示阅读完成对话框
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompletionDialog(
        bookTitle: _bookDetail?.title ?? '',
        newWordCount: _bookDetail?.newWordCount ?? 0,
        masteredCount: _bookDetail?.masteredCount ?? 0,
        onStartAssessment: () {
          Navigator.of(context).pop();
          _recordAndNavigate();
        },
        onFinish: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _recordAndNavigate() async {
    // 记录阅读完成
    if (widget.childId != null && _bookDetail != null) {
      await _repository.recordLearning(
        childId: widget.childId!,
        bookId: widget.bookId,
        pagesRead: _bookDetail!.pages.length,
      );
    }
    // 跳转到测评页
    if (mounted && widget.childId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AssessmentStartPage(
            childId: widget.childId!,
            assessmentType: AssessmentType.review,
            bookId: widget.bookId,
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }
    if (_errorMessage != null) {
      return _buildError();
    }
    if (_bookDetail == null || _bookDetail!.pages.isEmpty) {
      return _buildEmpty();
    }
    return _buildReader();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('正在加载绘本...', style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMessage!, style: AppTypography.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadBookDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回书架'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book, size: 56, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text('暂无绘本内容', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回书架'),
          ),
        ],
      ),
    );
  }

  Widget _buildReader() {
    final pages = _bookDetail!.pages;
    final isLastPage = _currentPageIndex >= pages.length - 1;

    return Stack(
      children: [
        // --- 全屏翻页内容 ---
        GestureDetector(
          onTap: _toggleControls,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
            },
            itemBuilder: (context, index) {
              return _ReaderPageView(
                page: pages[index],
                newWordSet: _newWordSet,
                isLastPage: index == pages.length - 1,
              );
            },
          ),
        ),

        // --- 顶部控制栏 ---
        if (_showControls)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildTopBar(pages.length),
          ),

        // --- 底部导航栏 ---
        if (_showControls)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildBottomBar(pages.length, isLastPage),
          ),

        // --- 左右翻页按钮 ---
        if (_showControls) ...[
          // 左翻页
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 60,
            child: GestureDetector(
              onTap: _currentPageIndex > 0 ? _goToPrevPage : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: _currentPageIndex > 0
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                      )
                    : null,
              ),
            ),
          ),
          // 右翻页
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 60,
            child: GestureDetector(
              onTap: _goToNextPage,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLastPage ? Icons.check_circle : Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 顶部栏
  Widget _buildTopBar(int totalPages) {
    final progress = (_currentPageIndex + 1) / totalPages;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // 第一行：关闭按钮 + 书名 + 页码
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  // 关闭按钮
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: '返回',
                  ),
                  const SizedBox(width: 4),
                  // 书名
                  Expanded(
                    child: Text(
                      _bookDetail?.title ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 页码
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPageIndex + 1} / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 进度条
            SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部导航栏
  Widget _buildBottomBar(int totalPages, bool isLastPage) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上一页按钮
            TextButton.icon(
              onPressed: _currentPageIndex > 0 ? _goToPrevPage : null,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
              label: const Text('上一页', style: TextStyle(color: Colors.white)),
            ),
            // 页码指示器
            totalPages > 10
                ? Text(
                    '${_currentPageIndex + 1} / $totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                totalPages,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPageIndex ? 8 : 6,
                  height: index == _currentPageIndex ? 8 : 6,
                  decoration: BoxDecoration(
                    color: index == _currentPageIndex
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // 下一页/完成按钮
            TextButton.icon(
              onPressed: _goToNextPage,
              icon: Icon(
                isLastPage ? Icons.check : Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                isLastPage ? '完成阅读' : '下一页',
                style: const TextStyle(color: Colors.white),
              ),
              style: isLastPage
                  ? TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ReaderPageView — 单页内容展示
// =============================================================================
class _ReaderPageView extends StatelessWidget {
  final BookPage page;
  final Set<String> newWordSet;
  final bool isLastPage;

  const _ReaderPageView({
    required this.page,
    required this.newWordSet,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // --- 插画区（占60%）---
          Expanded(
            flex: 60,
            child: _buildIllustration(),
          ),
          // --- 文字区（占40%）---
          Expanded(
            flex: 40,
            child: _buildTextArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.largeBorder,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 插画占位图（插画师交付后替换）
            if (page.image.isNotEmpty)
              Image.network(
                page.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildIllustrationPlaceholder(),
              )
            else
              _buildIllustrationPlaceholder(),
            // 图片描述浮动标签
            if (page.imageDescription.isNotEmpty)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    page.imageDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationPlaceholder() {
    // 根据绘本月度生成不同的背景色
    final colors = [
      AppColors.accent.withOpacity(0.3),
      AppColors.primaryLight.withOpacity(0.3),
      AppColors.secondary.withOpacity(0.3),
    ];
    final colorIndex = page.pageNumber % colors.length;

    return Container(
      color: colors[colorIndex],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              '第 ${page.pageNumber} 页',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '插画待交付',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediumBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拼音行（带声调符号）
          if (page.pinyin.isNotEmpty) ...[
            Text(
              page.pinyin,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
          ],
          // 正文（带新字高亮）
          Expanded(
            child: SingleChildScrollView(
              child: _buildHighlightedText(),
            ),
          ),
          // 教学提示
          if (page.teachingNote != null && page.teachingNote!.isNotEmpty) ...[
            const Divider(height: 12),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    page.teachingNote!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 带新字高亮的文字
  Widget _buildHighlightedText() {
    if (page.wordAnnotations.isEmpty) {
      return Text(
        page.text,
        style: const TextStyle(
          fontSize: 20,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      );
    }

    // 按字构建富文本
    final spans = <TextSpan>[];
    final chars = page.text.split('');

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      // 查找该字的标注
      final annotation = page.wordAnnotations.cast<WordAnnotation?>().firstWhere(
        (a) => a?.character == char,
        orElse: () => null,
      );

      final isNewWord = annotation?.isNewWord ?? false;
      final style = annotation?.highlightStyle ?? 'color';

      if (isNewWord) {
        // 新字：黄色背景 + 橙色文字
        spans.add(TextSpan(
          text: char,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: style.contains('color') ? AppColors.newWordText : AppColors.textPrimary,
            backgroundColor: style.contains('underline')
                ? null
                : AppColors.newWordBubble,
            decoration: style.contains('underline')
                ? TextDecoration.underline
                : null,
            decorationColor: AppColors.newWordText,
            decorationThickness: 2,
            height: 1.6,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: char,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// =============================================================================
// _CompletionDialog — 阅读完成对话框
// =============================================================================
class _CompletionDialog extends StatelessWidget {
  final String bookTitle;
  final int newWordCount;
  final int masteredCount;
  final VoidCallback onStartAssessment;
  final VoidCallback onFinish;

  const _CompletionDialog({
    required this.bookTitle,
    required this.newWordCount,
    required this.masteredCount,
    required this.onStartAssessment,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 星星/庆祝图标
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🎉 读完啦！',
              style: AppTypography.h2.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '《$bookTitle》',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // 学习数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: '新字', value: '+$newWordCount', color: AppColors.accent),
                _StatChip(label: '已掌握', value: '$masteredCount', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            // 按钮组
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStartAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('开始测评 ✏️', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onFinish,
              child: const Text('稍后测评'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
