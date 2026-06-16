// 绘本阅读器核心测试
// 验证：数据模型 → URL 解析 → 阅读器渲染 → 翻页
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/utils/image_url_resolver.dart';
import 'package:ziqu_reading/data/repositories/book_reader_repository.dart';
import 'package:ziqu_reading/presentation/pages/book_reader/book_reader_page.dart';

// ===================================================================
// Mock Repository（extends 而非 implements，简化实现）
// ===================================================================
class _MockRepo extends BookReaderRepository {
  final BookDetailModel? detail;
  final Exception? error;

  _MockRepo({this.detail, this.error});

  @override
  Future<BookDetailModel?> getBookDetail(String bookId, {String? childId}) async {
    if (error != null) throw error!;
    return detail;
  }

  @override
  Future<bool> recordLearning({
    required String childId,
    required String bookId,
    required int pagesRead,
  }) async {
    return true;
  }
}

// ===================================================================
// 测试数据
// ===================================================================
BookDetailModel _detail({int pages = 3}) {
  final list = <BookPage>[];
  for (int i = 0; i < pages; i++) {
    list.add(BookPage(
      id: 'p${i + 1}',
      pageNumber: i + 1,
      text: '第${i + 1}页测试文字',
      pinyin: '[dì ${i + 1} yè]',
      image: '/uploads/test_p0${i + 1}.png',
      imageDescription: '插画${i + 1}',
      wordAnnotations: [
        WordAnnotation(
          characterId: 'c1',
          character: '字${i + 1}',
          isNewWord: true,
          highlightStyle: 'both',
        ),
      ],
    ));
  }
  return BookDetailModel(
    id: 'book_001',
    title: '测试绘本',
    level: 1,
    theme: '测试',
    newWords: ['c1'],
    newWordCount: 1,
    reviewWords: [],
    exercises: [],
    pages: list,
    masteredCount: 0,
  );
}

// ===================================================================
// Unit Tests
// ===================================================================
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageUrlResolver', () {
    test('相对路径拼接服务器地址', () {
      expect(
        ImageUrlResolver.resolve('/uploads/pages/01_P01.png'),
        contains('localhost:3001/uploads/pages/01_P01.png'),
      );
    });

    test('完整URL直接返回', () {
      expect(
        ImageUrlResolver.resolve('https://cdn.example.com/img.png'),
        'https://cdn.example.com/img.png',
      );
    });
  });

  group('BookDetailModel 数据解析', () {
    test('fromJson 正确构造 BookDetailModel', () {
      final json = {
        'id': 'book_test',
        'title': '我的身体',
        'level': 1,
        'theme': '身体认知',
        'newWords': ['c1', 'c2'],
        'newWordCount': 2,
        'reviewWords': ['c3'],
        'exercises': [],
        'pages': [
          {
            'id': 'p1',
            'pageNumber': 1,
            'text': '我是小明',
            'pinyin': '[wǒ shì xiǎo míng]',
            'image': '/uploads/p1.png',
            'imageDescription': '封面',
            'wordAnnotations': [
              {
                'characterId': 'c1',
                'character': '我',
                'isNewWord': true,
                'highlightStyle': 'both',
              },
            ],
          },
        ],
        'masteredCount': 5,
      };

      final model = BookDetailModel.fromJson(json);
      expect(model.id, 'book_test');
      expect(model.title, '我的身体');
      expect(model.newWordCount, 2);
      expect(model.pages.length, 1);
      expect(model.pages.first.text, '我是小明');
      expect(model.masteredCount, 5);
    });
  });

  group('BookReaderPage Widget', () {
    testWidgets('加载时显示进度指示器', (tester) async {
      final repo = _MockRepo(detail: _detail());
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      // 初始状态应显示加载中的 CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('加载失败显示错误界面', (tester) async {
      final repo = _MockRepo(error: Exception('网络异常'));
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('加载失败'), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
    });

    testWidgets('加载成功显示阅读器内容', (tester) async {
      final repo = _MockRepo(detail: _detail());
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      await tester.pumpAndSettle();
      // 书名显示
      expect(find.text('测试绘本'), findsOneWidget);
      // 页码显示（1/3）
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('PageView 滑动翻页正常', (tester) async {
      final repo = _MockRepo(detail: _detail());
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);

      // 滑动到第2页
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('空页面数据展示空状态', (tester) async {
      final repo = _MockRepo(detail: _detail()..pages.clear());
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂无绘本内容'), findsOneWidget);
      expect(find.text('返回书架'), findsOneWidget);
    });

    testWidgets('到达最后一页显示完成阅读按钮', (tester) async {
      final repo = _MockRepo(detail: _detail(pages: 2));
      await tester.pumpWidget(
        MaterialApp(home: BookReaderPage(bookId: 'book_001', repository: repo)),
      );
      await tester.pumpAndSettle();
      // 滑动到最后一页
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('完成阅读'), findsOneWidget);
    });
  });
}
