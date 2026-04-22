import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_response.dart';

/// Token管理接口
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> clearTokens();
}

/// HTTP客户端封装
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  // Token刷新回调
  Future<bool> Function(String refreshToken)? onTokenExpired;

  // 是否正在刷新Token
  bool _isRefreshing = false;

  // 等待Token刷新的请求队列
  final List<Future<void> Function()> _pendingRequests = [];

  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
  })  : _baseUrl = baseUrl,
        _tokenStorage = tokenStorage {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 请求拦截器：自动添加Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401处理：自动刷新Token
        if (error.response?.statusCode == 401) {
          final success = await _refreshToken();
          if (success) {
            // 重试原请求
            final token = await _tokenStorage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          } else {
            // refreshToken也过期，需要重新登录
            await _tokenStorage.clearTokens();
            handler.next(error);
            return;
          }
        }
        handler.next(error);
      },
    ));

    // 日志拦截器（仅debug模式）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// 刷新Token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // 已经在刷新中，排队等待
      final completer = Completer<bool>();
      _pendingRequests.add(() async {
        completer.complete(true);
      });
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await Dio().post(
        '$_baseUrl/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        await _tokenStorage.saveTokens(
          accessToken: apiResponse.data!['accessToken'] as String,
          refreshToken: apiResponse.data!['refreshToken'] as String,
        );

        // 处理排队的请求
        for (final callback in _pendingRequests) {
          await callback();
        }
        _pendingRequests.clear();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        cancelToken: cancelToken,
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        cancelToken: cancelToken,
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        cancelToken: cancelToken,
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  ApiException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(code: -1, message: '网络连接超时，请检查网络');
      case DioExceptionType.connectionError:
        return ApiException(code: -2, message: '网络连接失败');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return ApiException(
            code: data['code'] as int? ?? e.response?.statusCode ?? -1,
            message: data['message'] as String? ?? '请求失败',
          );
        }
        return ApiException(
          code: e.response?.statusCode ?? -1,
          message: '服务器错误(${e.response?.statusCode})',
        );
      default:
        return ApiException(code: -1, message: '请求失败，请重试');
    }
  }
}

/// 简单的Completer占位（Dart内置）
class Completer<T> {
  final _completer = <void Function(T)>[];
  bool _isCompleted = false;
  T? _result;

  bool get isCompleted => _isCompleted;
  T get result => _result as T;

  void complete(T value) {
    if (_isCompleted) return;
    _isCompleted = true;
    _result = value;
    for (final callback in _completer) {
      callback(value);
    }
  }

  Future<T> get future {
    if (_isCompleted) return Future.value(_result);
    return Future.value(_result);
  }
}
