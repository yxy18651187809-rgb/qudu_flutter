import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/phone_input_field.dart';
import '../../widgets/sms_code_field.dart';

/// 登录页
/// PRD 4.1: 手机号+验证码登录，无密码
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

  /// 发送验证码
  Future<bool> _onSendCode(String phone) async {
    try {
      // TODO: 调用API POST /api/v1/auth/sms/send
      // 暂用Mock，后端已实现Mock模式：验证码固定123456
      debugPrint('发送验证码到: $phone');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码已发送（Mock模式：123456）'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
      return false;
    }
  }

  /// 登录
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

      // TODO: 调用API POST /api/v1/auth/login
      // body: { "phone": phone, "smsCode": code }
      debugPrint('登录: phone=$phone, code=$code');

      // Mock登录成功，跳转到档案页
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/children');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败：$e')),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo区域
              _buildLogoSection(),

              const SizedBox(height: 48),

              // 表单区域
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    PhoneInputField(controller: _phoneController),
                    const SizedBox(height: AppSpacing.md),
                    SmsCodeField(
                      codeController: _codeController,
                      phoneController: _phoneController,
                      onSendCode: _onSendCode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text('登录 / 注册', style: AppTypography.button),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 用户协议
              _buildAgreementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo占位 - 后续替换为正式Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '字趣阅读',
          style: AppTypography.h1.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI识字阅读，让阅读像玩游戏一样有趣',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
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
          style: AppTypography.caption,
        ),
        GestureDetector(
          onTap: () {
            // TODO: 跳转用户协议页面
            debugPrint('打开用户协议');
          },
          child: Text(
            '《用户协议》',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          '和',
          style: AppTypography.caption,
        ),
        GestureDetector(
          onTap: () {
            // TODO: 跳转隐私政策页面
            debugPrint('打开隐私政策');
          },
          child: Text(
            '《隐私政策》',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
