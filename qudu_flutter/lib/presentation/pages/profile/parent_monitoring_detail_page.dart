/// 家长监控 - 孩子详情页
/// API 6：获取单个孩子的监控详情
/// API 7：更新监控阈值
/// API 8：更新告警设置
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/parent_monitoring_model.dart';
import '../../../data/repositories/parent_monitoring_repository.dart';

class ParentMonitoringDetailPage extends StatefulWidget {
  final String parentId;
  final String childId;
  final MonitoringChildOverview? overview; // 从概览页传入

  const ParentMonitoringDetailPage({
    super.key,
    required this.parentId,
    required this.childId,
    this.overview,
  });

  @override
  State<ParentMonitoringDetailPage> createState() =>
      _ParentMonitoringDetailPageState();
}

class _ParentMonitoringDetailPageState extends State<ParentMonitoringDetailPage> {
  final ParentMonitoringRepository _repository =
      ServiceLocator.instance.parentMonitoringRepository;

  ChildMonitoringDetail? _detail;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _repository.getChildDetail(
        parentId: widget.parentId,
        childId: widget.childId,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
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

  Future<void> _saveThresholds() async {
    if (_detail == null) return;
    setState(() => _isSaving = true);
    try {
      await _repository.updateThresholds(
        parentId: widget.parentId,
        childId: widget.childId,
        maxDailyStudyTime: _detail!.thresholds.maxDailyStudyTime,
        minDailyStudyTime: _detail!.thresholds.minDailyStudyTime,
        minCharactersPerDay: _detail!.thresholds.minCharactersPerDay,
        minAccuracy: _detail!.thresholds.minAccuracy,
        maxReviewDelayDays: _detail!.thresholds.maxReviewDelayDays,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('阈值已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName = widget.overview?.childName ?? _detail?.childName ?? '未知';

    return Scaffold(
      appBar: AppBar(
        title: Text('$childName 的监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('暂无数据'))
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final d = _detail!;
    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 今日数据
          _SectionTitle('今日数据'),
          _TodayStats(today: d.today),
          const SizedBox(height: AppSpacing.md),

          // 本周均值
          _SectionTitle('本周均值'),
          _WeeklyStats(weekly: d.weekly),
          const SizedBox(height: AppSpacing.md),

          // 监控阈值设置
          _SectionTitle('监控阈值'),
          _ThresholdEditor(
            thresholds: d.thresholds,
            onChanged: (t) {
              setState(() => _detail = ChildMonitoringDetail(
                    childId: d.childId,
                    childName: d.childName,
                    thresholds: t,
                    today: d.today,
                    weekly: d.weekly,
                    alertSettings: d.alertSettings,
                  ));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveThresholds,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存阈值'),
          ),
          const SizedBox(height: AppSpacing.md),

          // 告警设置
          _SectionTitle('告警方式'),
          _AlertSettingsEditor(
            settings: d.alertSettings,
            onSaved: (s) async {
              setState(() => _isSaving = true);
              try {
                await _repository.updateAlertSettings(
                  parentId: widget.parentId,
                  enableStudyTimeAlert: s.enableStudyTimeAlert,
                  enableAccuracyAlert: s.enableAccuracyAlert,
                  enableReviewAlert: s.enableReviewAlert,
                  alertMethods: s.alertMethods,
                );
                if (mounted) {
                  setState(() => _detail = ChildMonitoringDetail(
                        childId: d.childId,
                        childName: d.childName,
                        thresholds: d.thresholds,
                        today: d.today,
                        weekly: d.weekly,
                        alertSettings: s,
                      ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('告警设置已更新')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存失败：$e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(title, style: AppTypography.h3),
    );
  }
}

class _TodayStats extends StatelessWidget {
  final MonitoringToday today;
  const _TodayStats({required this.today, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _StatRow('学习时长', '${today.studyTime}分钟'
                '${today.studyTime < today.minCharacters ? '⚠️' : '✅'}'),
            _StatRow('识字数', '${today.charactersLearned}个'
                '${today.charactersLearned < today.minCharacters ? '⚠️' : '✅'}'),
            _StatRow('准确率', today.accuracy > 0
                ? '${today.accuracy}%'
                    '${today.accuracy < today.minAccuracy ? '⚠️' : '✅'}'
                : '--'),
            _StatRow('待复习', '${today.reviewDue}个'),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStats extends StatelessWidget {
  final MonitoringWeekly weekly;
  const _WeeklyStats({required this.weekly, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _StatRow('日均学习时长', '${weekly.averageStudyTime}分钟'),
            _StatRow('日均识字数', '${weekly.averageCharacters}个'),
            _StatRow('平均准确率', '${weekly.averageAccuracy}%'),
            _StatRow('复习完成率', '${weekly.reviewCompletionRate}%'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ThresholdEditor extends StatefulWidget {
  final MonitoringThresholds thresholds;
  final ValueChanged<MonitoringThresholds> onChanged;

  const _ThresholdEditor({
    required this.thresholds,
    required this.onChanged,
    super.key,
  });

  @override
  State<_ThresholdEditor> createState() => _ThresholdEditorState();
}

class _ThresholdEditorState extends State<_ThresholdEditor> {
  late int _maxStudy;
  late int _minStudy;
  late int _minChars;
  late int _minAcc;
  late int _maxReview;

  @override
  void initState() {
    super.initState();
    _maxStudy = widget.thresholds.maxDailyStudyTime;
    _minStudy = widget.thresholds.minDailyStudyTime;
    _minChars = widget.thresholds.minCharactersPerDay;
    _minAcc = widget.thresholds.minAccuracy;
    _maxReview = widget.thresholds.maxReviewDelayDays;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _SliderRow(
              label: '每日最长学习时长',
              value: _maxStudy.toDouble(),
              min: 0,
              max: 480,
              unit: '分钟',
              onChanged: (v) {
                setState(() => _maxStudy = v.round());
                widget.onChanged(MonitoringThresholds(
                  maxDailyStudyTime: _maxStudy,
                  minDailyStudyTime: _minStudy,
                  minCharactersPerDay: _minChars,
                  minAccuracy: _minAcc,
                  maxReviewDelayDays: _maxReview,
                ));
              },
            ),
            _SliderRow(
              label: '每日最短学习时长',
              value: _minStudy.toDouble(),
              min: 0,
              max: 120,
              unit: '分钟',
              onChanged: (v) {
                setState(() => _minStudy = v.round());
                widget.onChanged(MonitoringThresholds(
                  maxDailyStudyTime: _maxStudy,
                  minDailyStudyTime: _minStudy,
                  minCharactersPerDay: _minChars,
                  minAccuracy: _minAcc,
                  maxReviewDelayDays: _maxReview,
                ));
              },
            ),
            _SliderRow(
              label: '每日最少识字数',
              value: _minChars.toDouble(),
              min: 0,
              max: 50,
              unit: '个',
              onChanged: (v) {
                setState(() => _minChars = v.round());
                widget.onChanged(MonitoringThresholds(
                  maxDailyStudyTime: _maxStudy,
                  minDailyStudyTime: _minStudy,
                  minCharactersPerDay: _minChars,
                  minAccuracy: _minAcc,
                  maxReviewDelayDays: _maxReview,
                ));
              },
            ),
            _SliderRow(
              label: '最低准确率',
              value: _minAcc.toDouble(),
              min: 0,
              max: 100,
              unit: '%',
              onChanged: (v) {
                setState(() => _minAcc = v.round());
                widget.onChanged(MonitoringThresholds(
                  maxDailyStudyTime: _maxStudy,
                  minDailyStudyTime: _minStudy,
                  minCharactersPerDay: _minChars,
                  minAccuracy: _minAcc,
                  maxReviewDelayDays: _maxReview,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text('${value.round()}$unit',
                style: AppTypography.bodySmall),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min) > 0 ? (max - min).round() : null,
          label: '${value.round()}$unit',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AlertSettingsEditor extends StatefulWidget {
  final MonitoringAlertSettings settings;
  final ValueChanged<MonitoringAlertSettings> onSaved;

  const _AlertSettingsEditor({
    required this.settings,
    required this.onSaved,
    super.key,
  });

  @override
  State<_AlertSettingsEditor> createState() => _AlertSettingsEditorState();
}

class _AlertSettingsEditorState extends State<_AlertSettingsEditor> {
  late bool _enableStudy;
  late bool _enableAccuracy;
  late bool _enableReview;
  late List<String> _methods;

  final _availableMethods = const ['push', 'sms', 'wechat'];

  @override
  void initState() {
    super.initState();
    _enableStudy = widget.settings.enableStudyTimeAlert;
    _enableAccuracy = widget.settings.enableAccuracyAlert;
    _enableReview = widget.settings.enableReviewAlert;
    _methods = List.from(widget.settings.alertMethods);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('学习时长告警'),
              value: _enableStudy,
              onChanged: (v) => setState(() => _enableStudy = v),
            ),
            SwitchListTile(
              title: const Text('准确率告警'),
              value: _enableAccuracy,
              onChanged: (v) => setState(() => _enableAccuracy = v),
            ),
            SwitchListTile(
              title: const Text('复习告警'),
              value: _enableReview,
              onChanged: (v) => setState(() => _enableReview = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('告警方式：'),
            ..._availableMethods.map((m) => CheckboxListTile(
                  title: Text(m),
                  value: _methods.contains(m),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _methods.add(m);
                      } else {
                        _methods.remove(m);
                      }
                    });
                  },
                )),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => widget.onSaved(MonitoringAlertSettings(
                enableStudyTimeAlert: _enableStudy,
                enableAccuracyAlert: _enableAccuracy,
                enableReviewAlert: _enableReview,
                alertMethods: _methods,
              )),
              child: const Text('保存告警设置'),
            ),
          ],
        ),
      ),
    );
  }
}
