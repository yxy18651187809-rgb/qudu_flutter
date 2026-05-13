import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_client.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/data/models/login_response.dart';
import 'package:ziqu_reading/data/repositories/auth_repository.dart';

/// Mock ApiClient — 绕过真实HTTP，直接返回预设的 ApiResponse
class MockApiClient extends ApiClient {
  /// 预设的 GET 响应映射：path → ApiResponse
  final Map<String, ApiResponse<Map<String, dynamic>>> _getResponses = {};

  /// 预设的 POST 响应映射：path → ApiResponse
  final Map<String, ApiResponse<Map<String, dynamic>>> _postResponses = {};

  /// 预设的 PUT 响应映射：path → ApiResponse
  final Map<String, ApiResponse<Map<String, dynamic>>> _putResponses = {};

  /// 预设的 DELETE 响应映射：path → ApiResponse
  final Map<String, ApiResponse<Map<String, dynamic>>> _deleteResponses = {};

  /// 预设的异常：path → ApiException
  final Map<String, ApiException> _postErrors = {};

  MockApiClient()
      : super(
          baseUrl: 'http://mock-api.test',
          tokenStorage: _MockTokenStorage(),
        );

  /// 注册 GET mock 响应
  void whenGet(
    String path,
    ApiResponse<Map<String, dynamic>> response,
  ) {
    _getResponses[path] = response;
  }

  /// 注册 POST mock 响应
  void whenPost(
    String path,
    ApiResponse<Map<String, dynamic>> response,
  ) {
    _postResponses[path] = response;
  }

  /// 注册 POST mock 异常
  void whenPostError(String path, ApiException error) {
    _postErrors[path] = error;
  }

  /// 注册 PUT mock 响应
  void whenPut(
    String path,
    ApiResponse<Map<String, dynamic>> response,
  ) {
    _putResponses[path] = response;
  }

  /// 注册 DELETE mock 响应
  void whenDelete(
    String path,
    ApiResponse<Map<String, dynamic>> response,
  ) {
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
    if (response != null) {
      return response as ApiResponse<T>;
    }
    return ApiResponse<T>.empty();
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    if (_postErrors.containsKey(path)) {
      throw _postErrors[path]!;
    }
    final response = _postResponses[path];
    if (response != null) {
      return response as ApiResponse<T>;
    }
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
    if (response != null) {
      return response as ApiResponse<T>;
    }
    return ApiResponse<T>.empty();
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    final response = _deleteResponses[path];
    if (response != null) {
      return response as ApiResponse<T>;
    }
    return ApiResponse<T>.empty();
  }
}

class _MockTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

void main() {
  late MockApiClient mockApi;
  late AuthRepository authRepo;

  setUp(() {
    mockApi = MockApiClient();
    authRepo = AuthRepository(apiClient: mockApi);
  });

  group('AuthRepository', () {
    group('sendSmsCode', () {
      test('成功发送返回 expireIn', () async {
        mockApi.whenPost('/auth/sms/send', ApiResponse(
          code: 0,
          data: {'expireIn': 300},
          message: 'ok',
        ));

        final result = await authRepo.sendSmsCode('13800138000');
        expect(result, 300);
      });

      test('API返回非0 code时抛出 ApiException', () async {
        mockApi.whenPost('/auth/sms/send', ApiResponse(
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
        mockApi.whenPost('/auth/sms/send', ApiResponse(
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
        mockApi.whenPost('/auth/sms/send', ApiResponse(
          code: 0,
          data: <String, dynamic>{},
          message: 'ok',
        ));

        // data 非null，但缺少 expireIn 字段
        // 因为 isSuccess=true 但 data 不含 expireIn，应返回默认 300
        // 但 AuthRepository 检查的是 data == null，这里 data 非 null
        // 所以会走到 `response.data!['expireIn'] as int? ?? 300`
        final result = await authRepo.sendSmsCode('13800138000');
        expect(result, 300);
      });
    });

    group('login', () {
      test('成功登录返回 LoginResponse', () async {
        mockApi.whenPost('/auth/login', ApiResponse(
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
        expect(result.expiresIn, 7200);
        expect(result.user.id, 'user001');
        expect(result.user.phone, '13800138000');
      });

      test('验证码错误时抛出 ApiException', () async {
        mockApi.whenPost('/auth/login', ApiResponse(
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
        mockApi.whenPostError('/auth/login', ApiException(
          code: -2,
          message: '网络连接失败',
        ));

        expect(
          () => authRepo.login(phone: '13800138000', code: '123456'),
          throwsA(isA<ApiException>().having(
            (e) => e.code, 'code', -2,
          )),
        );
      });
    });

    group('wechatLogin', () {
      test('微信登录成功返回 LoginResponse', () async {
        mockApi.whenPost('/auth/wechat/login', ApiResponse(
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
        mockApi.whenPost('/auth/wechat/login', ApiResponse(
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
        mockApi.whenGet('/user/profile', ApiResponse(
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
        expect(result.nickname, '测试用户');
        expect(result.hasChildren, true);
        expect(result.childrenCount, 2);
      });

      test('Token过期时抛出 ApiException', () async {
        mockApi.whenGet('/user/profile', ApiResponse(
          code: 401,
          data: null,
          message: 'Token已过期',
        ));

        expect(
          () => authRepo.getUserProfile(),
          throwsA(isA<ApiException>().having(
            (e) => e.code, 'code', 401,
          )),
        );
      });
    });
  });
}
