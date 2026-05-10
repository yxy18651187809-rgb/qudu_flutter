import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/data/models/book_model.dart';

void main() {
  group('BookModel', () {
    final validJson = {
      'id': 'book001',
      'title': '我的身体',
      'cover': '/uploads/covers/book_cover_01.png',
      'level': 'L1',
      'newWords': ['我', '的', '身', '体'],
      'totalPages': 11,
      'readCount': 3,
      'isCompleted': true,
      'lastReadAt': '2026-05-10T10:30:00Z',
    };

    test('fromJson 正确解析完整字段', () {
      final book = BookModel.fromJson(validJson);
      expect(book.id, 'book001');
      expect(book.title, '我的身体');
      expect(book.cover, '/uploads/covers/book_cover_01.png');
      expect(book.level, 'L1');
      expect(book.newWords, ['我', '的', '身', '体']);
      expect(book.totalPages, 11);
      expect(book.readCount, 3);
      expect(book.isCompleted, true);
      expect(book.lastReadAt, isNotNull);
    });

    test('fromJson 处理空 JSON 使用默认值', () {
      final book = BookModel.fromJson({});
      expect(book.id, '');
      expect(book.title, '');
      expect(book.cover, '');
      expect(book.level, 'L1');
      expect(book.newWords, isEmpty);
      expect(book.totalPages, 0);
      expect(book.readCount, 0);
      expect(book.isCompleted, false);
      expect(book.lastReadAt, isNull);
    });

    test('fromJson 兼容 _id 字段', () {
      final book = BookModel.fromJson({'_id': 'mongoId001'});
      expect(book.id, 'mongoId001');
    });

    test('fromJson 优先使用 id 而非 _id', () {
      final book = BookModel.fromJson({
        'id': 'preferId',
        '_id': 'mongoId',
      });
      expect(book.id, 'preferId');
    });

    test('toJson 序列化正确', () {
      final book = BookModel.fromJson(validJson);
      final json = book.toJson();
      expect(json['id'], 'book001');
      expect(json['title'], '我的身体');
      expect(json['level'], 'L1');
      expect(json['newWords'], ['我', '的', '身', '体']);
      expect(json['readCount'], 3);
      expect(json['isCompleted'], true);
    });

    test('masteryProgress 从未读过时为0', () {
      final book = BookModel.fromJson({
        'totalPages': 10,
        'readCount': 0,
      });
      expect(book.masteryProgress, 0.0);
    });

    test('masteryProgress 读了总页数×2次达到1.0', () {
      final book = BookModel.fromJson({
        'totalPages': 10,
        'readCount': 20,
      });
      expect(book.masteryProgress, 1.0);
    });

    test('masteryProgress 不超过1.0', () {
      final book = BookModel.fromJson({
        'totalPages': 5,
        'readCount': 100,
      });
      expect(book.masteryProgress, 1.0);
    });

    test('masteryProgress 半掌握', () {
      final book = BookModel.fromJson({
        'totalPages': 10,
        'readCount': 10,
      });
      expect(book.masteryProgress, 0.5);
    });

    test('levelLabel 各级别正确返回', () {
      expect(BookModel.fromJson({'level': 'L1'}).levelLabel, '⭐ 启蒙');
      expect(BookModel.fromJson({'level': 'L2'}).levelLabel, '⭐⭐ 基础');
      expect(BookModel.fromJson({'level': 'L3'}).levelLabel, '⭐⭐⭐ 进阶');
      expect(BookModel.fromJson({'level': 'L4'}).levelLabel, '⭐⭐⭐⭐ 提升');
      expect(BookModel.fromJson({'level': 'L5'}).levelLabel, '⭐⭐⭐⭐⭐ 挑战');
    });

    test('levelLabel 未知级别返回原值', () {
      final book = BookModel.fromJson({'level': 'unknown'});
      expect(book.levelLabel, 'unknown');
    });

    test('lastReadAt 为 null 时正确解析', () {
      final book = BookModel.fromJson({'lastReadAt': null});
      expect(book.lastReadAt, isNull);
    });

    test('无效 lastReadAt 格式时返回 null', () {
      final book = BookModel.fromJson({'lastReadAt': 'not-a-date'});
      expect(book.lastReadAt, isNull);
    });
  });
}
