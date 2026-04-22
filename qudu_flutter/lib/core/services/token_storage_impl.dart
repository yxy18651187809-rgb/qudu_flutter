import '../network/api_client.dart';
import 'storage_service.dart';

/// TokenStorage接口的StorageService实现
/// 让ApiClient通过StorageService管理Token
class SecureTokenStorage implements TokenStorage {
  @override
  Future<String?> getAccessToken() => StorageService.getAccessToken();

  @override
  Future<String?> getRefreshToken() => StorageService.getRefreshToken();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // 刷新Token时API也返回expiresIn，默认7200（2小时）
    await StorageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: 7200,
    );
  }

  @override
  Future<void> clearTokens() => StorageService.clearTokens();
}
