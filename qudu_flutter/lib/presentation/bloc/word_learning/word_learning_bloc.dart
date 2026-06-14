import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/network_interceptor.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/repositories/character_repository.dart';
import 'word_learning_event.dart';
import 'word_learning_state.dart';

/// 识字 BLoC — 管理 Tab1 识字页状态
class WordLearningBloc extends Bloc<WordLearningEvent, WordLearningState> {
  final CharacterRepository _characterRepository;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  WordLearningBloc({
    CharacterRepository? characterRepository,
    Stream<NetworkStatus>? networkStatus,
    int? initialLevel,
    String? initialChildId,
  })  : _characterRepository =
            characterRepository ?? CharacterRepository(),
        super(WordLearningState(
          selectedLevel: initialLevel ?? 1,
          currentChildId: initialChildId,
        )) {
    on<WordLearningLoadData>(_onLoadData);
    on<WordLearningRefreshData>(_onRefreshData);
    on<WordLearningLevelChanged>(_onLevelChanged);
    on<WordLearningNetworkChanged>(_onNetworkChanged);
    on<WordLearningChildIdChanged>(_onChildIdChanged);

    // 监听网络状态
    final statusStream =
        networkStatus ?? ServiceLocator.instance.apiClient.networkStatus;
    _networkSubscription = statusStream.listen((status) {
      add(WordLearningNetworkChanged(status == NetworkStatus.offline));
    });
  }

  /// 加载数据（首次进入）
  Future<void> _onLoadData(
    WordLearningLoadData event,
    Emitter<WordLearningState> emit,
  ) async {
    // 如果还没有 childId，尝试从存储获取
    if (state.currentChildId == null) {
      final childId = await StorageService.getCurrentChildId();
      emit(state.copyWith(currentChildId: childId));
    }
    await _loadCharacters(emit);
  }

  /// 下拉刷新
  Future<void> _onRefreshData(
    WordLearningRefreshData event,
    Emitter<WordLearningState> emit,
  ) async {
    await _loadCharacters(emit);
  }

  /// 切换级别
  Future<void> _onLevelChanged(
    WordLearningLevelChanged event,
    Emitter<WordLearningState> emit,
  ) async {
    if (event.level == state.selectedLevel) return;
    emit(state.copyWith(
      selectedLevel: event.level,
      isLoading: true,
      errorMessage: null,
    ));
    await _loadCharacters(emit);
  }

  /// 网络状态变化
  void _onNetworkChanged(
    WordLearningNetworkChanged event,
    Emitter<WordLearningState> emit,
  ) {
    emit(state.copyWith(isOffline: event.isOffline));
  }

  /// 儿童ID变更
  Future<void> _onChildIdChanged(
    WordLearningChildIdChanged event,
    Emitter<WordLearningState> emit,
  ) async {
    if (event.childId == state.currentChildId) return;
    emit(state.copyWith(
      currentChildId: event.childId,
      isLoading: true,
      errorMessage: null,
    ));
    await _loadCharacters(emit);
  }

  /// 核心：加载字卡列表 + 学习统计
  Future<void> _loadCharacters(Emitter<WordLearningState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // 并行加载：汉字列表 + 学习统计
      final results = await Future.wait([
        _characterRepository.getCharactersByLevel(
          state.selectedLevel,
          childId: state.currentChildId,
        ),
        if (state.currentChildId != null)
          _characterRepository.getLearningStats(state.currentChildId!)
        else
          Future.value(null),
      ]);

      final chars = results[0] as List<dynamic>;
      final stats = results[1] as LearningStats?;

      emit(state.copyWith(
        characters: chars.cast(),
        reviewCount: stats?.dueReview ?? 0,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
