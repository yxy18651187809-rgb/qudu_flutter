/// 学习记录 Repository
/// 对接API契约第五章：学习记录 + 学习统计
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/learning_stats_model.dart';

class LearningRepository {
  final ApiClient _apiClient;

  LearningRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取学习统计
  /// GET /api/v1/learning/stats/:childId
  Future<LearningStatsModel> getStats(String childId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/stats/$childId',
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return LearningStatsModel.fromJson(response.data!);
  }

  /// 记录学习数据
  /// POST /api/v1/learning/record
  Future<LearningRecordResult> recordLearning({
    required String childId,
    required String type,
    String? subtype,
    String? bookId,
    List<CharacterResult>? characters,
    int? duration,
    String? startTime,
    String? endTime,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/learning/record',
      data: {
        'childId': childId,
        'type': type,
        if (subtype != null) 'subtype': subtype,
        if (bookId != null) 'bookId': bookId,
        if (characters != null)
          'characters': characters.map((c) => c.toJson()).toList(),
        if (duration != null) 'duration': duration,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
      },
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    return LearningRecordResult.fromJson(response.data!);
  }

  /// 获取学习历史
  /// GET /api/v1/learning/history/:childId
  Future<List<LearningRecordResult>> getHistory({
    required String childId,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/history/$childId',
      queryParams: {
        if (type != null) 'type': type,
        'page': page,
        'pageSize': pageSize,
      },
    );
    if (!response.isSuccess || response.data == null) {
      throw ApiException(code: response.code, message: response.message);
    }
    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list.map((e) => LearningRecordResult.fromJson(e)).toList();
  }
}

class CharacterResult {
  final String characterId;
  final String character;
  final String result;
  final int? responseTime;

  CharacterResult({
    required this.characterId,
    required this.character,
    required this.result,
    this.responseTime,
  });

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'character': character,
        'result': result,
        if (responseTime != null) 'responseTime': responseTime,
      };
}

class LearningRecordResult {
  final String recordId;
  final int starsEarned;
  final int coinsEarned;
  final int correctCount;
  final int totalCount;
  final double accuracy;

  LearningRecordResult({
    required this.recordId,
    required this.starsEarned,
    required this.coinsEarned,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
  });

  factory LearningRecordResult.fromJson(Map<String, dynamic> json) {
    return LearningRecordResult(
      recordId: json['recordId'] ?? '',
      starsEarned: json['starsEarned'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
    );
  }
}