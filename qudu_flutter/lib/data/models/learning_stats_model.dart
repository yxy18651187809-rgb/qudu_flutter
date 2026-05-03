/// 学习统计 Model
/// 对应后端API: GET /learning/stats/:childId

class LearningStatsModel {
  final OverviewStats overview;
  final TodayStats today;
  final MasteryStats mastery;
  final List<WeeklyTrendItem> weeklyTrend;

  LearningStatsModel({
    required this.overview,
    required this.today,
    required this.mastery,
    required this.weeklyTrend,
  });

  factory LearningStatsModel.fromJson(Map<String, dynamic> json) {
    return LearningStatsModel(
      overview: OverviewStats.fromJson(json['overview'] ?? {}),
      today: TodayStats.fromJson(json['today'] ?? {}),
      mastery: MasteryStats.fromJson(json['mastery'] ?? {}),
      weeklyTrend: (json['weeklyTrend'] as List<dynamic>? ?? [])
          .map((e) => WeeklyTrendItem.fromJson(e))
          .toList(),
    );
  }
}

class OverviewStats {
  final int totalRecords;
  final int totalMinutes;
  final int totalStars;
  final int streakDays;
  final int currentLevel;

  OverviewStats({
    required this.totalRecords,
    required this.totalMinutes,
    required this.totalStars,
    required this.streakDays,
    required this.currentLevel,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalRecords: json['totalRecords'] ?? 0,
      totalMinutes: json['totalMinutes'] ?? 0,
      totalStars: json['totalStars'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
    );
  }
}

class TodayStats {
  final int records;
  final int minutes;
  final int stars;

  TodayStats({
    required this.records,
    required this.minutes,
    required this.stars,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      records: json['records'] ?? 0,
      minutes: json['minutes'] ?? 0,
      stars: json['stars'] ?? 0,
    );
  }
}

class MasteryStats {
  final int newCount;
  final int learning;
  final int reviewing;
  final int mastered;
  final int dueReview;

  MasteryStats({
    required this.newCount,
    required this.learning,
    required this.reviewing,
    required this.mastered,
    required this.dueReview,
  });

  factory MasteryStats.fromJson(Map<String, dynamic> json) {
    return MasteryStats(
      newCount: json['new'] ?? 0,
      learning: json['learning'] ?? 0,
      reviewing: json['reviewing'] ?? 0,
      mastered: json['mastered'] ?? 0,
      dueReview: json['dueReview'] ?? 0,
    );
  }
}

class WeeklyTrendItem {
  final String date;
  final int count;
  final int minutes;
  final int stars;

  WeeklyTrendItem({
    required this.date,
    required this.count,
    required this.minutes,
    required this.stars,
  });

  factory WeeklyTrendItem.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendItem(
      date: json['_id'] ?? json['date'] ?? '',
      count: json['count'] ?? 0,
      minutes: json['minutes'] ?? 0,
      stars: json['stars'] ?? 0,
    );
  }
}