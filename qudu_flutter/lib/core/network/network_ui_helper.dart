import 'package:flutter/material.dart';

/// 离线状态UI辅助工具
class NetworkUIHelper {
  /// 显示离线SnackBar
  static void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 8),
            Text('当前处于离线状态，部分功能可能不可用'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示在线恢复SnackBar
  static void showOnlineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.cloud_done, color: Colors.white),
            SizedBox(width: 8),
            Text('网络已恢复'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 构建带离线Banner的AppBar
  static PreferredSizeWidget buildOfflineAppBar({required Widget child}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56 + 24),
      child: Column(
        children: [
          child,
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '离线模式 - 仅显示已缓存内容',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建离线状态内联提示
  static Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, size: 14, color: Colors.orange),
          SizedBox(width: 6),
          Text(
            '离线模式',
            style: TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
