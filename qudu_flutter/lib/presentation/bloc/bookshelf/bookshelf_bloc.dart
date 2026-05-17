import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/network_interceptor.dart';
import '../../../data/repositories/books_repository.dart';
import 'bookshelf_event.dart';
import 'bookshelf_state.dart';

/// 书架 BLoC — 管理 Tab2 书架页状态
class BookshelfBloc extends Bloc<BookshelfEvent, BookshelfState> {
  final BooksRepository _booksRepository;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  BookshelfBloc({
    BooksRepository? booksRepository,
    Stream<NetworkStatus>? networkStatus,
  })  : _booksRepository = booksRepository ?? ServiceLocator.instance.booksRepository,
        super(const BookshelfState()) {
    on<BookshelfLoadData>(_onLoadData);
    on<BookshelfRefreshData>(_onRefreshData);
    on<BookshelfNetworkChanged>(_onNetworkChanged);
    on<BookshelfLevelChanged>(_onLevelChanged);

    // 监听网络状态（与 HomeBloc 一致）
    // 支持注入 networkStatus 以便测试
    final statusStream = networkStatus ?? ServiceLocator.instance.apiClient.networkStatus;
    _networkSubscription = statusStream.listen((status) {
      add(BookshelfNetworkChanged(status == NetworkStatus.offline));
    });
  }

  /// 加载书架数据（首次进入）
  Future<void> _onLoadData(BookshelfLoadData event, Emitter<BookshelfState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final books = await _booksRepository.getBooks(level: state.selectedLevel);
      final recommended = await _booksRepository.getRecommendedBooks();
      emit(state.copyWith(
        books: books,
        recommendedBooks: recommended,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// 下拉刷新
  Future<void> _onRefreshData(BookshelfRefreshData event, Emitter<BookshelfState> emit) async {
    try {
      final books = await _booksRepository.getBooks(level: state.selectedLevel);
      final recommended = await _booksRepository.getRecommendedBooks();
      emit(state.copyWith(
        books: books,
        recommendedBooks: recommended,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// 网络状态变化
  void _onNetworkChanged(BookshelfNetworkChanged event, Emitter<BookshelfState> emit) {
    emit(state.copyWith(isOffline: event.isOffline));
  }

  /// 切换级别筛选
  Future<void> _onLevelChanged(BookshelfLevelChanged event, Emitter<BookshelfState> emit) async {
    if (event.level == state.selectedLevel) return;
    emit(state.copyWith(selectedLevel: event.level, isLoading: true, errorMessage: null));
    try {
      final books = await _booksRepository.getBooks(level: event.level);
      emit(state.copyWith(books: books, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
