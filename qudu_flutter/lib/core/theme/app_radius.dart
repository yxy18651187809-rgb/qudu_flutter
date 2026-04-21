import 'package:flutter/material.dart';

/// 字趣阅读圆角规范
/// 来源：04-设计/UI规范速查表_v1.md
class AppRadius {
  static const double small = 8.0;    // 小元素（徽章/头像框）
  static const double medium = 12.0;  // 按钮/输入框
  static const double large = 16.0;   // 大卡片
  static const double bubble = 20.0;  // 新字气泡
  static const double full = 1000.0;  // 圆形（头像）

  static BorderRadius get smallBorder => BorderRadius.circular(small);
  static BorderRadius get mediumBorder => BorderRadius.circular(medium);
  static BorderRadius get largeBorder => BorderRadius.circular(large);
  static BorderRadius get bubbleBorder => BorderRadius.circular(bubble);
}
