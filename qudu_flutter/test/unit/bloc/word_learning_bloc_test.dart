import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/core/network/api_response.dart';
import 'package:ziqu_reading/core/network/network_interceptor.dart';
import 'package:ziqu_reading/data/models/character_model.dart';
import 'package:ziqu_reading/data/repositories/character_repository.dart';
import 'package:ziqu_reading/presentation/bloc/word_learning/word_learning_bloc.dart';
import 'package:ziqu_reading/presentation/bloc/word_learning/word_learning_event.dart';
import 'package:ziqu_reading/presentation/bloc/word_learning/word_learning_state.dart';

import '../repositories/auth_repository_test.dart';

/// 构建测试用 CharacterModel
CharacterModel _buildTestChar({
  String id = 'c1',
  String character = '大',
  String pinyin = 'dà',
  int level = 1,
  double mastery = 0.0,
}) {
  return CharacterModel(
    id: id,
    character: character,
    pinyin: pinyin,
    radical: '大',
    strokeCount: 3,
    structure: '独体',
    coreLevel: 'core',
    level: level,
    words: ['大人', '大小'],
    sentences: [],
    mastery: mastery,
    isReview: false,
  );
}

/// 构建字卡列表 API 响应
ApiResponse<Map<String, dynamic>> _charactersListResponse(
    List<CharacterModel> chars) {
  return ApiResponse(
    code: 0,
    data: {
      'list': chars
          .map((c) => {
                'id': c.id,
                'character': c.character,
                'pinyin': c.pinyin,
                'radical': c.radical,
                'strokeCount': c.strokeCount,
                'structure': c.structure,
                'coreLevel': c.coreLevel,
                'level': c.level,
                'words': c.words,
                'sentences': c.sentences,
                'mastery': c.mastery,
                'isReview': c.isReview,
                'audioUrl': '',
              })
          .toList(),
    },
    message: 'ok',
  );
}

/// 构建学习统计 API 响应
ApiResponse<Map<String, dynamic>> _statsResponse({
  int totalWords = 47,
  int masteredWords = 20,
  int dueReview = 5,
  int streakDays = 3,
  int totalReadingMinutes = 120,
}) {
  return ApiResponse(
    code: 0,
    data: {
      'totalWords': totalWords,
      'masteredWords': masteredWords,
      'dueReview': dueReview,
      'streakDays': streakDays,
      'totalReadingMinutes': totalReadingMinutes,
    },
    message: 'ok',
  );
}

/// 空的 NetworkStatus 流（测试用）
Stream<NetworkStatus> _dummyNetworkStream() => const Stream.empty();

