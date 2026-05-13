// 绘本书架 Repository
// 对接API契约第六章：绘本列表/详情/推荐
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/di/service_locator.dart';
import '../models/book_model.dart';

/// 绘本 Repository
/// 所有方法使用真实后端API
class BooksRepository {
  final ApiClient? _injectedApi;

  BooksRepository({ApiClient? apiClient}) : _injectedApi = apiClient;

  ApiClient get _api => _injectedApi ?? ServiceLocator.instance.apiClient;

  /// 获取绘本列表（按级别筛选）
  /// GET /api/v1/books?level=1&childId=xxx
  Future<List<BookModel>> getBooks({String? level, String? childId}) async {
    final queryParams = <String, dynamic>{};
    if (level != null && level.isNotEmpty) {
      // 转换 "L1" → "1"（后端期望数字字符串）
      final levelNum = level.startsWith('L') ? level.substring(1) : level;
      queryParams['level'] = levelNum;
    }
    if (childId != null && childId.isNotEmpty) queryParams['childId'] = childId;

    final response = await _api.get<Map<String, dynamic>>(
      '/books',
      queryParams: queryParams,
    );

    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        code: response.code,
        message: response.message,
      );
    }

    // 响应格式：{ list: [...] }
    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取单个绘本详情
  /// GET /api/v1/books/:id?childId=xxx
  Future<BookModel?> getBookDetail(String bookId, {String? childId}) async {
    final queryParams = <String, dynamic>{};
    if (childId != null && childId.isNotEmpty) {
      queryParams['childId'] = childId;
    }

    final response = await _api.get<Map<String, dynamic>>(
      '/books/$bookId',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }
    return BookModel.fromJson(response.data!);
  }

  /// 获取推荐绘本
  /// GET /api/v1/books/recommended?childId=xxx
  Future<List<BookModel>> getRecommendedBooks({String? childId}) async {
    final queryParams = <String, dynamic>{};
    if (childId != null && childId.isNotEmpty) queryParams['childId'] = childId;

    final response = await _api.get<Map<String, dynamic>>(
      '/books/recommended',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (!response.isSuccess || response.data == null) {
      return [];
    }

    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取免费绘本
  /// GET /api/v1/books/free
  Future<List<BookModel>> getFreeBooks() async {
    final response = await _api.get<Map<String, dynamic>>('/books/free');

    if (!response.isSuccess || response.data == null) {
      return [];
    }

    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取主题列表
  /// GET /api/v1/books/themes
  Future<List<String>> getThemes() async {
    final response = await _api.get<Map<String, dynamic>>('/books/themes');

    if (!response.isSuccess || response.data == null) {
      return [];
    }

    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }
}
