// 汉字识字 Repository
// 对接API契约第五章：汉字列表/详情/学习统计
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/di/service_locator.dart';
import '../models/character_model.dart';

/// 汉字 Repository
/// 所有方法使用真实后端API
class CharacterRepository {
  ApiClient get _api => ServiceLocator.instance.apiClient;

  /// 获取某级别的汉字列表
  /// GET /api/v1/characters?level=1&childId=xxx
  /// [level] 1-5，对应 L1-L5
  /// [childId] 可选，传入后返回该儿童的掌握进度
  Future<List<CharacterModel>> getCharactersByLevel(
    int level, {
    String? childId,
  }) async {
    final queryParams = <String, dynamic>{
      'level': level.toString(),
    };
    if (childId != null && childId.isNotEmpty) {
      queryParams['childId'] = childId;
    }

    final response = await _api.get<Map<String, dynamic>>(
      '/characters',
      queryParams: queryParams,
    );

    if (!response.isSuccess || response.data == null) {
      throw ApiException(
        code: response.code,
        message: response.message,
      );
    }

    final list = response.data!['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => CharacterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取汉字详情（含例句、字源）
  /// GET /api/v1/characters/:id
  Future<CharacterModel?> getCharacterDetail(String id) async {
    final response = await _api.get<Map<String, dynamic>>('/characters/$id');

    if (!response.isSuccess || response.data == null) {
      return null;
    }
    return CharacterModel.fromJson(response.data!);
  }

  /// 获取儿童的学习统计（含今日待复习数）
  /// GET /api/v1/learning/stats/:childId
  Future<LearningStats?> getLearningStats(String childId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/learning/stats/$childId',
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }
    return LearningStats.fromJson(response.data!);
  }

  /// 获取儿童的待复习汉字列表（遗忘曲线驱动）
  /// [childId] 儿童ID
  /// 返回今日需要复习的汉字
  Future<List<CharacterModel>> getReviewQueue(String childId) async {
    try {
      final stats = await getLearningStats(childId);
      if (stats == null) return [];

      // 根据stats中的dueReview数量获取对应汉字
      if (stats.dueReview <= 0) return [];

      // 从L1获取前N个待复习汉字
      final chars = await getCharactersByLevel(1, childId: childId);
      return chars.where((c) => c.needsReview).take(stats.dueReview).toList();
    } catch (_) {
      return [];
    }
  }
}

/// 学习统计数据模型
/// 对应后端 /learning/stats/:childId 响应
class LearningStats {
  final int totalWords;        // 累计学习字数
  final int masteredWords;     // 已掌握字数
  final int dueReview;         // 今日待复习数
  final int streakDays;        // 连续学习天数
  final int totalReadingMinutes; // 累计阅读时长（分钟）

  const LearningStats({
    required this.totalWords,
    required this.masteredWords,
    required this.dueReview,
    required this.streakDays,
    required this.totalReadingMinutes,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      totalWords: json['totalWords'] as int? ?? 0,
      masteredWords: json['masteredWords'] as int? ?? 0,
      dueReview: json['dueReview'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      totalReadingMinutes: json['totalReadingMinutes'] as int? ?? 0,
    );
  }
}
