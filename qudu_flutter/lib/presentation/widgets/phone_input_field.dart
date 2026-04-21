import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      decoration: const InputDecoration(
        hintText: '请输入手机号',
        prefixIcon: Icon(Icons.phone_android_outlined),
        prefixText: '+86  ',
        prefixStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        counterText: '',
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) return '请输入手机号';
            if (value.length != 11) return '请输入11位手机号';
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
