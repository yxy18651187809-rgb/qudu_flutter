/// 家长监控 Repository
/// 对接家长监控 API（4个接口）
library;

import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/parent_monitoring_model.dart';

class ParentMonitoringRepository {
  final ApiClient _apiClient;

  ParentMonitoringRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// API 5：获取监控概览
  /// GET /api/v1/parent-monitoring/:parentId
  Future<MonitoringOverview> getOverview({
    required String parentId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/parent-monitoring/$parentId',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return MonitoringOverview.fromJson(response.data!);
  }

  /// API 6：获取单个孩子的监控详情
  /// GET /api/v1/parent-monitoring/:parentId/child/:childId
  Future<ChildMonitoringDetail> getChildDetail({
    required String parentId,
    required String childId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/parent-monitoring/$parentId/child/$childId',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return ChildMonitoringDetail.fromJson(response.data!);
  }

  /// API 7：更新监控阈值
  /// PUT /api/v1/parent-monitoring/:parentId/child/:childId/thresholds
  Future<void> updateThresholds({
    required String parentId,
    required String childId,
    int? maxDailyStudyTime,
    int? minDailyStudyTime,
    int? minCharactersPerDay,
    int? minAccuracy,
    int? maxReviewDelayDays,
  }) async {
    final data = <String, dynamic>{
      if (maxDailyStudyTime != null) 'maxDailyStudyTime': maxDailyStudyTime,
      if (minDailyStudyTime != null) 'minDailyStudyTime': minDailyStudyTime,
      if (minCharactersPerDay != null) 'minCharactersPerDay': minCharactersPerDay,
      if (minAccuracy != null) 'minAccuracy': minAccuracy,
      if (maxReviewDelayDays != null) 'maxReviewDelayDays': maxReviewDelayDays,
    };
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/parent-monitoring/$parentId/child/$childId/thresholds',
      data: data,
    );
    if (!response.isSuccess) {
      throw ApiException(code: response.code, message: response.message);
    }
  }

  /// API 8：更新告警设置
  /// PUT /api/v1/parent-monitoring/:parentId/alert-settings
  Future<void> updateAlertSettings({
    required String parentId,
    bool? enableStudyTimeAlert,
    bool? enableAccuracyAlert,
    bool? enableReviewAlert,
    List<String>? alertMethods,
  }) async {
    final data = <String, dynamic>{
      if (enableStudyTimeAlert != null)
        'enableStudyTimeAlert': enableStudyTimeAlert,
      if (enableAccuracyAlert != null)
        'enableAccuracyAlert': enableAccuracyAlert,
      if (enableReviewAlert != null)
        'enableReviewAlert': enableReviewAlert,
      if (alertMethods != null) 'alertMethods': alertMethods,
    };
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/parent-monitoring/$parentId/alert-settings',
      data: data,
    );
    if (!response.isSuccess) {
      throw ApiException(code: response.code, message: response.message);
    }
  }
}
