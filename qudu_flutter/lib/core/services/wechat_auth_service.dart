import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fluwx/fluwx.dart';
import '../../data/models/wechat_login_result.dart';

/// 微信登录服务
/// 封装 fluwx v4.x SDK 调用
/// 需要在原生平台配置微信SDK（iOS/Android）
class WechatAuthService {
  static final WechatAuthService _instance = WechatAuthService._internal();
  factory WechatAuthService() => _instance;
  WechatAuthService._internal();

  final Fluwx _fluwx = Fluwx();
  bool _isInitialized = false;

  /// 初始化微信SDK
  /// 需要在app启动时调用
  /// [appId] 微信开放平台应用APPID
  /// [universalLink] iOS Universal Link（仅iOS需要）
  Future<bool> init({
    required String appId,
    bool doOnAndroid = true,
    bool doOnIOS = true,
    String? universalLink,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _fluwx.registerApi(
        appId: appId,
        doOnAndroid: doOnAndroid,
        doOnIOS: doOnIOS,
        universalLink: universalLink,
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
      return await _fluwx.isWeChatInstalled;
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
      // 使用 Completer 桥接 fluwx v4.x 回调模式到 Future
      final completer = Completer<WechatLoginResult>();

      // 先注册订阅者，再发起授权
      final cancelable = _fluwx.addSubscriber((response) {
        if (response is WeChatAuthResponse && !completer.isCompleted) {
          if (response.isSuccessful) {
            final code = response.code;
            if (code != null && code.isNotEmpty) {
              debugPrint('[WechatAuthService] 微信授权成功，code: $code');
              completer.complete(WechatLoginResult.success(code));
            } else {
              completer.complete(WechatLoginResult.error('微信授权返回code为空'));
            }
          } else {
            final errCode = response.errCode;
            final errStr = response.errStr ?? '未知错误';
            debugPrint('[WechatAuthService] 微信授权失败: $errCode - $errStr');

            if (errCode == -2) {
              completer.complete(WechatLoginResult.cancelled());
            } else {
              completer.complete(WechatLoginResult.error('微信授权失败: $errStr'));
            }
          }
        }
      });

      // 发起微信授权（获取code）
      // fluwx v4.x 使用 authBy + NormalAuth
      final sendResult = await _fluwx.authBy(
        which: NormalAuth(scope: 'snsapi_userinfo', state: 'wechat_login'),
      );

      if (!sendResult) {
        cancelable.cancel();
        return WechatLoginResult.error('发起微信授权失败');
      }

      // 等待授权结果（120秒超时）
      final result = await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () => WechatLoginResult.error('微信授权超时'),
      );

      cancelable.cancel();
      return result;
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
