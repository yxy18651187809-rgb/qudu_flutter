import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/core/network/network_interceptor.dart';
import 'package:ziqu_reading/data/models/book_model.dart';
import 'package:ziqu_reading/data/repositories/books_repository.dart';
import 'package:ziqu_reading/presentation/bloc/bookshelf/bookshelf_bloc.dart';
import 'package:ziqu_reading/presentation/bloc/bookshelf/bookshelf_event.dart';
import 'package:ziqu_reading/presentation/bloc/bookshelf/bookshelf_state.dart';

import '../repositories/auth_repository_test.dart';

/// 构建测试用 BookModel
BookModel _buildTestBook({
  String id = 'book1',
  String title = '测试绘本',
  String level = 'L1',
  List<String> newWords = const ['大', '小'],
}) {
  return BookModel(
    id: id,
    title: title,
    cover: '/covers/test.png',
    level: level,
    newWords: newWords,
    totalPages: 10,
  );
}

/// Mock books 列表 API 响应
ApiResponse<Map<String, dynamic>> _booksListResponse(List<BookModel> books) {
  return ApiResponse(
    code: 0,
    data: {
      'list': books.map((b) => b.toJson()).toList(),
    },
    message: 'ok',
  );
}

/// 创建空的 NetworkStatus 流（测试用，避免依赖 ServiceLocator）
Stream<NetworkStatus> _dummyNetworkStream() =>
    const Stream.empty();

void main() {
  late TestableApiClient mockApi;
  late BooksRepository booksRepo;

  final testBooks = [
    _buildTestBook(id: 'b1', title: '绘本一', level: 'L1'),
    _buildTestBook(id: 'b2', title: '绘本二', level: 'L1'),
  ];

  final testRecommendedBooks = [
    _buildTestBook(id: 'r1', title: '推荐一', level: 'L1'),
  ];

  final testL2Books = [
    _buildTestBook(id: 'b3', title: '绘本三', level: 'L2'),
  ];

  setUp(() {
    mockApi = TestableApiClient();
    booksRepo = BooksRepository(apiClient: mockApi);
  });

  group('BookshelfBloc', () {
    test('初始状态正确（默认 L1，空列表，isLoading=false）', () {
      final bloc = BookshelfBloc(
        booksRepository: booksRepo,
        networkStatus: _dummyNetworkStream(),
      );
      expect(bloc.state.selectedLevel, 'L1');
      expect(bloc.state.books, isEmpty);
      expect(bloc.state.recommendedBooks, isEmpty);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isOffline, false);
      expect(bloc.state.errorMessage, isNull);
    });

    group('BookshelfLoadData', () {
      blocTest<BookshelfBloc, BookshelfState>(
        '成功加载 books + recommended',
        build: () {
          mockApi.mockGet('/books', _booksListResponse(testBooks));
          mockApi.mockGet('/books/recommended', _booksListResponse(testRecommendedBooks));
          return BookshelfBloc(
            booksRepository: booksRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const BookshelfLoadData()),
        expect: () => [
          isA<BookshelfState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          isA<BookshelfState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.books.length, 'books.length', 2)
              .having((s) => s.recommendedBooks.length, 'recommendedBooks.length', 1)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      blocTest<BookshelfBloc, BookshelfState>(
        'API 失败设置 errorMessage',
        build: () {
          mockApi.mockGet('/books', ApiResponse(
            code: 1001,
            data: null,
            message: '服务器错误',
          ));
          return BookshelfBloc(
            booksRepository: booksRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const BookshelfLoadData()),
        expect: () => [
          isA<BookshelfState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          isA<BookshelfState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('BookshelfRefreshData', () {
      blocTest<BookshelfBloc, BookshelfState>(
        '成功刷新',
        build: () {
          mockApi.mockGet('/books', _booksListResponse(testBooks));
          mockApi.mockGet('/books/recommended', _booksListResponse(testRecommendedBooks));
          return BookshelfBloc(
            booksRepository: booksRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const BookshelfRefreshData()),
        expect: () => [
          isA<BookshelfState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.books.length, 'books.length', 2)
              .having((s) => s.recommendedBooks.length, 'recommendedBooks.length', 1),
        ],
      );
    });

    group('BookshelfLevelChanged', () {
      blocTest<BookshelfBloc, BookshelfState>(
        '切换级别并加载新数据',
        build: () {
          mockApi.mockGet('/books', _booksListResponse(testL2Books));
          return BookshelfBloc(
            booksRepository: booksRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const BookshelfLevelChanged('L2')),
        expect: () => [
          isA<BookshelfState>()
              .having((s) => s.selectedLevel, 'selectedLevel', 'L2')
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          isA<BookshelfState>()
              .having((s) => s.selectedLevel, 'selectedLevel', 'L2')
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.books.length, 'books.length', 1),
        ],
      );

      blocTest<BookshelfBloc, BookshelfState>(
        '相同级别不触发',
        build: () => BookshelfBloc(
          booksRepository: booksRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc.add(const BookshelfLevelChanged('L1')),
        expect: () => [],
      );
    });

    group('BookshelfNetworkChanged', () {
      blocTest<BookshelfBloc, BookshelfState>(
        '更新 isOffline',
        build: () => BookshelfBloc(
          booksRepository: booksRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc.add(const BookshelfNetworkChanged(true)),
        expect: () => [
          isA<BookshelfState>().having((s) => s.isOffline, 'isOffline', true),
        ],
      );

      blocTest<BookshelfBloc, BookshelfState>(
        '恢复在线状态',
        build: () => BookshelfBloc(
          booksRepository: booksRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc
          ..add(const BookshelfNetworkChanged(true))
          ..add(const BookshelfNetworkChanged(false)),
        expect: () => [
          isA<BookshelfState>().having((s) => s.isOffline, 'isOffline', true),
          isA<BookshelfState>().having((s) => s.isOffline, 'isOffline', false),
        ],
      );
    });
  });
}
