/// 学习报告 Repository
/// 对接 API 第四章：学习报告（8个接口中的 1/2/3/4）
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/learning_report_model.dart';

class LearningReportRepository {
  final ApiClient _apiClient;

  LearningReportRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// API 1：获取学习报告
  /// GET /api/v1/learning-report/:childId?period=daily&date=2026-05-07
  Future<LearningReportModel> getReport({
    required String childId,
    String period = 'daily',
    String? date,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
      if (date != null) 'date': date,
    };
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning-report/$childId',
      queryParams: queryParams,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return LearningReportModel.fromJson(response.data!);
  }

  /// API 2：获取学习报告列表（家长视角）
  /// GET /api/v1/learning-report/parent/:parentId?period=daily
  Future<List<ParentReportItem>> getReportList({
    required String parentId,
    String period = 'daily',
    String? date,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
      if (date != null) 'date': date,
    };
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning-report/parent/$parentId',
      queryParams: queryParams,
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    final list = response.data!['children'] as List<dynamic>? ?? [];
    return list.map((e) => ParentReportItem.fromJson(e)).toList();
  }

  /// API 3：生成学习报告（手动触发）
  /// POST /api/v1/learning-report/:childId/generate
  Future<void> generateReport({
    required String childId,
    String period = 'daily',
    String? date,
  }) async {
    final data = <String, dynamic>{
      'period': period,
      if (date != null) 'date': date,
    };
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/learning-report/$childId/generate',
      data: data,
    );
    if (!response.isSuccess) {
      throw ApiException(code: response.code, message: response.message);
    }
  }

  /// API 4：获取识字量趋势
  /// GET /api/v1/learning-report/:childId/characters-trend?days=30
  Future<List<CharactersPoint>> getCharactersTrend({
    required String childId,
    int days = 30,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning-report/$childId/characters-trend',
      queryParams: {'days': days},
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    final trend = response.data!['trend'] as List<dynamic>? ?? [];
    return trend.map((e) => CharactersPoint.fromJson(e)).toList();
  }
}
