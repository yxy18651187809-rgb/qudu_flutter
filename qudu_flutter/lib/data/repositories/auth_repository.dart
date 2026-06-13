import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/login_response.dart';

/// 认证模块 Repository
/// 对接API契约第二章：发送验证码、登录、刷新Token、用户信息
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 发送验证码
  /// POST /api/v1/auth/sms/send
  Future<int> sendSmsCode(String phone) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/sms/send',
      data: {'phone': phone},
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return response.data!['expireIn'] as int? ?? 300;
  }

  /// 登录（手机号+验证码，新用户自动注册）
  /// POST /api/v1/auth/login
  Future<LoginResponse> login({
    required String phone,
    required String code,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'code': code},
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return LoginResponse.fromJson(response.data!);
  }

  /// 微信登录
  /// POST /api/v1/auth/wechat/login
  /// [code] 微信授权返回的code
  Future<LoginResponse> wechatLogin({
    required String code,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/wechat/login',
      data: {'code': code},
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return LoginResponse.fromJson(response.data!);
  }

  /// 获取用户信息
  /// GET /api/v1/user/profile
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/user/profile',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return UserModel.fromJson(response.data!);
  }

  /// 注销账号
  /// DELETE /api/v1/auth/account
  /// 注意：后端需实现此接口，前端按此规格对接
  Future<void> deleteAccount() async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/auth/account',
    );
    if (!response.isSuccess) {
      throw ApiException(code: response.code, message: response.message);
    }
  }
}
