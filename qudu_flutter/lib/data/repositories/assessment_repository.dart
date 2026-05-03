/// 测评 Repository
/// 对接后端 API：第七章 识字测评模块
import '../../core/network/api_client.dart';
import '../../core/di/service_locator.dart';
import '../models/assessment_model.dart';

class AssessmentRepository {
  ApiClient get _api => ServiceLocator.instance.apiClient;

  /// 开始测评
  /// POST /assessments/start
  /// - type=review 时必须传入 bookId
  Future<AssessmentModel?> startAssessment({
    required String childId,
    AssessmentType type = AssessmentType.initial,
    int? targetLevel,
    int? questionCount,
    String? bookId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/assessments/start',
      data: {
        'childId': childId,
        'type': type.apiValue,
        if (targetLevel != null) 'targetLevel': targetLevel,
        if (questionCount != null) 'questionCount': questionCount,
        if (bookId != null) 'bookId': bookId,
      },
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }

    final data = response.data!['data'] ?? response.data;
    return AssessmentModel.fromJson(data);
  }

  /// 提交测评答案
  /// POST /assessments/:id/submit
  Future<AssessmentResult?> submitAnswers({
    required String assessmentId,
    required List<AssessmentAnswer> answers,
    required int duration,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/assessments/$assessmentId/submit',
      data: {
        'answers': answers.map((a) => a.toJson()).toList(),
        'duration': duration,
      },
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }

    final data = response.data!['data'] ?? response.data;
    return AssessmentResult.fromJson(data);
  }

  /// 获取测评结果
  /// GET /assessments/:id
  Future<AssessmentModel?> getAssessment(String assessmentId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/assessments/$assessmentId',
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }

    final data = response.data!['data'] ?? response.data;
    return AssessmentModel.fromJson(data);
  }

  /// 获取测评历史
  /// GET /assessments/history/:childId
  Future<List<AssessmentHistory>> getHistory({
    required String childId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/assessments/history/$childId',
      queryParams: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    if (!response.isSuccess || response.data == null) {
      return [];
    }

    final data = response.data!['data'] ?? response.data;
    final list = data['list'] as List<dynamic>? ?? [];
    return list.map((e) => AssessmentHistory.fromJson(e)).toList();
  }
}
