import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// 验证码输入框 + 获取验证码按钮组合
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
        Expanded(
          child: TextFormField(
            controller: widget.codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              hintText: '验证码',
              prefixIcon: Icon(Icons.lock_outline),
              counterText: '',
            ),
            validator: widget.validator ??
                (value) {
                  if (value == null || value.isEmpty) return '请输入验证码';
                  if (value.length != 6) return '请输入6位验证码';
                  return null;
                },
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: _countdown > 0
              ? OutlinedButton(
                  onPressed: null,
                  child: Text(
                    '${_countdown}s',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(110, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '获取验证码',
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
        ),
      ],
    );
  }
}
