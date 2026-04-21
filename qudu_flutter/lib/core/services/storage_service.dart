import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全本地存储服务
/// 用于存储Token等敏感数据
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ==================== Token ====================

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresIn = 'expires_in';
  static const _keyExpiresAt = 'expires_at';

  /// 保存Token信息
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyExpiresIn, value: expiresIn.toString());
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toString());
  }

  /// 获取AccessToken
  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  /// 获取RefreshToken
  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  /// 检查AccessToken是否过期
  static Future<bool> isAccessTokenExpired() async {
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    if (expiresAtStr == null) return true;
    final expiresAt = int.tryParse(expiresAtStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // 提前5分钟判定为过期，避免边界问题
    return now >= expiresAt - 300;
  }

  /// 检查是否有已登录的Token
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !(await isAccessTokenExpired());
  }

  /// 清除所有Token
  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresIn);
    await _storage.delete(key: _keyExpiresAt);
  }

  // ==================== 用户信息 ====================

  static const _keyUserId = 'user_id';
  static const _keyCurrentChildId = 'current_child_id';

  /// 保存当前登录用户ID
  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  /// 获取当前登录用户ID
  static Future<String?> getUserId() =>
      _storage.read(key: _keyUserId);

  /// 保存当前选中的儿童ID
  static Future<void> saveCurrentChildId(String childId) =>
      _storage.write(key: _keyCurrentChildId, value: childId);

  /// 获取当前选中的儿童ID
  static Future<String?> getCurrentChildId() =>
      _storage.read(key: _keyCurrentChildId);

  /// 清除所有数据（退出登录时调用）
  static Future<void> clearAll() async {
    await clearTokens();
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyCurrentChildId);
  }
}
