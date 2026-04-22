import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// 验证码输入框 + 获取验证码按钮组合
/// 设计稿规范：输入框flex:1 + 按钮96dp宽 + 间距12dp
class SmsCodeField extends StatefulWidget {
  final TextEditingController codeController;
  final TextEditingController phoneController;
  final Future<bool> Function(String phone) onSendCode;
  final String? Function(String?)? validator;

  const SmsCodeField({
    super.key,
    required this.codeController,
    required this.phoneController,
    required this.onSendCode,
    this.validator,
  });

  @override
  State<SmsCodeField> createState() => _SmsCodeFieldState();
}

class _SmsCodeFieldState extends State<SmsCodeField> {
  int _countdown = 0;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = widget.phoneController.text.replaceAll(' ', '');
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await widget.onSendCode(phone);
      if (success && mounted) {
        setState(() => _countdown = 60);
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _countdown--;
            if (_countdown <= 0) {
              timer.cancel();
            }
          });
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 验证码输入框 flex:1
        Expanded(
          child: TextFormField(
            controller: widget.codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '请输入验证码',
              hintStyle: const TextStyle(
                fontSize: 16,
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            validator: widget.validator ??
                (value) {
                  if (value == null || value.isEmpty) return '验证码错误，请重新输入';
                  if (value.length != 6) return '验证码错误，请重新输入';
                  return null;
                },
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 12),
        // 获取验证码按钮 96dp宽
        SizedBox(
          width: 96,
          height: 48,
          child: _countdown > 0
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorder,
                    ),
                  ),
                  child: Text(
                    '$_countdown秒',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mediumBorder,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text(
                          '获取验证码',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
        ),
      ],
    );
  }
}
