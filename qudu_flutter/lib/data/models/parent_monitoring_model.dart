/// 家长监控 Model
/// 对接家长监控 API（4个接口）
library;

/// 监控概览 - 单个孩子的概览数据
class MonitoringChildOverview {
  final String childId;
  final String childName;
  final String avatarUrl;
  final MonitoringToday today;
  final List<MonitoringAlert> alerts;

  MonitoringChildOverview({
    required this.childId,
    required this.childName,
    required this.avatarUrl,
    required this.today,
    required this.alerts,
  });

  factory MonitoringChildOverview.fromJson(Map<String, dynamic> json) {
    final today = json['today'] ?? {};
    final alertList = json['alerts'] as List<dynamic>? ?? [];
    return MonitoringChildOverview(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '未知',
      avatarUrl: json['avatarUrl'] ?? '',
      today: MonitoringToday.fromJson(today),
      alerts: alertList.map((e) => MonitoringAlert.fromJson(e)).toList(),
    );
  }
}

/// 今日学习数据
class MonitoringToday {
  final int studyTime;
  final int maxStudyTime;
  final int charactersLearned;
  final int minCharacters;
  final int accuracy;
  final int minAccuracy;
  final int reviewDue;

  MonitoringToday({
    required this.studyTime,
    required this.maxStudyTime,
    required this.charactersLearned,
    required this.minCharacters,
    required this.accuracy,
    required this.minAccuracy,
    required this.reviewDue,
  });

  factory MonitoringToday.fromJson(Map<String, dynamic> json) =>
      MonitoringToday(
        studyTime: json['studyTime'] ?? 0,
        maxStudyTime: json['maxStudyTime'] ?? 60,
        charactersLearned: json['charactersLearned'] ?? 0,
        minCharacters: json['minCharacters'] ?? 3,
        accuracy: json['accuracy'] ?? 0,
        minAccuracy: json['minAccuracy'] ?? 70,
        reviewDue: json['reviewDue'] ?? 0,
      );
}

/// 告警信息
class MonitoringAlert {
  final String type;
  final String message;
  final String severity;

  MonitoringAlert({
    required this.type,
    required this.message,
    required this.severity,
  });

  factory MonitoringAlert.fromJson(Map<String, dynamic> json) =>
      MonitoringAlert(
        type: json['type'] ?? '',
        message: json['message'] ?? '',
        severity: json['severity'] ?? 'info',
      );
}

/// 监控概览响应（API 5）
class MonitoringOverview {
  final String parentId;
  final List<MonitoringChildOverview> children;

  MonitoringOverview({
    required this.parentId,
    required this.children,
  });

  factory MonitoringOverview.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>? ?? [];
    return MonitoringOverview(
      parentId: json['parentId'] ?? '',
      children:
          childrenList.map((e) => MonitoringChildOverview.fromJson(e)).toList(),
    );
  }
}

/// 周度学习数据
class MonitoringWeekly {
  final int averageStudyTime;
  final double averageCharacters;
  final int averageAccuracy;
  final int reviewCompletionRate;

  MonitoringWeekly({
    required this.averageStudyTime,
    required this.averageCharacters,
    required this.averageAccuracy,
    required this.reviewCompletionRate,
  });

  factory MonitoringWeekly.fromJson(Map<String, dynamic> json) =>
      MonitoringWeekly(
        averageStudyTime: json['averageStudyTime'] ?? 0,
        averageCharacters: (json['averageCharacters'] ?? 0).toDouble(),
        averageAccuracy: json['averageAccuracy'] ?? 0,
        reviewCompletionRate: json['reviewCompletionRate'] ?? 0,
      );
}

/// 监控阈值设置
class MonitoringThresholds {
  final int maxDailyStudyTime;
  final int minDailyStudyTime;
  final int minCharactersPerDay;
  final int minAccuracy;
  final int maxReviewDelayDays;

  MonitoringThresholds({
    required this.maxDailyStudyTime,
    required this.minDailyStudyTime,
    required this.minCharactersPerDay,
    required this.minAccuracy,
    required this.maxReviewDelayDays,
  });

  factory MonitoringThresholds.fromJson(Map<String, dynamic> json) =>
      MonitoringThresholds(
        maxDailyStudyTime: json['maxDailyStudyTime'] ?? 60,
        minDailyStudyTime: json['minDailyStudyTime'] ?? 15,
        minCharactersPerDay: json['minCharactersPerDay'] ?? 3,
        minAccuracy: json['minAccuracy'] ?? 70,
        maxReviewDelayDays: json['maxReviewDelayDays'] ?? 2,
      );

  Map<String, dynamic> toJson() => {
        'maxDailyStudyTime': maxDailyStudyTime,
        'minDailyStudyTime': minDailyStudyTime,
        'minCharactersPerDay': minCharactersPerDay,
        'minAccuracy': minAccuracy,
        'maxReviewDelayDays': maxReviewDelayDays,
      };
}

/// 告警设置
class MonitoringAlertSettings {
  final bool enableStudyTimeAlert;
  final bool enableAccuracyAlert;
  final bool enableReviewAlert;
  final List<String> alertMethods;

  MonitoringAlertSettings({
    required this.enableStudyTimeAlert,
    required this.enableAccuracyAlert,
    required this.enableReviewAlert,
    required this.alertMethods,
  });

  factory MonitoringAlertSettings.fromJson(Map<String, dynamic> json) =>
      MonitoringAlertSettings(
        enableStudyTimeAlert: json['enableStudyTimeAlert'] ?? true,
        enableAccuracyAlert: json['enableAccuracyAlert'] ?? true,
        enableReviewAlert: json['enableReviewAlert'] ?? true,
        alertMethods: (json['alertMethods'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'enableStudyTimeAlert': enableStudyTimeAlert,
        'enableAccuracyAlert': enableAccuracyAlert,
        'enableReviewAlert': enableReviewAlert,
        'alertMethods': alertMethods,
      };
}

/// 单个孩子监控详情响应（API 6）
class ChildMonitoringDetail {
  final String childId;
  final String childName;
  final MonitoringThresholds thresholds;
  final MonitoringToday today;
  final MonitoringWeekly weekly;
  final MonitoringAlertSettings alertSettings;

  ChildMonitoringDetail({
    required this.childId,
    required this.childName,
    required this.thresholds,
    required this.today,
    required this.weekly,
    required this.alertSettings,
  });

  factory ChildMonitoringDetail.fromJson(Map<String, dynamic> json) {
    final thresholds = json['thresholds'] ?? {};
    final today = json['today'] ?? {};
    final weekly = json['weekly'] ?? {};
    final alertSettings = json['alertSettings'] ?? {};
    return ChildMonitoringDetail(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '未知',
      thresholds: MonitoringThresholds.fromJson(thresholds),
      today: MonitoringToday.fromJson(today),
      weekly: MonitoringWeekly.fromJson(weekly),
      alertSettings: MonitoringAlertSettings.fromJson(alertSettings),
    );
  }
}
