/// 家长监控页
/// 对接家长监控 API（4个接口）
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/parent_monitoring_model.dart';
import '../../../data/repositories/parent_monitoring_repository.dart';

class ParentMonitoringPage extends StatefulWidget {
  final String parentId;
  const ParentMonitoringPage({
    super.key,
    required this.parentId,
  });

  @override
  State<ParentMonitoringPage> createState() => _ParentMonitoringPageState();
}

class _ParentMonitoringPageState extends State<ParentMonitoringPage> {
  final ParentMonitoringRepository _repository =
      ServiceLocator.instance.parentMonitoringRepository;
  MonitoringOverview? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _repository.getOverview(parentId: widget.parentId);
      if (mounted) {
        setState(() {
          _overview = overview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  void _navigateToChildDetail(MonitoringChildOverview child) {
    context.push(
      '/parent-monitoring/${widget.parentId}/child/${child.childId}',
      extra: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家长监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverview,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _overview == null
              ? const Center(child: Text('暂无数据'))
              : _buildOverview(),
    );
  }

  Widget _buildOverview() {
    final children = _overview!.children;
    if (children.isEmpty) {
      return const Center(child: Text('暂未添加孩子'));
    }
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, index) {
          final child = children[index];
          return _ChildOverviewCard(
            child: child,
            onTap: () => _navigateToChildDetail(child),
          );
        },
      ),
    );
  }
}

class _ChildOverviewCard extends StatelessWidget {
  final MonitoringChildOverview child;
  final VoidCallback onTap;

  const _ChildOverviewCard({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = child.today;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 孩子名称 + 头像
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: child.avatarUrl.isNotEmpty
                        ? NetworkImage(child.avatarUrl)
                        : null,
                    child: child.avatarUrl.isEmpty
                        ? Text(child.childName.isNotEmpty
                            ? child.childName[0]
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      child.childName,
                      style: AppTypography.h3,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // 今日数据
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: '学习时长',
                    value: '${today.studyTime}分钟',
                  ),
                  _StatItem(
                    label: '识字数',
                    value: '${today.charactersLearned}个',
                  ),
                  _StatItem(
                    label: '准确率',
                    value: today.accuracy > 0
                        ? '${today.accuracy}%'
                        : '--',
                  ),
                ],
              ),

              // 告警信息
              if (child.alerts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ...child.alerts.map((alert) => _AlertItem(alert: alert)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.h3),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

class _AlertItem extends StatelessWidget {
  final MonitoringAlert alert;

  const _AlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isWarning = alert.severity == 'warning';
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_amber : Icons.info,
            size: 16,
            color: isWarning ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              alert.message,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
