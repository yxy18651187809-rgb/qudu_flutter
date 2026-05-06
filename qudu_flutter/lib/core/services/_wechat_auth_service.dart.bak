import 'package:fluwx/fluwx.dart';
import '../models/wechat_login_result.dart';

/// 微信登录服务
/// 封装fluwx SDK调用
/// 需要在原生平台配置微信SDK（iOS/Android）
class WechatAuthService {
  static final WechatAuthService _instance = WechatAuthService._internal();
  factory WechatAuthService() => _instance;
  WechatAuthService._internal();

  bool _isInitialized = false;

  /// 初始化微信SDK
  /// 需要在app启动时调用
  /// [appId] 微信开放平台应用APPID
  Future<bool> init({required String appId, required bool doOnAndroid: true, required bool doOnIOS: true}) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await registerWxApi(
        appId: appId,
        doOnAndroid: doOnAndroid,
        doOnIOS: doOnIOS,
      );
      
      if (_isInitialized) {
        debugPrint('[WechatAuthService] 微信SDK初始化成功');
      } else {
        debugPrint('[WechatAuthService] 微信SDK初始化失败');
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('[WechatAuthService] 微信SDK初始化异常: $e');
      return false;
    }
  }

  /// 检查微信是否安装
  Future<bool> isWechatInstalled() async {
    try {
      return await isWeChatInstalled;
    } catch (e) {
      debugPrint('[WechatAuthService] 检查微信安装状态失败: $e');
      return false;
    }
  }

  /// 发起微信登录授权
  /// 返回微信授权code（用于交换access_token）
  /// 需要在前端页面调用后端接口：POST /api/v1/auth/wechat/login
  Future<WechatLoginResult> login() async {
    if (!_isInitialized) {
      return WechatLoginResult.error('微信SDK未初始化');
    }

    try {
      // 发起微信授权（获取code）
      final sendResult = await sendWeChatAuth(
        scope: "snsapi_userinfo",
        state: "wechat_login",
      );

      if (!sendResult) {
        return WechatLoginResult.error('发起微信授权失败');
      }

      // 监听微信授权响应
      final response = await weChatResponseSubscriber
          .stream
          .where((event) => event is WeChatAuthResponse)
          .first;

      if (response is WeChatAuthResponse) {
        if (response.isSuccessful) {
          final code = response.code;
          if (code != null && code.isNotEmpty) {
            debugPrint('[WechatAuthService] 微信授权成功，code: $code');
            return WechatLoginResult.success(code);
          } else {
            return WechatLoginResult.error('微信授权返回code为空');
          }
        } else {
          final errorCode = response.errorCode;
          final errorMsg = response.errorMsg ?? '未知错误';
          debugPrint('[WechatAuthService] 微信授权失败: $errorCode - $errorMsg');
          
          if (errorCode == -2) {
            return WechatLoginResult.cancelled();
          } else {
            return WechatLoginResult.error('微信授权失败: $errorMsg');
          }
        }
      }

      return WechatLoginResult.error('微信授权响应异常');
    } catch (e) {
      debugPrint('[WechatAuthService] 微信登录异常: $e');
      return WechatLoginResult.error('微信登录异常: $e');
    }
  }

  /// 处理微信回调（供微信开放平台回调使用）
  void handleWechatResponse(WeChatResponse response) {
    debugPrint('[WechatAuthService] 收到微信响应: $response');
  }
}
