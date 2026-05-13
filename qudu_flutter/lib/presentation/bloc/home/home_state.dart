import 'package:equatable/equatable.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/learning_stats_model.dart';

/// 首页状态
class HomeState extends Equatable {
  final List<ChildModel> children;
  final LearningStatsModel? stats;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;

  const HomeState({
    this.children = const [],
    this.stats,
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
  });

  /// 活跃儿童（默认取第一个）
  ChildModel? get activeChild => children.isNotEmpty ? children.first : null;

  /// 学习数据便捷访问
  int get todayWords => stats?.today.records ?? 0;
  int get totalWords => (stats?.mastery.newCount ?? 0) + (stats?.mastery.mastered ?? 0);
  int get totalBooks => stats?.overview.totalStars ?? 0;
  int get streakDays => stats?.overview.streakDays ?? 0;
  List<WeeklyTrendItem> get weeklyTrend => stats?.weeklyTrend ?? [];

  HomeState copyWith({
    List<ChildModel>? children,
    LearningStatsModel? stats,
    bool? isLoading,
    bool? isOffline,
    String? errorMessage,
  }) {
    return HomeState(
      children: children ?? this.children,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [children, stats, isLoading, isOffline, errorMessage];
}
