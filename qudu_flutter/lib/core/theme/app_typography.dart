import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 字趣阅读字体规范
/// 来源：04-设计/UI规范速查表_v1.md
class AppTypography {
  // 标题层级
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // 正文层级
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.6,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // 新字展示（加粗+底色）
  static const TextStyle newWord = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.newWordText,
  );

  // 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  // 儿童阅读专用 - 大字号
  static const TextStyle readingText = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.8,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  // 测评页大字
  static const TextStyle assessChar = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
}
