import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/network_interceptor.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/repositories/children_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// 个人中心 BLoC — 管理 Tab3 我的页状态
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ChildrenRepository _childrenRepository;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  ProfileBloc({
    ChildrenRepository? childrenRepository,
    Stream<NetworkStatus>? networkStatus,
    String? parentId,
  })  : _childrenRepository =
            childrenRepository ??
            ChildrenRepository(
                apiClient: ServiceLocator.instance.apiClient),
        super(ProfileState(parentId: parentId)) {
    on<ProfileLoadData>(_onLoadData);
    on<ProfileRefreshData>(_onRefreshData);
    on<ProfileNetworkChanged>(_onNetworkChanged);

    // 监听网络状态
    final statusStream =
        networkStatus ?? ServiceLocator.instance.apiClient.networkStatus;
    _networkSubscription = statusStream.listen((status) {
      add(ProfileNetworkChanged(status == NetworkStatus.offline));
    });
  }

  /// 加载数据（首次进入）
  Future<void> _onLoadData(
    ProfileLoadData event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // 如果未从外部注入，从 StorageService 获取
      final parentId =
          state.parentId ?? await StorageService.getUserId();
      final children = await _childrenRepository.getChildren();
      emit(state.copyWith(
        parentId: parentId,
        children: children,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// 下拉刷新
  Future<void> _onRefreshData(
    ProfileRefreshData event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final children = await _childrenRepository.getChildren();
      emit(state.copyWith(
        children: children,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// 网络状态变化
  void _onNetworkChanged(
    ProfileNetworkChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(isOffline: event.isOffline));
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
