import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

/// 字趣阅读 App Logo 组件
///
/// 用于启动页、登录页、About 页面等品牌展示场景。
/// 包含趣趣 IP 形象 + 品牌名文字。
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? backgroundColor;
  final double elevation;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.backgroundColor,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo 图标（渐变背景 + 趣趣 SVG）
        Container(
          width: size,
          height: size * 0.9,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.gradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: elevation > 0
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.1),
            child: SvgPicture.asset(
              'assets/images/ququ/ququ_logo.svg',
              width: size * 0.8,
              height: size * 0.8,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.1),
          // 品牌名：字趣阅读
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '字',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '趣',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '阅',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '读',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
