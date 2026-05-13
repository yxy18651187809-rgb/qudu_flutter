import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/network_interceptor.dart';
import '../../../data/repositories/children_repository.dart';
import '../../../data/repositories/learning_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

/// 首页 BLoC — 管理 Tab0 首页状态
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ChildrenRepository _childrenRepository;
  final LearningRepository _learningRepository;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  HomeBloc({
    ChildrenRepository? childrenRepository,
    LearningRepository? learningRepository,
  })  : _childrenRepository = childrenRepository ?? ServiceLocator.instance.childrenRepository,
        _learningRepository = learningRepository ?? ServiceLocator.instance.learningRepository,
        super(const HomeState()) {
    on<HomeLoadData>(_onLoadData);
    on<HomeRefreshData>(_onRefreshData);
    on<HomeNetworkChanged>(_onNetworkChanged);
    on<HomeSwitchChild>(_onSwitchChild);

    // 监听网络状态
    _networkSubscription = ServiceLocator.instance.apiClient.networkStatus.listen((status) {
      add(HomeNetworkChanged(status == NetworkStatus.offline));
    });
  }

  Future<void> _onLoadData(HomeLoadData event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final children = await _childrenRepository.getChildren();
      if (children.isNotEmpty) {
        final stats = await _learningRepository.getStats(children.first.id);
        emit(state.copyWith(
          children: children,
          stats: stats,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(children: children, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshData(HomeRefreshData event, Emitter<HomeState> emit) async {
    try {
      final children = await _childrenRepository.getChildren();
      if (children.isNotEmpty) {
        final stats = await _learningRepository.getStats(children.first.id);
        emit(state.copyWith(
          children: children,
          stats: stats,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(children: children, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onNetworkChanged(HomeNetworkChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(isOffline: event.isOffline));
  }

  Future<void> _onSwitchChild(HomeSwitchChild event, Emitter<HomeState> emit) async {
    try {
      final stats = await _learningRepository.getStats(event.childId);
      emit(state.copyWith(stats: stats));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
