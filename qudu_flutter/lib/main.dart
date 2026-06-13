import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/services/storage_service.dart';
import 'presentation/pages/privacy/privacy_consent_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查隐私政策同意状态
  final hasConsent = await StorageService.hasPrivacyConsent();

  if (!hasConsent) {
    // 首次启动：展示隐私同意页，不同意不初始化SDK
    runApp(_PrivacyGateApp());
    return;
  }

  // 已同意隐私政策，正常初始化
  _initApp();
}

/// 初始化应用（SDK初始化 + 运行主应用）
void _initApp() {
  // 初始化服务定位器（含API客户端等）
  ServiceLocator.instance.init();

  // TODO(P1): 微信SDK初始化待 wechat_auth_service.dart 修复后启用
  // await ServiceLocator.instance.wechatAuthService.init(
  //   appId: 'YOUR_WECHAT_APPID',  // 替换为真实的微信开放平台APPID
  //   doOnAndroid: true,
  //   doOnIOS: true,
  // );

  runApp(const ZiquApp());
}

/// 隐私政策门控应用
/// 用户同意前不初始化任何SDK，仅展示隐私同意页
class _PrivacyGateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '字趣阅读',
      debugShowCheckedModeBanner: false,
      home: PrivacyConsentPage(
        onResult: (agreed) {
          if (agreed) {
            // 用户同意后初始化SDK并启动主应用
            _initApp();
          } else {
            // 用户拒绝，退出APP
            SystemNavigator.pop();
          }
        },
      ),
    );
  }
}
