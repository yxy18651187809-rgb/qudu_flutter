/// 我的 — 个人中心页
/// Tab 3 of HomeShell
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/child_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/children_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/network/network_aware_mixin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with NetworkAwareMixin {
  final ChildrenRepository _childrenRepository = ServiceLocator.instance.childrenRepository;
  List<ChildModel> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initNetworkAware(); // 初始化网络状态监听
    _loadChildren();
  }

  @override
  void dispose() {
    disposeNetworkAware(); // 取消网络状态订阅
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final children = await _childrenRepository.getChildren();
      if (mounted) {
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StorageService.clearTokens();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _children.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline) buildOfflineBannerInline(),
              _buildProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildChildSelector(),
              const SizedBox(height: AppSpacing.lg),
              _buildLearningStats(),
              const SizedBox(height: AppSpacing.lg),
              _buildSettingsSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildLearningReportSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildMonitoringSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildAboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // 头像
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: const Icon(Icons.auto_stories_rounded, size: 30, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _children.isNotEmpty ? '${_children.first.name}的账号' : '字趣阅读',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'L1 级别 · ${_children.length}个孩子',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // 编辑按钮
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/children'),
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildChildSelector() {
    if (_children.isEmpty) return const SizedBox.shrink();
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
          Text('切换孩子', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _children.map((child) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        child.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/children'),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('添加新孩子'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningStats() {
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
          const Text('学习统计', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStatItem(value: '47', label: '识字量', color: AppColors.primary),
              _ProfileStatItem(value: '3', label: '已读绘本', color: AppColors.accent),
              _ProfileStatItem(value: 'L1', label: '当前级别', color: AppColors.secondary),
              _ProfileStatItem(value: '5', label: '学习天数', color: const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningReportSection() {
    if (_children.isEmpty) return const SizedBox.shrink();
    return Container(
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('学习报告',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          _MenuRow(
            icon: Icons.bar_chart_outlined,
            title: '查看学习报告',
            titleColor: AppColors.primary,
            onTap: () {
              if (_children.isNotEmpty) {
                final child = _children.first;
                final nameParam =
                    child.name.isNotEmpty ? '&childName=${child.name}' : '';
                context.go('/learning-report?childId=${child.id}$nameParam');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringSection() {
    if (_children.isEmpty) return const SizedBox.shrink();
    return Container(
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('家长监控',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          _MenuRow(
            icon: Icons.monitor_heart_outlined,
            title: '监控概览',
            titleColor: AppColors.primary,
            onTap: () {
              // TODO: 获取真实parentId（当前用户ID）
              final parentId = 'me';
              context.go('/parent-monitoring/$parentId');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          _SettingRow(
            icon: Icons.volume_up_outlined,
            title: '音效和朗读',
            subtitle: '开启朗读拼音和音效',
            trailing: Switch.adaptive(value: true, onChanged: (_) {}),
          ),
          const Divider(height: 1, indent: 56),
          _SettingRow(
            icon: Icons.autorenew_rounded,
            title: '自动翻页',
            subtitle: '阅读时自动翻到下一页',
            trailing: Switch.adaptive(value: false, onChanged: (_) {}),
          ),
          const Divider(height: 1, indent: 56),
          _SettingRow(
            icon: Icons.timer_outlined,
            title: '每日提醒',
            subtitle: '每天固定时间提醒学习',
            trailing: Switch.adaptive(value: true, onChanged: (_) {}),
          ),
          const Divider(height: 1, indent: 56),
          _SettingRow(
            icon: Icons.wifi_outlined,
            title: '仅WiFi下载',
            subtitle: '仅在WiFi环境下下载内容',
            trailing: Switch.adaptive(value: true, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('关于', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          _MenuRow(icon: Icons.info_outline, title: '关于字趣阅读', onTap: () {}),
          const Divider(height: 1, indent: 56),
          _MenuRow(icon: Icons.description_outlined, title: '用户协议', onTap: () {}),
          const Divider(height: 1, indent: 56),
          _MenuRow(icon: Icons.privacy_tip_outlined, title: '隐私政策', onTap: () {}),
          const Divider(height: 1, indent: 56),
          _MenuRow(icon: Icons.logout, title: '退出登录', titleColor: AppColors.error, onTap: _logout),
        ],
      ),
    );
  }
}

// =============================================================================
// 子组件
// =============================================================================

class _ProfileStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProfileStatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: titleColor ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: titleColor ?? AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
