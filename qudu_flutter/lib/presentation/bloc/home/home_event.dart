import 'package:equatable/equatable.dart';

/// 首页事件基类
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// 加载首页数据
class HomeLoadData extends HomeEvent {
  const HomeLoadData();
}

/// 刷新首页数据（下拉刷新）
class HomeRefreshData extends HomeEvent {
  const HomeRefreshData();
}

/// 网络状态变化
class HomeNetworkChanged extends HomeEvent {
  final bool isOffline;

  const HomeNetworkChanged(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}

/// 切换活跃儿童
class HomeSwitchChild extends HomeEvent {
  final String childId;

  const HomeSwitchChild(this.childId);

  @override
  List<Object?> get props => [childId];
}
