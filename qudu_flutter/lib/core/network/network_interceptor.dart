import 'dart:async';

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络状态拦截器（纯Dart，无Flutter依赖）
class NetworkInterceptor extends Interceptor {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// 当前网络状态
  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;

  NetworkInterceptor() {
    // 监听网络状态变化
    _connectivity.onConnectivityChanged.listen((result) {
      final status = _mapResultToStatus(result);
      if (_currentStatus != status) {
        _currentStatus = status;
        _statusController.add(status);
      }
    });

    // 初始检测
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _currentStatus = _mapResultToStatus(result);
    _statusController.add(_currentStatus);
  }

  NetworkStatus _mapResultToStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // 离线状态下，在请求中标记网络状态
    options.extra['isOffline'] = _currentStatus == NetworkStatus.offline;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 处理网络异常，更新状态
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      _currentStatus = NetworkStatus.offline;
      _statusController.add(NetworkStatus.offline);
    }
    handler.next(err);
  }

  void dispose() {
    _statusController.close();
  }
}

/// 网络状态枚举
enum NetworkStatus {
  online,
  offline,
}