void main() {
  late TestableApiClient mockApi;
  late CharacterRepository charRepo;

  final testChars = [
    _buildTestChar(id: 'c1', character: '大', pinyin: 'dà'),
    _buildTestChar(id: 'c2', character: '小', pinyin: 'xiǎo'),
    _buildTestChar(id: 'c3', character: '人', pinyin: 'rén'),
  ];

  setUp(() {
    mockApi = TestableApiClient();
    charRepo = CharacterRepository(apiClient: mockApi);
  });

  group('WordLearningBloc', () {
    test('初始状态正确（L1，空列表）', () {
      final bloc = WordLearningBloc(
        characterRepository: charRepo,
        networkStatus: _dummyNetworkStream(),
      );
      expect(bloc.state.selectedLevel, 1);
      expect(bloc.state.characters, isEmpty);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isOffline, false);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.reviewCount, 0);
    });

    test('支持初始级别注入', () {
      final bloc = WordLearningBloc(
        characterRepository: charRepo,
        networkStatus: _dummyNetworkStream(),
        initialLevel: 3,
      );
      expect(bloc.state.selectedLevel, 3);
    });

    test('便捷 getter', () {
      final bloc = WordLearningBloc(
        characterRepository: charRepo,
        networkStatus: _dummyNetworkStream(),
      );
      expect(bloc.state.levelLabel, 'L1');
      expect(bloc.state.characterCount, 0);
      expect(bloc.state.hasReview, false);
    });

    group('WordLearningLoadData', () {
      blocTest<WordLearningBloc, WordLearningState>(
        '成功加载字卡列表 + 学习统计',
        build: () {
          mockApi.mockGet('/characters', _charactersListResponse(testChars));
          mockApi.mockGet(
            '/learning/stats/child1',
            _statsResponse(dueReview: 5),
          );
          return WordLearningBloc(
            characterRepository: charRepo,
            networkStatus: _dummyNetworkStream(),
            initialChildId: 'child1',
          );
        },
        act: (bloc) => bloc.add(const WordLearningLoadData()),
        expect: () => [
          // _loadCharacters 先 emit isLoading: true，再 emit 结果
          predicate<WordLearningState>((s) => s.isLoading == true),
          predicate<WordLearningState>(
            (s) =>
                s.isLoading == false &&
                s.characters.length == 3 &&
                s.reviewCount == 5 &&
                s.errorMessage == null,
          ),
        ],
      );

      blocTest<WordLearningBloc, WordLearningState>(
        'API 失败设置 errorMessage',
        build: () {
          mockApi.mockGet(
            '/characters',
            ApiResponse(code: 500, data: null, message: '服务器错误'),
          );
          return WordLearningBloc(
            characterRepository: charRepo,
            networkStatus: _dummyNetworkStream(),
            initialChildId: 'child1',
          );
        },
        act: (bloc) => bloc.add(const WordLearningLoadData()),
        expect: () => [
          predicate<WordLearningState>((s) => s.isLoading == true),
          predicate<WordLearningState>(
            (s) => s.isLoading == false && s.errorMessage != null,
          ),
        ],
      );
    });

    group('WordLearningLevelChanged', () {
      blocTest<WordLearningBloc, WordLearningState>(
        '切换级别并加载新数据',
        build: () {
          mockApi.mockGet('/characters', _charactersListResponse([
            _buildTestChar(id: 'c4', character: '天', level: 2),
          ]));
          return WordLearningBloc(
            characterRepository: charRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const WordLearningLevelChanged(2)),
        expect: () => [
          predicate<WordLearningState>(
            (s) => s.selectedLevel == 2 && s.isLoading == true,
          ),
          predicate<WordLearningState>(
            (s) =>
                s.selectedLevel == 2 &&
                s.isLoading == false &&
                s.characters.length == 1,
          ),
        ],
      );

      blocTest<WordLearningBloc, WordLearningState>(
        '相同级别不触发',
        build: () => WordLearningBloc(
          characterRepository: charRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc.add(const WordLearningLevelChanged(1)),
        expect: () => [],
      );
    });

    group('WordLearningNetworkChanged', () {
      blocTest<WordLearningBloc, WordLearningState>(
        '更新 isOffline',
        build: () => WordLearningBloc(
          characterRepository: charRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc.add(const WordLearningNetworkChanged(true)),
        expect: () => [
          predicate<WordLearningState>((s) => s.isOffline == true),
        ],
      );

      blocTest<WordLearningBloc, WordLearningState>(
        '恢复在线状态',
        build: () => WordLearningBloc(
          characterRepository: charRepo,
          networkStatus: _dummyNetworkStream(),
        ),
        act: (bloc) => bloc
          ..add(const WordLearningNetworkChanged(true))
          ..add(const WordLearningNetworkChanged(false)),
        expect: () => [
          predicate<WordLearningState>((s) => s.isOffline == true),
          predicate<WordLearningState>((s) => s.isOffline == false),
        ],
      );
    });

    group('WordLearningRefreshData', () {
      blocTest<WordLearningBloc, WordLearningState>(
        '刷新成功更新字卡列表',
        build: () {
          mockApi.mockGet('/characters', _charactersListResponse(testChars));
          return WordLearningBloc(
            characterRepository: charRepo,
            networkStatus: _dummyNetworkStream(),
          );
        },
        act: (bloc) => bloc.add(const WordLearningRefreshData()),
        expect: () => [
          predicate<WordLearningState>((s) => s.isLoading == true),
          predicate<WordLearningState>(
            (s) => s.isLoading == false && s.characters.length == 3,
          ),
        ],
      );
    });
  });
}
