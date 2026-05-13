import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/data/models/child_model.dart';
import 'package:ziqu_reading/data/repositories/children_repository.dart';

import 'auth_repository_test.dart' show MockApiClient;

void main() {
  late MockApiClient mockApi;
  late ChildrenRepository childrenRepo;

  setUp(() {
    mockApi = MockApiClient();
    childrenRepo = ChildrenRepository(apiClient: mockApi);
  });

  group('ChildrenRepository', () {
    group('getChildren', () {
      test('成功获取儿童列表', () async {
        mockApi.whenGet('/children', ApiResponse(
          code: 0,
          data: {
            'list': [
              {
                'id': 'child001',
                'name': '小明',
                'gender': 'male',
                'birthDate': '2020-05-10',
                'grade': 1,
                'currentLevel': 2,
                'knownCharacterCount': 150,
                'streakDays': 7,
                'totalStars': 42,
                'totalReadingMinutes': 320,
              },
              {
                'id': 'child002',
                'name': '小红',
                'gender': 'female',
                'birthDate': '2021-03-15',
                'grade': 0,
                'currentLevel': 1,
                'knownCharacterCount': 30,
                'streakDays': 3,
                'totalStars': 15,
                'totalReadingMinutes': 80,
              },
            ],
          },
          message: 'ok',
        ));

        final result = await childrenRepo.getChildren();
        expect(result.length, 2);
        expect(result[0].id, 'child001');
        expect(result[0].name, '小明');
        expect(result[1].name, '小红');
        expect(result[1].gender, 'female');
      });

      test('空列表时返回空List', () async {
        mockApi.whenGet('/children', ApiResponse(
          code: 0,
          data: {'list': []},
          message: 'ok',
        ));

        final result = await childrenRepo.getChildren();
        expect(result, isEmpty);
      });

      test('API返回非0时抛出 ApiException', () async {
        mockApi.whenGet('/children', ApiResponse(
          code: 401,
          data: null,
          message: '未授权',
        ));

        expect(
          () => childrenRepo.getChildren(),
          throwsA(isA<ApiException>()),
        );
      });

      test('data为null时抛出 ApiException', () async {
        mockApi.whenGet('/children', ApiResponse(
          code: 0,
          data: null,
          message: 'ok',
        ));

        expect(
          () => childrenRepo.getChildren(),
          throwsA(isA<ApiException>()),
        );
      });

      test('list字段缺失时返回空List', () async {
        mockApi.whenGet('/children', ApiResponse(
          code: 0,
          data: <String, dynamic>{},
          message: 'ok',
        ));

        // data非null但没有list字段
        final result = await childrenRepo.getChildren();
        expect(result, isEmpty);
      });
    });

    group('createChild', () {
      test('成功创建儿童档案', () async {
        mockApi.whenPost('/children', ApiResponse(
          code: 0,
          data: {
            'id': 'child_new',
            'name': '小刚',
            'gender': 'male',
            'birthDate': '2019-08-20',
            'grade': 2,
            'currentLevel': 3,
            'knownCharacterCount': 0,
            'streakDays': 0,
            'totalStars': 0,
            'totalReadingMinutes': 0,
          },
          message: 'ok',
        ));

        final child = ChildModel.fromJson({
          'name': '小刚',
          'gender': 'male',
          'birthDate': '2019-08-20',
          'grade': 2,
        });
        final result = await childrenRepo.createChild(child);
        expect(result.id, 'child_new');
        expect(result.name, '小刚');
      });

      test('创建失败抛出 ApiException', () async {
        mockApi.whenPost('/children', ApiResponse(
          code: 2001,
          data: null,
          message: '已达到儿童档案上限',
        ));

        final child = ChildModel.fromJson({'name': '小刚', 'gender': 'male'});
        expect(
          () => childrenRepo.createChild(child),
          throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', '已达到儿童档案上限',
          )),
        );
      });
    });

    group('getChildDetail', () {
      test('成功获取儿童详情', () async {
        mockApi.whenGet('/children/child001', ApiResponse(
          code: 0,
          data: {
            'id': 'child001',
            'name': '小明',
            'gender': 'male',
            'birthDate': '2020-05-10',
            'grade': 1,
            'currentLevel': 2,
            'knownCharacterCount': 150,
            'streakDays': 7,
            'totalStars': 42,
            'totalReadingMinutes': 320,
          },
          message: 'ok',
        ));

        final result = await childrenRepo.getChildDetail('child001');
        expect(result.id, 'child001');
        expect(result.name, '小明');
        expect(result.knownCharacterCount, 150);
      });

      test('儿童不存在时抛出 ApiException', () async {
        mockApi.whenGet('/children/nonexistent', ApiResponse(
          code: 2002,
          data: null,
          message: '儿童档案不存在',
        ));

        expect(
          () => childrenRepo.getChildDetail('nonexistent'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('updateChild', () {
      test('成功更新儿童档案', () async {
        mockApi.whenPut('/children/child001', ApiResponse(
          code: 0,
          data: {
            'id': 'child001',
            'name': '小明更新',
            'gender': 'male',
            'birthDate': '2020-05-10',
            'grade': 2,
            'currentLevel': 3,
            'knownCharacterCount': 200,
            'streakDays': 14,
            'totalStars': 80,
            'totalReadingMinutes': 500,
          },
          message: 'ok',
        ));

        final child = ChildModel.fromJson({
          'id': 'child001',
          'name': '小明更新',
          'gender': 'male',
          'grade': 2,
        });
        final result = await childrenRepo.updateChild(child);
        expect(result.name, '小明更新');
        expect(result.grade, 2);
      });

      test('更新失败抛出 ApiException', () async {
        mockApi.whenPut('/children/child001', ApiResponse(
          code: 2003,
          data: null,
          message: '更新失败',
        ));

        final child = ChildModel.fromJson({
          'id': 'child001',
          'name': '小明',
        });
        expect(
          () => childrenRepo.updateChild(child),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('deleteChild', () {
      test('成功删除儿童档案', () async {
        mockApi.whenDelete('/children/child001', ApiResponse(
          code: 0,
          data: null,
          message: 'ok',
        ));

        // 应不抛异常
        await childrenRepo.deleteChild('child001');
      });

      test('删除失败抛出 ApiException', () async {
        mockApi.whenDelete('/children/nonexistent', ApiResponse(
          code: 2002,
          data: null,
          message: '儿童档案不存在',
        ));

        expect(
          () => childrenRepo.deleteChild('nonexistent'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
