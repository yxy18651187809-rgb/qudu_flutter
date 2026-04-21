import 'package:flutter/material.dart';

/// 字趣阅读色彩系统
/// 来源：04-设计/UI规范速查表_v1.md
class AppColors {
  // 品牌主色板
  static const Color primary = Color(0xFF8BC34A);       // 春绿 - 主按钮、导航高亮、进度条
  static const Color primaryLight = Color(0xFFC5E8A8);  // 浅色背景、hover态
  static const Color primaryDark = Color(0xFF689F38);    // 深色强调、按下态
  static const Color secondary = Color(0xFFFFAB91);      // 暖粉 - 辅色卡片、趣趣腮红
  static const Color accent = Color(0xFFFFD54F);         // 阳光黄 - 新字高亮背景、徽章
  static const Color warning = Color(0xFFFF7043);        // 橙红 - 警示、新字文字色

  // 背景色
  static const Color background = Color(0xFFF5F5DC);     // 温暖米白 - 全局背景（护眼）
  static const Color bg = background;                     // 别名
  static const Color surface = Color(0xFFFFFFFF);         // 纯白 - 卡片/页面白底

  // 文字色
  static const Color textPrimary = Color(0xFF424242);     // 深灰 - 正文文字
  static const Color textSecondary = Color(0xFF757575);   // 次要文字
  static const Color textHint = Color(0xFFBDBDBD);        // 占位符、hint文字

  // 状态色
  static const Color success = Color(0xFF81C784);
  static const Color error = Color(0xFFE57373);
  static const Color disabled = Color(0xFFE0E0E0);
  static const Color disabledText = Color(0xFF9E9E9E);

  // 功能色
  static const Color border = Color(0xFFE0E0E0);         // 输入框边框（未聚焦）
  static const Color shadow = Color.fromRGBO(0, 0, 0, 0.08); // 卡片阴影

  // 新字气泡
  static const Color newWordBubble = Color.fromRGBO(255, 213, 79, 0.85); // 暖黄85%透明
  static const Color newWordText = Color(0xFFFF7043);     // 橙红

  // 趣趣IP配色
  static const Color ipBody = Color(0xFFC5E1A5);         // 淡黄绿
  static const Color ipBelly = Color(0xFFFFF8E1);        // 乳白
  static const Color ipBlush = Color(0xFFFFAB91);        // 粉红腮红
  static const Color ipLeaf = Color(0xFF8BC34A);         // 春绿叶子
}
