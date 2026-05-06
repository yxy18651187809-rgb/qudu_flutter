import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../widgets/phone_input_field.dart';
import '../../widgets/sms_code_field.dart';

/// 登录页
/// PRD 4.1: 手机号+验证码登录，无密码
/// 设计稿：04-设计/登录页UI设计稿_v1.md
/// API契约：03-后端/API契约文档_v1.md 第二章
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 是否可以点击登录（三项验证：手机号+验证码+协议）
  bool get _canLogin {
    final phone = _phoneController.text.replaceAll(' ', '');
    final code = _codeController.text;
    return phone.length == 11 && code.length == 6 && _agreed;
  }

  /// 发送验证码
  /// POST /api/v1/auth/sms/send
  Future<bool> _onSendCode(String phone) async {
    try {
      final expireIn = await ServiceLocator.instance.authRepository.sendSmsCode(phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('验证码已发送（有效期${expireIn ~/ 60}分钟）'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络连接失败，请检查网络'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  /// 登录
  /// POST /api/v1/auth/login
  /// 登录成功后保存Token并跳转
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意用户协议和隐私政策')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.replaceAll(' ', '');
      final code = _codeController.text;

      final loginResponse = await ServiceLocator.instance.authRepository.login(
        phone: phone,
        code: code,
      );

      // 保存Token到安全存储
      await StorageService.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn,
      );

      // 保存用户ID
      await StorageService.saveUserId(loginResponse.user.id);

      debugPrint('登录成功: userId=${loginResponse.user.id}, isNewUser=${loginResponse.isNewUser}');

      if (mounted) {
        // 新用户引导到儿童档案创建页，老用户直接进首页
        if (loginResponse.isNewUser || !loginResponse.user.hasChildren) {
          context.go('/children');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码错误，请重新输入'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildLogoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          PhoneInputField(controller: _phoneController),
                          const SizedBox(height: AppSpacing.sm),
                          SmsCodeField(
                            codeController: _codeController,
                            phoneController: _phoneController,
                            onSendCode: _onSendCode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildAgreementSection(),
                  ],
                ),
              ),
            ),
            _buildBottomHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: AppRadius.bubbleBorder,
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '字趣阅读',
          style: AppTypography.h1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading || !_canLogin ? null : _onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBorder,
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('登录 / 注册', style: AppTypography.button),
      ),
    );
  }

  Widget _buildWechatLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _onWechatLogin,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBorder,
          ),
          foregroundColor: AppColors.textPrimary,
        ),
        icon: const Icon(Icons.wechat, color: Color(0xFF07C160)),
        label: const Text('微信登录', style: AppTypography.button),
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '我已阅读并同意',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => debugPrint('打开用户协议'),
          child: Text(
            '《用户协议》',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
          ),
        ),
        Text(
          '和',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => debugPrint('打开隐私政策'),
          child: Text(
            '《隐私政策》',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          FractionallySizedBox(
            widthFactor: 0.6,
            child: const Divider(color: AppColors.border, thickness: 1),
          ),
          const SizedBox(height: 8),
          Text(
            '还没有账号？登录即注册',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
