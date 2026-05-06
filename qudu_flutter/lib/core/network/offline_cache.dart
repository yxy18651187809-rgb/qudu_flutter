import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 离线缓存管理器
class OfflineCache {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  static final OfflineCache _instance = OfflineCache._internal();
  factory OfflineCache() => _instance;
  OfflineCache._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 缓存API响应
  Future<void> cacheResponse({
    required String key,
    required Map<String, dynamic> data,
    Duration? duration,
  }) async {
    await init();
    final cacheData = {
      'data': data,
      'expireAt': DateTime.now()
          .add(duration ?? _defaultCacheDuration)
          .millisecondsSinceEpoch,
    };
    await _prefs!.setString(_cachePrefix + key, jsonEncode(cacheData));
  }

  /// 获取缓存的API响应
  Future<Map<String, dynamic>?> getCachedResponse(String key) async {
    await init();
    final raw = _prefs!.getString(_cachePrefix + key);
    if (raw == null) return null;

    try {
      final cacheData = jsonDecode(raw) as Map<String, dynamic>;
      final expireAt = cacheData['expireAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expireAt) {
        // 缓存过期，删除
        await _prefs!.remove(_cachePrefix + key);
        return null;
      }
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 清除指定缓存
  Future<void> removeCache(String key) async {
    await init();
    await _prefs!.remove(_cachePrefix + key);
  }

  /// 清除所有缓存
  Future<void> clearAll() async {
    await init();
    final keys = _prefs!.getKeys().where(
          (key) => key.startsWith(_cachePrefix),
        );
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// 预加载关键数据（用于在线时提前缓存）
  /// 需要在 ApiClient 层调用各 Repository，触发 GET 请求以自动缓存
  Future<void> preloadEssentialData({
    required Future<void> Function() fetchChildren,
    required Future<void> Function() fetchBooks,
    required Future<void> Function(String childId) fetchStats,
    required List<String> childIds,
  }) async {
    try {
      await fetchChildren();
    } catch (e) {
      // 离线或失败，忽略
    }
    try {
      await fetchBooks();
    } catch (e) {
      // 离线或失败，忽略
    }
    for (final childId in childIds) {
      try {
        await fetchStats(childId);
      } catch (e) {
        // 离线或失败，忽略
      }
    }
  }
}
