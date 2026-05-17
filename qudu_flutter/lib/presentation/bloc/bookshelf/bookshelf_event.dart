import 'package:equatable/equatable.dart';

/// 书架事件基类
abstract class BookshelfEvent extends Equatable {
  const BookshelfEvent();

  @override
  List<Object?> get props => [];
}

/// 加载书架数据（首次进入）
class BookshelfLoadData extends BookshelfEvent {
  const BookshelfLoadData();
}

/// 下拉刷新
class BookshelfRefreshData extends BookshelfEvent {
  const BookshelfRefreshData();
}

/// 网络状态变化
class BookshelfNetworkChanged extends BookshelfEvent {
  final bool isOffline;

  const BookshelfNetworkChanged(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}

/// 切换级别筛选
class BookshelfLevelChanged extends BookshelfEvent {
  final String level;

  const BookshelfLevelChanged(this.level);

  @override
  List<Object?> get props => [level];
}
