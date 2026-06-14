import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/data/models/login_response.dart';
import 'package:ziqu_reading/data/models/wechat_login_result.dart';
import 'package:ziqu_reading/data/repositories/auth_repository.dart';

import '../repositories/auth_repository_test.dart';

void main() {
  // =========================================================================
  // WechatLoginResult 模型测试
  // =========================================================================
  group('WechatLoginResult', () {
    test('success 工厂创建成功结果', () {
      final result = WechatLoginResult.success('test_code_123');
      expect(result.success, true);
      expect(result.code, 'test_code_123');
      expect(result.error, isNull);
      expect(result.isCancelled, false);
    });

    test('error 工厂创建错误结果', () {
      final result = WechatLoginResult.error('微信未安装');
      expect(result.success, false);
      expect(result.code, isNull);
      expect(result.error, '微信未安装');
      expect(result.isCancelled, false);
    });

    test('cancelled 工厂创建取消结果', () {
      final result = WechatLoginResult.cancelled();
      expect(result.success, false);
      expect(result.isCancelled, true);
      expect(result.code, isNull);
      expect(result.error, '用户取消授权');
    });

    test('success/cancelled/error 互斥', () {
      final succ = WechatLoginResult.success('code1');
      final canc = WechatLoginResult.cancelled();
      final err = WechatLoginResult.error('fail');
      expect(succ.success, true);
      expect(canc.isCancelled, true);
      expect(err.error, 'fail');
      expect(succ, isNot(equals(canc)));
    });
  });

  // =========================================================================
  // LoginResponse 模型测试
  // =========================================================================
  group('LoginResponse', () {
    test('fromJson 解析完整 token 响应', () {
      final json = {
        'accessToken': 'eyJhbGciOi...',
        'refreshToken': 'eyJhbGciOi...x',
        'isNewUser': false,
        'expiresIn': 7200,
        'user': {
          'id': 'user123',
          'phone': '138****8000',
          'nickname': '测试用户',
          'avatar': '',
          'hasChildren': true,
          'childrenCount': 2,
        },
      };
      final response = LoginResponse.fromJson(json);
      expect(response.accessToken, 'eyJhbGciOi...');
      expect(response.refreshToken, 'eyJhbGciOi...x');
      expect(response.expiresIn, 7200);
      expect(response.isNewUser, false);
      expect(response.user.id, 'user123');
      expect(response.user.phone, '138****8000');
      expect(response.user.nickname, '测试用户');
    });

    test('fromJson 处理缺失字段', () {
      final response = LoginResponse.fromJson({});
      expect(response.accessToken, '');
      expect(response.refreshToken, '');
      expect(response.isNewUser, false);
      expect(response.expiresIn, 7200);
      expect(response.user.id, '');
    });
  });

  // =========================================================================
  // UserModel 测试
  // =========================================================================
  group('UserModel', () {
    test('fromJson 解析用户数据', () {
      final json = {
        'id': 'user001',
        'phone': '13800138000',
        'nickname': '家长A',
        'avatar': '/avatars/a.png',
        'hasChildren': true,
        'childrenCount': 1,
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'user001');
      expect(user.phone, '13800138000');
      expect(user.nickname, '家长A');
      expect(user.childrenCount, 1);
      expect(user.hasChildren, true);
    });
  });

  // =========================================================================
  // AuthRepository.wechatLogin 测试
  // =========================================================================
  group('AuthRepository.wechatLogin', () {
    late TestableApiClient mockApi;
    late AuthRepository authRepo;

    setUp(() {
      mockApi = TestableApiClient();
      authRepo = AuthRepository(apiClient: mockApi);
    });

    test('微信 code 登录成功返回 LoginResponse', () async {
      mockApi.mockPost('/auth/wechat/login', ApiResponse(
        code: 0,
        data: {
          'accessToken': 'wx_token_abc',
          'refreshToken': 'wx_refresh_abc',
          'isNewUser': true,
          'expiresIn': 7200,
          'user': {
            'id': 'wx_user_1',
            'phone': '',
            'nickname': '微信用户',
            'avatar': 'https://wx.avatar/1.jpg',
            'hasChildren': false,
            'childrenCount': 0,
          },
        },
        message: '登录成功',
      ));

      final result = await authRepo.wechatLogin(code: 'wx_code_123');
      expect(result.accessToken, 'wx_token_abc');
      expect(result.user.id, 'wx_user_1');
      expect(result.user.nickname, '微信用户');
      expect(result.isNewUser, true);
    });

    test('微信 code 无效返回错误', () async {
      mockApi.mockPost('/auth/wechat/login', ApiResponse(
        code: 4001,
        data: null,
        message: '微信code无效或已过期',
      ));

      expect(
        () => authRepo.wechatLogin(code: 'invalid_code'),
        throwsA(isA<ApiException>().having(
          (e) => e.code, 'code', 4001,
        )),
      );
    });

    test('微信登录网络异常传播', () async {
      mockApi.mockPostError(
        '/auth/wechat/login',
        ApiException(code: -1, message: '网络连接失败'),
      );

      expect(
        () => authRepo.wechatLogin(code: 'test_code'),
        throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', '网络连接失败',
        )),
      );
    });
  });

  // =========================================================================
  // Login 完整流程测试（手机号 + 验证码）
  // =========================================================================
  group('Auth — 完整登录流程', () {
    late TestableApiClient mockApi;
    late AuthRepository authRepo;

    setUp(() {
      mockApi = TestableApiClient();
      authRepo = AuthRepository(apiClient: mockApi);
    });

    test('发送短信验证码成功', () async {
      mockApi.mockPost('/auth/sms/send', ApiResponse(
        code: 0,
        data: {'expireIn': 300},
        message: '验证码已发送',
      ));

      final expireIn = await authRepo.sendSmsCode('13800138000');
      expect(expireIn, 300);
    });

    test('SMS → Login 完整流程', () async {
      // Step 1: 发送验证码
      mockApi.mockPost('/auth/sms/send', ApiResponse(
        code: 0,
        data: {'expireIn': 300},
        message: '验证码已发送',
      ));
      final expireIn = await authRepo.sendSmsCode('13800138000');
      expect(expireIn, 300);

      // Step 2: 用验证码登录
      mockApi.mockPost('/auth/login', ApiResponse(
        code: 0,
        data: {
          'accessToken': 'token_full_flow',
          'refreshToken': 'refresh_full_flow',
          'isNewUser': false,
          'expiresIn': 7200,
          'user': {
            'id': 'parent_001',
            'phone': '13800138000',
            'nickname': '家长',
            'avatar': '',
            'hasChildren': true,
            'childrenCount': 2,
          },
        },
        message: '登录成功',
      ));

      final loginResult = await authRepo.login(
        phone: '13800138000',
        code: '123456',
      );
      expect(loginResult.accessToken, 'token_full_flow');
      expect(loginResult.refreshToken, 'refresh_full_flow');
      expect(loginResult.user.id, 'parent_001');
      expect(loginResult.user.childrenCount, 2);
      expect(loginResult.isNewUser, false);
    });
  });
}
