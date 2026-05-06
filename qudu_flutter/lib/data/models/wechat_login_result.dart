/// 微信登录结果模型
class WechatLoginResult {
  final bool success;
  final String? code;
  final String? error;
  final bool isCancelled;

  WechatLoginResult._({
    required this.success,
    this.code,
    this.error,
    this.isCancelled = false,
  });

  /// 成功
  factory WechatLoginResult.success(String code) {
    return WechatLoginResult._(success: true, code: code);
  }

  /// 失败
  factory WechatLoginResult.error(String error) {
    return WechatLoginResult._(success: false, error: error);
  }

  /// 用户取消
  factory WechatLoginResult.cancelled() {
    return WechatLoginResult._(success: false, isCancelled: true, error: '用户取消授权');
  }
}
