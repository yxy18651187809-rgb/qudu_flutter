import 'package:equatable/equatable.dart';
import '../../../data/models/child_model.dart';

/// 个人中心状态（Tab3）
class ProfileState extends Equatable {
  final List<ChildModel> children;
  final String? parentId;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;

  const ProfileState({
    this.children = const [],
    this.parentId,
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
  });

  /// 是否有孩子档案
  bool get hasChildren => children.isNotEmpty;

  /// 第一个孩子名称（用于头像提示）
  String get displayName =>
      hasChildren ? '${children.first.name}的账号' : '字趣阅读';

  /// 孩子数量
  int get childCount => children.length;

  ProfileState copyWith({
    List<ChildModel>? children,
    String? parentId,
    bool? isLoading,
    bool? isOffline,
    String? errorMessage,
  }) {
    return ProfileState(
      children: children ?? this.children,
      parentId: parentId ?? this.parentId,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        children,
        parentId,
        isLoading,
        isOffline,
        errorMessage,
      ];
}
