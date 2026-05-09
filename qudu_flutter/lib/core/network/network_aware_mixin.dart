import 'dart:async';
import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import 'network_interceptor.dart';
import 'network_ui_helper.dart';

/// 网络状态感知 Mixin
/// 混入此 Mixin 的 State 类会自动监听网络状态，并提供离线 Banner 构建方法
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  bool _isOffline = false;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  /// 是否离线
  bool get isOffline => _isOffline;

  /// 初始化网络状态监听（在 initState() 中调用）
  void initNetworkAware() {
    _networkSubscription = ServiceLocator.instance.apiClient.networkStatus.listen((status) {
      if (mounted) {
        setState(() {
          _isOffline = status == NetworkStatus.offline;
        });
      }
    });
  }

  /// 取消网络状态订阅（在 dispose() 中调用）
  void disposeNetworkAware() {
    _networkSubscription?.cancel();
  }

  /// 构建离线 Banner（轻量版，适合放在 Column 或 Row 中）
  Widget buildOfflineBannerInline() => NetworkUIHelper.buildOfflineBanner();

  /// 构建离线 Banner（AppBar 扩展版，适合放在 Scaffold 的 AppBar 中）
  PreferredSizeWidget buildOfflineAppBar({required Widget child}) =>
      NetworkUIHelper.buildOfflineAppBar(child: child) as PreferredSizeWidget;

  /// 显示离线 SnackBar
  void showOfflineSnackBar(BuildContext context) {
    NetworkUIHelper.showOfflineSnackBar(context);
  }

  /// 显示在线恢复 SnackBar
  void showOnlineSnackBar(BuildContext context) {
    NetworkUIHelper.showOnlineSnackBar(context);
  }
}
