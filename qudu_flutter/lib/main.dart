import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务定位器
  ServiceLocator.instance.init();

  // TODO(P1): 微信SDK初始化待 wechat_auth_service.dart 修复后启用
  // await ServiceLocator.instance.wechatAuthService.init(
  //   appId: 'YOUR_WECHAT_APPID',  // 替换为真实的微信开放平台APPID
  //   doOnAndroid: true,
  //   doOnIOS: true,
  // );

  runApp(const ZiquApp());
}
