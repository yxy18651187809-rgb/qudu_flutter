/// 隐私政策同意页
/// 首次启动时展示，用户必须同意才能使用APP
/// 不同意则退出APP，不初始化任何SDK
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/storage_service.dart';

/// 隐私同意结果回调
typedef OnPrivacyConsentResult = void Function(bool agreed);

class PrivacyConsentPage extends StatelessWidget {
  final OnPrivacyConsentResult onResult;

  const PrivacyConsentPage({super.key, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        // 不同意则退出APP
        if (!didPop) {
          final exit = await _showExitDialog(context);
          if (exit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '字趣阅读',
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '5-12岁儿童AI识字阅读',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(flex: 2),
                // 隐私政策说明卡片
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Row(
                        children: [
                          const Icon(Icons.privacy_tip_outlined,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '隐私政策与用户协议',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '感谢您选择字趣阅读！在您开始使用之前，'
                        '请仔细阅读并同意以下协议：\n\n'
                        '• 《用户协议》 — 规定了我们的服务条款、'
                        '权利义务和责任限制\n\n'
                        '• 《隐私政策》 — 说明我们如何收集、使用、'
                        '存储和保护您的个人信息\n\n'
                        '• 《儿童隐私保护声明》 — 我们特别重视'
                        '儿童隐私，遵守相关法律法规\n\n'
                        '我们会申请以下权限为您提供更好的服务：\n'
                        '• 网络访问：用于数据传输和内容更新\n'
                        '• 存储权限：用于缓存学习内容\n'
                        '• 麦克风（可选）：用于语音评测功能',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                // 按钮区
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _onAgree(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mediumBorder,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('同意并继续', style: AppTypography.button),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _onDisagree(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mediumBorder,
                      ),
                    ),
                    child: const Text('不同意并退出'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '不同意隐私政策将无法使用本应用',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAgree(BuildContext context) async {
    await StorageService.setPrivacyConsent(true);
    onResult(true);
  }

  Future<void> _onDisagree(BuildContext context) async {
    final exit = await _showExitDialog(context);
    if (exit == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('温馨提示'),
        content: const Text(
          '您需要同意隐私政策才能使用字趣阅读。\n\n确定要退出应用吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出应用',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
