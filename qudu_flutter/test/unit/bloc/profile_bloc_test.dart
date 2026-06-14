import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/core/network/network_interceptor.dart';
import 'package:ziqu_reading/data/models/child_model.dart';
import 'package:ziqu_reading/data/repositories/children_repository.dart';
import 'package:ziqu_reading/presentation/bloc/profile/profile_bloc.dart';
import 'package:ziqu_reading/presentation/bloc/profile/profile_event.dart';
import 'package:ziqu_reading/presentation/bloc/profile/profile_state.dart';

import '../repositories/auth_repository_test.dart';

/// 构建测试用 ChildModel
ChildModel _buildTestChild({
  String id = 'child1',
  String name = '小明',
  int currentLevel = 1,
}) {
  return ChildModel(
    id: id,
    name: name,
    avatar: '',
    gender: 'unknown',
    birthDate: '2020-01-01',
    grade: 0,
    currentLevel: currentLevel,
    knownCharacterCount: 20,
    streakDays: 5,
    totalStars: 100,
    totalReadingMinutes: 60,
    isVip: false,
  );
}

/// 构建儿童列表 API 响应
ApiResponse<Map<String, dynamic>> _childrenListResponse(
    List<ChildModel> children) {
  return ApiResponse(
    code: 0,
    data: {
      'list': children
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'avatar': c.avatar,
                'gender': c.gender,
                'birthDate': c.birthDate,
                'grade': c.grade,
                'currentLevel': c.currentLevel,
                'knownCharacterCount': c.knownCharacterCount,
                'streakDays': c.streakDays,
                'totalStars': c.totalStars,
                'totalReadingMinutes': c.totalReadingMinutes,
                'isVip': c.isVip,
              })
          .toList(),
    },
    message: 'ok',
  );
}

/// 空的 NetworkStatus 流
Stream<NetworkStatus> _dummyNetworkStream() => const Stream.empty();

void main() {
  late TestableApiClient mockApi;
  late ChildrenRepository childrenRepo;

  final testChildren = [
    _buildTestChild(id: 'c1', name: '小明'),
    _buildTestChild(id: 'c2', name: '小红', currentLevel: 2),
  ];

  setUp(() {
    mockApi = TestableApiClient();
    childrenRepo = ChildrenRepository(apiClient: mockApi);
  });

  group('ProfileBloc', () {
    test('初始状态正确（空列表）', () {
      final bloc = ProfileBloc(
        childrenRepository: childrenRepo,
        networkStatus: _dummyNetworkStream(),
      );
      expect(bloc.state.children, isEmpty);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isOffline, false);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.parentId, isNull);
    });

    test('便捷 getter', () {
      final bloc = ProfileBloc(
        childrenRepository: childrenRepo,
        networkStatus: _dummyNetworkStream(),
      );
      expect(bloc.state.hasChildren, false);
      expect(bloc.state.displayName, '字趣阅读');
      expect(bloc.state.childCount, 0);
    });

    group('ProfileLoadData', () {
      blocTest<ProfileBloc, ProfileState>(
        '成功加载儿童列表',
        build: () {
          mockApi.mockGet('/children', _childrenListResponse(testChildren));
          return ProfileBloc(
            childrenRepository: childrenRepo,
            networkStatus: _dummyNetworkStream(),
            parentId: 'test_parent',
          );
        },
        act: (bloc) => bloc.add(const ProfileLoadData()),
        verify: (bloc) {
          final state = bloc.state;
          expect(state.isLoading, false);
          expect(state.children.length, 2);
          expect(state.errorMessage, isNull);
          expect(state.hasChildren, true);
          expect(state.displayName, '小明的账号');
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'API 失败设置 errorMessage',
        build: () {
          mockApi.mockGet(
            '/children',
            ApiResponse(code: 500, data: null, message: '服务器错误'),
          );
          return ProfileBloc(
            childrenRepository: childrenRepo,
            networkStatus: _dummyNetworkStream(),
            parentId: 'test_parent',
          );
        },
        act: (bloc) => bloc.add(const ProfileLoadData()),
        verify: (bloc) {
          expect(bloc.state.isLoading, false);
          expect(bloc.state.errorMessage, isNotNull);
        },
      );
    });

    group('ProfileRefreshData', () {
      blocTest<ProfileBloc, ProfileState>(
        '刷新成功更新列表',
        build: () {
          mockApi.mockGet('/children', _childrenListResponse(testChildren));
          return ProfileBloc(
            childrenRepository: childrenRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const ProfileRefreshData()),
        verify: (bloc) {
          expect(bloc.state.children.length, 2);
          expect(bloc.state.errorMessage, isNull);
        },
      );
    });

    group('ProfileNetworkChanged', () {
      blocTest<ProfileBloc, ProfileState>(
        '更新 isOffline',
        build: () => ProfileBloc(
          childrenRepository: childrenRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc.add(const ProfileNetworkChanged(true)),
        expect: () => [
          predicate<ProfileState>((s) => s.isOffline == true),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        '恢复在线状态',
        build: () => ProfileBloc(
          childrenRepository: childrenRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc
          ..add(const ProfileNetworkChanged(true))
          ..add(const ProfileNetworkChanged(false)),
        expect: () => [
          predicate<ProfileState>((s) => s.isOffline == true),
          predicate<ProfileState>((s) => s.isOffline == false),
        ],
      );
    });
  });
}
