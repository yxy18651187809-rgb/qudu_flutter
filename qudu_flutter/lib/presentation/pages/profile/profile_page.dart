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
  String? _parentId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initNetworkAware(); // 初始化网络状态监听
    _loadInitData();
  }

  Future<void> _loadInitData() async {
    _parentId = await StorageService.getUserId();
    await _loadChildren();
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

  /// 注销账号
  /// 需要二次确认，调用 DELETE /api/v1/auth/account
  Future<void> _deleteAccount() async {
    // 第一次确认
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text(
          '注销账号后，您的所有数据将被永久删除，包括：\n\n'
          '• 账号信息与登录凭证\n'
          '• 儿童档案与学习记录\n'
          '• 学习报告与统计数据\n'
          '• 绘本阅读进度\n\n'
          '此操作不可撤销，确定要继续吗？',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('继续注销', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    // 第二次确认（输入"注销"二字）
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteAccountConfirmDialog(),
    );

    if (step2 != true || !mounted) return;

    // 显示加载中
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ServiceLocator.instance.authRepository.deleteAccount();
      // 清除本地所有数据
      await StorageService.clearAll();
      if (mounted) {
        Navigator.of(context).pop(); // 关闭loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账号已注销')),
        );
        Navigator.of(context).pushReplacementNamed('login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注销失败：${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
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
              final parentId = _parentId ?? '';
              if (parentId.isNotEmpty) {
                context.go('/parent-monitoring/$parentId');
              }
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
          const Divider(height: 1, indent: 56),
          _MenuRow(
            icon: Icons.delete_forever_outlined,
            title: '注销账号',
            titleColor: const Color(0xFFE53935),
            onTap: _deleteAccount,
          ),
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

/// 注销账号二次确认对话框
/// 要求用户输入"注销"以确认
class _DeleteAccountConfirmDialog extends StatefulWidget {
  @override
  State<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<_DeleteAccountConfirmDialog> {
  final _controller = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('最终确认'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '请在下方输入"注销"以确认删除账号：',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '请输入"注销"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _confirmed = value.trim() == '注销';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
          child: const Text('确认注销',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}
