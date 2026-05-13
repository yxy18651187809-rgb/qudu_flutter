import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/data/repositories/books_repository.dart';

import 'auth_repository_test.dart' show MockApiClient;

void main() {
  late MockApiClient mockApi;
  late BooksRepository booksRepo;

  setUp(() {
    mockApi = MockApiClient();
    booksRepo = BooksRepository(apiClient: mockApi);
  });

  group('BooksRepository', () {
    group('getBooks', () {
      test('成功获取绘本列表', () async {
        mockApi.whenGet('/books', ApiResponse(
          code: 0,
          data: {
            'list': [
              {
                'id': 'L1_book_01',
                'title': '我的身体',
                'cover': '/uploads/covers/book_cover_01.png',
                'level': 'L1',
                'newWords': ['我', '的', '身', '体'],
                'totalPages': 11,
                'readCount': 3,
              },
              {
                'id': 'L1_book_02',
                'title': '早上好',
                'cover': '/uploads/covers/book_cover_02.png',
                'level': 'L1',
                'newWords': ['早', '上', '好'],
                'totalPages': 11,
                'readCount': 0,
              },
            ],
          },
          message: 'ok',
        ));

        final result = await booksRepo.getBooks(level: 'L1');
        expect(result.length, 2);
        expect(result[0].id, 'L1_book_01');
        expect(result[0].title, '我的身体');
        expect(result[1].title, '早上好');
      });

      test('空列表返回空List', () async {
        mockApi.whenGet('/books', ApiResponse(
          code: 0,
          data: {'list': []},
          message: 'ok',
        ));

        final result = await booksRepo.getBooks();
        expect(result, isEmpty);
      });

      test('API失败抛出 ApiException', () async {
        mockApi.whenGet('/books', ApiResponse(
          code: 500,
          data: null,
          message: '服务器错误',
        ));

        expect(
          () => booksRepo.getBooks(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getBookDetail', () {
      test('成功获取绘本详情', () async {
        mockApi.whenGet('/books/L1_book_01', ApiResponse(
          code: 0,
          data: {
            'id': 'L1_book_01',
            'title': '我的身体',
            'cover': '/uploads/covers/book_cover_01.png',
            'level': 'L1',
            'newWords': ['我', '的', '身', '体'],
            'totalPages': 11,
            'readCount': 5,
            'isCompleted': true,
          },
          message: 'ok',
        ));

        final result = await booksRepo.getBookDetail('L1_book_01');
        expect(result, isNotNull);
        expect(result!.id, 'L1_book_01');
        expect(result.title, '我的身体');
        expect(result.isCompleted, true);
      });

      test('绘本不存在返回null', () async {
        mockApi.whenGet('/books/nonexistent', ApiResponse(
          code: 404,
          data: null,
          message: '绘本不存在',
        ));

        final result = await booksRepo.getBookDetail('nonexistent');
        expect(result, isNull);
      });

      test('带childId参数获取绘本详情', () async {
        mockApi.whenGet('/books/L1_book_01', ApiResponse(
          code: 0,
          data: {
            'id': 'L1_book_01',
            'title': '我的身体',
            'cover': '/uploads/covers/book_cover_01.png',
            'level': 'L1',
            'newWords': ['我', '的', '身', '体'],
            'totalPages': 11,
            'readCount': 2,
          },
          message: 'ok',
        ));

        final result = await booksRepo.getBookDetail(
          'L1_book_01',
          childId: 'child001',
        );
        expect(result, isNotNull);
        expect(result!.id, 'L1_book_01');
      });
    });

    group('getRecommendedBooks', () {
      test('成功获取推荐绘本列表', () async {
        mockApi.whenGet('/books/recommended', ApiResponse(
          code: 0,
          data: {
            'list': [
              {
                'id': 'L1_book_03',
                'title': '小兔子找妈妈',
                'cover': '/uploads/covers/book_cover_03.png',
                'level': 'L1',
                'newWords': ['小', '兔', '子'],
                'totalPages': 11,
              },
            ],
          },
          message: 'ok',
        ));

        final result = await booksRepo.getRecommendedBooks(childId: 'child001');
        expect(result.length, 1);
        expect(result[0].title, '小兔子找妈妈');
      });

      test('无推荐返回空List', () async {
        mockApi.whenGet('/books/recommended', ApiResponse(
          code: 0,
          data: null,
          message: 'ok',
        ));

        final result = await booksRepo.getRecommendedBooks();
        expect(result, isEmpty);
      });
    });

    group('getFreeBooks', () {
      test('成功获取免费绘本', () async {
        mockApi.whenGet('/books/free', ApiResponse(
          code: 0,
          data: {
            'list': [
              {
                'id': 'L1_book_01',
                'title': '我的身体',
                'cover': '/uploads/covers/book_cover_01.png',
                'level': 'L1',
                'newWords': ['我', '的', '身', '体'],
                'totalPages': 11,
              },
            ],
          },
          message: 'ok',
        ));

        final result = await booksRepo.getFreeBooks();
        expect(result.length, 1);
      });

      test('无免费绘本返回空List', () async {
        mockApi.whenGet('/books/free', ApiResponse(
          code: 0,
          data: {'list': []},
          message: 'ok',
        ));

        final result = await booksRepo.getFreeBooks();
        expect(result, isEmpty);
      });
    });

    group('getThemes', () {
      test('成功获取主题列表', () async {
        mockApi.whenGet('/books/themes', ApiResponse(
          code: 0,
          data: {
            'list': ['自然与动物', '生活与社交', '认知与启蒙'],
          },
          message: 'ok',
        ));

        final result = await booksRepo.getThemes();
        expect(result.length, 3);
        expect(result[0], '自然与动物');
        expect(result[2], '认知与启蒙');
      });

      test('无主题返回空List', () async {
        mockApi.whenGet('/books/themes', ApiResponse(
          code: 500,
          data: null,
          message: '服务器错误',
        ));

        final result = await booksRepo.getThemes();
        expect(result, isEmpty);
      });
    });
  });
}
