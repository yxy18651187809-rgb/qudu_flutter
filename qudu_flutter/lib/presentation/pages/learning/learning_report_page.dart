/// 学习报告页
/// 对接 LearningReportRepository API 1
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/learning_report_model.dart';
import '../../../data/repositories/learning_report_repository.dart';
import '../../../core/network/network_aware_mixin.dart';

class LearningReportPage extends StatefulWidget {
  final String childId;
  final String? childName;

  const LearningReportPage({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  State<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends State<LearningReportPage>
    with NetworkAwareMixin {
  late LearningReportRepository _repository;
  String _period = 'daily';
  LearningReportModel? _report;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initNetworkAware(); // 初始化网络状态监听
    _repository = ServiceLocator.instance.learningReportRepository;
    _loadReport();
  }

  @override
  void dispose() {
    disposeNetworkAware(); // 取消网络状态订阅
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final report = await _repository.getReport(
        childId: widget.childId,
        period: _period,
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isOffline
          ? buildOfflineAppBar(
              child: AppBar(
                title: Text('${widget.childName ?? "孩子"}的学习报告'),
                backgroundColor: AppColors.surface,
                elevation: 0,
              ),
            )
          : AppBar(
              title: Text('${widget.childName ?? "孩子"}的学习报告'),
              backgroundColor: AppColors.surface,
              elevation: 0,
            ),
      body: Column(
        children: [
          if (isOffline) buildOfflineBannerInline(),
          _buildPeriodToggle(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _report == null
                        ? const Center(child: Text('暂无数据'))
                        : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: ['daily', 'weekly', 'monthly'].map((p) {
          final isSelected = _period == p;
          final label = {'daily': '日报', 'weekly': '周报', 'monthly': '月报'}[p]!;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (_period != p) {
                    setState(() => _period = p);
                    _loadReport();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: AppRadius.mediumBorder,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(_error!,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _loadReport,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final s = _report!.statistics;
    final p = _report!.progress;
    final t = _report!.trends;
    final r = _report!.review;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计卡片
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${s.studyTime}',
                  unit: '分钟',
                  label: '学习时长',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  value: '${s.charactersLearned}',
                  unit: '个',
                  label: '识字数',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${s.booksRead}',
                  unit: '本',
                  label: '阅读绘本',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  value: '${s.averageAccuracy}',
                  unit: '%',
                  label: '平均准确率',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 识字量进度
          _buildProgressSection(p),
          const SizedBox(height: AppSpacing.lg),
          // 准确率趋势图
          if (t.accuracy.isNotEmpty) ...[
            _buildSectionTitle('准确率趋势'),
            const SizedBox(height: AppSpacing.sm),
            _buildAccuracyChart(t.accuracy),
            const SizedBox(height: AppSpacing.lg),
          ],
          // 识字量趋势图
          if (t.characters.isNotEmpty) ...[
            _buildSectionTitle('识字量趋势（最近30天）'),
            const SizedBox(height: AppSpacing.sm),
            _buildCharactersChart(t.characters),
            const SizedBox(height: AppSpacing.lg),
          ],
          // 复习状态
          if (r != null) _buildReviewSection(r),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProgressSection(LearningProgress p) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('识字进度',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('L${p.level}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  )),
              Text(' 级别',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  )),
              const Spacer(),
              Text('${p.totalCharacters}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
              Text(' 字',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (p.totalCharacters % 60) / 60.0,
            minHeight: 8,
            backgroundColor: AppColors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: AppRadius.smallBorder,
          ),
          const SizedBox(height: 4),
          Text(
            '距离 L${p.level + 1} 还需 ${p.nextLevelCharacters} 字',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart(List<AccuracyPoint> data) {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.accuracy.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 20,
                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (data.length - 1).toDouble(),
                  getTitlesWidget: (value, _) {
                    if (value.toInt() == 0) {
                      return Text(
                        data.first.date.substring(5),
                        style: TextStyle(fontSize: 10, color: AppColors.textHint),
                      );
                    }
                    if (value.toInt() == data.length - 1) {
                      return Text(
                        data.last.date.substring(5),
                        style: TextStyle(fontSize: 10, color: AppColors.textHint),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.primary,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharactersChart(List<CharactersPoint> data) {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    final maxCount = data.isNotEmpty
        ? data.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (data.length ~/ 4).toDouble().clamp(1, double.infinity),
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    if (idx % 5 == 0 || idx == data.length - 1) {
                      return Text(
                        data[idx].date.substring(5),
                        style: TextStyle(fontSize: 9, color: AppColors.textHint),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.accent,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent.withOpacity(0.3),
                      AppColors.accent.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection(LearningReview r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('复习状态',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ReviewBadge(
                count: r.due,
                label: '待复习',
                color: r.due > 0 ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _ReviewBadge(
                count: r.completed,
                label: '已完成',
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              _ReviewBadge(
                count: r.rate,
                label: '完成率%',
                color: AppColors.secondary,
                isPercent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 子组件
// =============================================================================

class _StatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool isPercent;

  const _ReviewBadge({
    required this.count,
    required this.label,
    required this.color,
    this.isPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.mediumBorder,
        ),
        child: Column(
          children: [
            Text(
              isPercent ? '$count%' : '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
