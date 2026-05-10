import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/data/models/child_model.dart';

void main() {
  group('ChildModel', () {
    final validJson = {
      'id': 'child001',
      'name': '小明',
      'avatar': 'https://example.com/avatar.png',
      'gender': 'male',
      'birthDate': '2020-05-10',
      'grade': 1,
      'currentLevel': 2,
      'knownCharacterCount': 150,
      'streakDays': 7,
      'totalStars': 42,
      'totalReadingMinutes': 320,
      'isVip': true,
      'vipExpireAt': '2026-12-31',
      'lastLearningAt': '2026-05-10T10:30:00Z',
      'createdAt': '2026-01-01T00:00:00Z',
    };

    test('fromJson 正确解析完整字段', () {
      final child = ChildModel.fromJson(validJson);
      expect(child.id, 'child001');
      expect(child.name, '小明');
      expect(child.gender, 'male');
      expect(child.birthDate, '2020-05-10');
      expect(child.grade, 1);
      expect(child.currentLevel, 2);
      expect(child.knownCharacterCount, 150);
      expect(child.streakDays, 7);
      expect(child.totalStars, 42);
      expect(child.totalReadingMinutes, 320);
      expect(child.isVip, true);
      expect(child.vipExpireAt, '2026-12-31');
    });

    test('fromJson 处理空 JSON 使用默认值', () {
      final child = ChildModel.fromJson({});
      expect(child.id, '');
      expect(child.name, '');
      expect(child.gender, 'unknown');
      expect(child.grade, 0);
      expect(child.currentLevel, 1);
      expect(child.knownCharacterCount, 0);
      expect(child.streakDays, 0);
      expect(child.isVip, false);
      expect(child.vipExpireAt, isNull);
    });

    test('fromJson 处理 null 值使用默认值', () {
      final child = ChildModel.fromJson({
        'id': null,
        'name': null,
        'gender': null,
        'grade': null,
        'knownCharacterCount': null,
      });
      expect(child.id, '');
      expect(child.name, '');
      expect(child.gender, 'unknown');
      expect(child.grade, 0);
      expect(child.knownCharacterCount, 0);
    });

    test('levelLabel 正确返回', () {
      final child = ChildModel.fromJson({'currentLevel': 3});
      expect(child.levelLabel, 'L3');
    });

    test('age 正确计算年龄', () {
      final child = ChildModel.fromJson({'birthDate': '2020-05-10'});
      // 基于当前日期计算，2020年出生 -> 大约6岁
      expect(child.age, greaterThanOrEqualTo(5));
    });

    test('空 birthDate 时 age 返回 0', () {
      final child = ChildModel.fromJson({'birthDate': ''});
      expect(child.age, 0);
    });

    test('无效 birthDate 时 age 返回 0', () {
      final child = ChildModel.fromJson({'birthDate': 'invalid'});
      expect(child.age, 0);
    });

    test('toCreateJson 输出正确字段', () {
      final child = ChildModel.fromJson(validJson);
      final json = child.toCreateJson();
      expect(json['name'], '小明');
      expect(json['gender'], 'male');
      expect(json['birthDate'], '2020-05-10');
      expect(json['grade'], 1);
      // 不应包含 id/vip 等字段
      expect(json.containsKey('id'), false);
      expect(json.containsKey('isVip'), false);
    });

    test('toUpdateJson 包含非空 avatar 和 name', () {
      final child = ChildModel.fromJson(validJson);
      final json = child.toUpdateJson();
      expect(json['name'], '小明');
      expect(json['avatar'], 'https://example.com/avatar.png');
    });

    test('toUpdateJson 不包含空字符串', () {
      final child = ChildModel.fromJson({'name': '', 'avatar': ''});
      final json = child.toUpdateJson();
      // 空字符串 name/avatar 不应出现
      expect(json.containsKey('name'), false);
      expect(json.containsKey('avatar'), false);
      // grade 始终包含
      expect(json['grade'], 0);
    });
  });
}
