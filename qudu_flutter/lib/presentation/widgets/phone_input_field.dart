import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// 手机号输入框
/// 限制11位数字，自动格式化 xxx xxxx xxxx
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onFieldSubmitted;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PhoneFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '请输入手机号',
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.textHint,
        ),
        prefixIcon: const Icon(Icons.phone_android_outlined, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        prefixText: '+86  ',
        prefixStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        // 设计稿规范：1.5dp边框、12dp圆角、16dp内边距
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
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) return '请输入正确的手机号';
            if (value.length != 11) return '请输入正确的手机号';
            if (!value.startsWith('1')) return '请输入正确的手机号';
            return null;
          },
      onFieldSubmitted: (_) => onFieldSubmitted?.call(),
      textInputAction: TextInputAction.next,
    );
  }
}

/// 手机号格式化器：138 0013 8000
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 7) buffer.write(' ');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(
        offset: buffer.length,
      ),
    );
  }
}
