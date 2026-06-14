import 'package:equatable/equatable.dart';

/// 个人中心事件基类（Tab3）
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// 加载数据（首次进入）
class ProfileLoadData extends ProfileEvent {
  const ProfileLoadData();
}

/// 下拉刷新
class ProfileRefreshData extends ProfileEvent {
  const ProfileRefreshData();
}

/// 网络状态变化
class ProfileNetworkChanged extends ProfileEvent {
  final bool isOffline;
  const ProfileNetworkChanged(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}
