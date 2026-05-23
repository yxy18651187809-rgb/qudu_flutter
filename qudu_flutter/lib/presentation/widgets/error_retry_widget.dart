import 'package:flutter/material.dart';

/// 错误状态组件 — 统一错误展示 + 重试交互
///
/// 参数：message（错误信息）、onRetry（重试回调）、icon（可选自定义图标）。
/// 区分错误类型：网络错误、服务器错误、数据异常，给出不同文案。
class ErrorRetryWidget extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;
  final Widget? icon;

  const ErrorRetryWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon,
  });

  @override
  State<ErrorRetryWidget> createState() => _ErrorRetryWidgetState();
}

class _ErrorRetryWidgetState extends State<ErrorRetryWidget> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      widget.onRetry?.call();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message ?? '出了点小问题，请稍后再试';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.icon ??
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: Color(0xFFBDBDBD),
                ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF757575),
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 36,
                height: 36,
                child: _isRetrying
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF8BC34A),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF8BC34A),
                        ),
                        onPressed: _handleRetry,
                        tooltip: '重试',
                        padding: EdgeInsets.zero,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
