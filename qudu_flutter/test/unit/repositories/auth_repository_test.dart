import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_client.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/data/repositories/auth_repository.dart';

/// 可测试的 ApiClient — skipInterceptors=true 避免触发平台通道
class TestableApiClient extends ApiClient {
  final Map<String, ApiResponse<Map<String, dynamic>>> _getResponses = {};
  final Map<String, ApiResponse<Map<String, dynamic>>> _postResponses = {};
  final Map<String, ApiResponse<Map<String, dynamic>>> _putResponses = {};
  final Map<String, ApiResponse<Map<String, dynamic>>> _deleteResponses = {};
  final Map<String, ApiException> _postErrors = {};

  TestableApiClient() : super(
    baseUrl: 'http://test.local',
    tokenStorage: _DummyTokenStorage(),
    skipInterceptors: true,
  );

  void mockGet(String path, ApiResponse<Map<String, dynamic>> response) {
    _getResponses[path] = response;
  }

  void mockPost(String path, ApiResponse<Map<String, dynamic>> response) {
    _postResponses[path] = response;
  }

  void mockPostError(String path, ApiException error) {
    _postErrors[path] = error;
  }

  void mockPut(String path, ApiResponse<Map<String, dynamic>> response) {
    _putResponses[path] = response;
  }

  void mockDelete(String path, ApiResponse<Map<String, dynamic>> response) {
    _deleteResponses[path] = response;
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    final response = _getResponses[path];
    if (response != null) return response as ApiResponse<T>;
    return ApiResponse<T>.empty();
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    if (_postErrors.containsKey(path)) throw _postErrors[path]!;
    final response = _postResponses[path];
    if (response != null) return response as ApiResponse<T>;
    return ApiResponse<T>.empty();
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    final response = _putResponses[path];
    if (response != null) return response as ApiResponse<T>;
    return ApiResponse<T>.empty();
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    final response = _deleteResponses[path];
    if (response != null) return response as ApiResponse<T>;
    return ApiResponse<T>.empty();
  }
}

class _DummyTokenStorage implements TokenStorage {
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
}

void main() {
  late TestableApiClient mockApi;
  late AuthRepository authRepo;

  setUp(() {
    mockApi = TestableApiClient();
    authRepo = AuthRepository(apiClient: mockApi);
  });

  group('AuthRepository', () {
    group('sendSmsCode', () {
      test('成功发送返回 expireIn', () async {
        mockApi.mockPost('/auth/sms/send', ApiResponse(
          code: 0,
          data: {'expireIn': 300},
          message: 'ok',
        ));

        final result = await authRepo.sendSmsCode('13800138000');
        expect(result, 300);
      });

      test('API返回非0 code时抛出 ApiException', () async {
        mockApi.mockPost('/auth/sms/send', ApiResponse(
          code: 1001,
          data: null,
          message: '手机号格式不正确',
        ));

        expect(
          () => authRepo.sendSmsCode('invalid'),
          throwsA(isA<ApiException>()),
        );
      });

      test('API返回null data时抛出 ApiException', () async {
        mockApi.mockPost('/auth/sms/send', ApiResponse(
          code: 0,
          data: null,
          message: 'ok',
        ));

        expect(
          () => authRepo.sendSmsCode('13800138000'),
          throwsA(isA<ApiException>()),
        );
      });

      test('expireIn 缺失时默认300', () async {
        mockApi.mockPost('/auth/sms/send', ApiResponse(
          code: 0,
          data: <String, dynamic>{},
          message: 'ok',
        ));

        final result = await authRepo.sendSmsCode('13800138000');
        expect(result, 300);
      });
    });

    group('login', () {
      test('成功登录返回 LoginResponse', () async {
        mockApi.mockPost('/auth/login', ApiResponse(
          code: 0,
          data: {
            'isNewUser': true,
            'accessToken': 'access_token_123',
            'refreshToken': 'refresh_token_456',
            'expiresIn': 7200,
            'user': {
              'id': 'user001',
              'phone': '13800138000',
              'nickname': '测试用户',
              'avatar': '',
              'hasChildren': false,
              'childrenCount': 0,
            },
          },
          message: 'ok',
        ));

        final result = await authRepo.login(
          phone: '13800138000',
          code: '123456',
        );
        expect(result.isNewUser, true);
        expect(result.accessToken, 'access_token_123');
        expect(result.refreshToken, 'refresh_token_456');
        expect(result.user.id, 'user001');
      });

      test('验证码错误时抛出 ApiException', () async {
        mockApi.mockPost('/auth/login', ApiResponse(
          code: 1002,
          data: null,
          message: '验证码错误或已过期',
        ));

        expect(
          () => authRepo.login(phone: '13800138000', code: 'wrong'),
          throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', '验证码错误或已过期',
          )),
        );
      });

      test('网络异常时抛出 ApiException', () async {
        mockApi.mockPostError('/auth/login', ApiException(
          code: -2,
          message: '网络连接失败',
        ));

        expect(
          () => authRepo.login(phone: '13800138000', code: '123456'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', -2)),
        );
      });
    });

    group('wechatLogin', () {
      test('微信登录成功返回 LoginResponse', () async {
        mockApi.mockPost('/auth/wechat/login', ApiResponse(
          code: 0,
          data: {
            'isNewUser': false,
            'accessToken': 'wx_access_token',
            'refreshToken': 'wx_refresh_token',
            'expiresIn': 7200,
            'user': {
              'id': 'user_wx_001',
              'phone': '',
              'nickname': '微信用户',
              'avatar': 'https://wx.avatar/1.png',
              'hasChildren': false,
              'childrenCount': 0,
            },
          },
          message: 'ok',
        ));

        final result = await authRepo.wechatLogin(code: 'wx_code_abc');
        expect(result.isNewUser, false);
        expect(result.accessToken, 'wx_access_token');
        expect(result.user.nickname, '微信用户');
      });

      test('微信授权码无效时抛出 ApiException', () async {
        mockApi.mockPost('/auth/wechat/login', ApiResponse(
          code: 1003,
          data: null,
          message: '微信授权码无效',
        ));

        expect(
          () => authRepo.wechatLogin(code: 'invalid_code'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getUserProfile', () {
      test('成功获取用户信息', () async {
        mockApi.mockGet('/user/profile', ApiResponse(
          code: 0,
          data: {
            'id': 'user001',
            'phone': '13800138000',
            'nickname': '测试用户',
            'avatar': 'https://avatar.example.com/1.png',
            'hasChildren': true,
            'childrenCount': 2,
          },
          message: 'ok',
        ));

        final result = await authRepo.getUserProfile();
        expect(result.id, 'user001');
        expect(result.hasChildren, true);
        expect(result.childrenCount, 2);
      });

      test('Token过期时抛出 ApiException', () async {
        mockApi.mockGet('/user/profile', ApiResponse(
          code: 401,
          data: null,
          message: 'Token已过期',
        ));

        expect(
          () => authRepo.getUserProfile(),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
        );
      });
    });
  });
}
