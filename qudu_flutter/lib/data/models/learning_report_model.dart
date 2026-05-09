/// 学习报告 Model
/// 对接 API 第四章：学习报告（8个接口中的1/2/3/4）

/// 学习报告主模型（对应 API 1 响应）
class LearningReportModel {
  final String childId;
  final String childName;
  final String period; // 'daily' | 'weekly' | 'monthly'
  final String date; // '2026-05-07'
  final LearningStats statistics;
  final LearningProgress progress;
  final LearningTrends trends;
  final LearningReview review;

  LearningReportModel({
    required this.childId,
    required this.childName,
    required this.period,
    required this.date,
    required this.statistics,
    required this.progress,
    required this.trends,
    required this.review,
  });

  factory LearningReportModel.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] ?? {};
    final prog = json['progress'] ?? {};
    final tr = json['trends'] ?? {};
    final rev = json['review'] ?? {};
    return LearningReportModel(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '未知',
      period: json['period'] ?? 'daily',
      date: json['date'] ?? '',
      statistics: LearningStats.fromJson(stats),
      progress: LearningProgress.fromJson(prog),
      trends: LearningTrends.fromJson(tr),
      review: LearningReview.fromJson(rev),
    );
  }
}

/// 统计数据
class LearningStats {
  final int studyTime; // 分钟
  final int charactersLearned;
  final int booksRead;
  final int assessmentCount;
  final int averageAccuracy; // 百分比 0-100

  LearningStats({
    required this.studyTime,
    required this.charactersLearned,
    required this.booksRead,
    required this.assessmentCount,
    required this.averageAccuracy,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) =>
      LearningStats(
        studyTime: json['studyTime'] ?? 0,
        charactersLearned: json['charactersLearned'] ?? 0,
        booksRead: json['booksRead'] ?? 0,
        assessmentCount: json['assessmentCount'] ?? 0,
        averageAccuracy: json['averageAccuracy'] ?? 0,
      );
}

/// 进度信息
class LearningProgress {
  final int totalCharacters;
  final int level;
  final int nextLevelCharacters;

  LearningProgress({
    required this.totalCharacters,
    required this.level,
    required this.nextLevelCharacters,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      LearningProgress(
        totalCharacters: json['totalCharacters'] ?? 0,
        level: json['level'] ?? 1,
        nextLevelCharacters: json['nextLevelCharacters'] ?? 0,
      );
}

/// 趋势数据
class LearningTrends {
  final List<AccuracyPoint> accuracy;
  final List<CharactersPoint> characters;

  LearningTrends({
    required this.accuracy,
    required this.characters,
  });

  factory LearningTrends.fromJson(Map<String, dynamic> json) {
    final accList = json['accuracy'] as List<dynamic>? ?? [];
    final charList = json['characters'] as List<dynamic>? ?? [];
    return LearningTrends(
      accuracy:
          accList.map((e) => AccuracyPoint.fromJson(e)).toList(),
      characters:
          charList.map((e) => CharactersPoint.fromJson(e)).toList(),
    );
  }
}

class AccuracyPoint {
  final String date;
  final int accuracy;

  AccuracyPoint({required this.date, required this.accuracy});

  factory AccuracyPoint.fromJson(Map<String, dynamic> json) => AccuracyPoint(
        date: json['date'] ?? '',
        accuracy: json['accuracy'] ?? 0,
      );
}

class CharactersPoint {
  final String date;
  final int count;

  CharactersPoint({required this.date, required this.count});

  factory CharactersPoint.fromJson(Map<String, dynamic> json) =>
      CharactersPoint(
        date: json['date'] ?? '',
        count: json['count'] ?? 0,
      );
}

/// 复习状态
class LearningReview {
  final int due;
  final int completed;
  final int rate; // 百分比 0-100

  LearningReview({
    required this.due,
    required this.completed,
    required this.rate,
  });

  factory LearningReview.fromJson(Map<String, dynamic> json) =>
      LearningReview(
        due: json['due'] ?? 0,
        completed: json['completed'] ?? 0,
        rate: json['rate'] ?? 0,
      );
}

/// 家长视角报告列表项（对应 API 2 响应）
class ParentReportItem {
  final String childId;
  final String childName;
  final String avatarUrl;
  final LearningStats? statistics;
  final List<ReportAlert> alerts;

  ParentReportItem({
    required this.childId,
    required this.childName,
    required this.avatarUrl,
    required this.statistics,
    required this.alerts,
  });

  factory ParentReportItem.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'];
    final alertList = json['alerts'] as List<dynamic>? ?? [];
    return ParentReportItem(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      statistics:
          stats != null ? LearningStats.fromJson(stats) : null,
      alerts:
          alertList.map((e) => ReportAlert.fromJson(e)).toList(),
    );
  }
}

class ReportAlert {
  final String type;
  final String message;

  ReportAlert({required this.type, required this.message});

  factory ReportAlert.fromJson(Map<String, dynamic> json) => ReportAlert(
        type: json['type'] ?? '',
        message: json['message'] ?? '',
      );
}
