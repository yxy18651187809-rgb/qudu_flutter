import 'package:equatable/equatable.dart';

/// 识字页事件基类（Tab1）
abstract class WordLearningEvent extends Equatable {
  const WordLearningEvent();

  @override
  List<Object?> get props => [];
}

/// 加载数据（首次进入）
class WordLearningLoadData extends WordLearningEvent {
  const WordLearningLoadData();
}

/// 下拉刷新
class WordLearningRefreshData extends WordLearningEvent {
  const WordLearningRefreshData();
}

/// 切换级别
class WordLearningLevelChanged extends WordLearningEvent {
  final int level;
  const WordLearningLevelChanged(this.level);

  @override
  List<Object?> get props => [level];
}

/// 网络状态变化
class WordLearningNetworkChanged extends WordLearningEvent {
  final bool isOffline;
  const WordLearningNetworkChanged(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}

/// 儿童ID变更（从外部传入）
class WordLearningChildIdChanged extends WordLearningEvent {
  final String childId;
  const WordLearningChildIdChanged(this.childId);

  @override
  List<Object?> get props => [childId];
}
