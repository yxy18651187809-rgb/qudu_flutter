// 绘本阅读器 Repository
// 对接后端 API：GET /books/:id + POST /learning/record
import '../../core/network/api_client.dart';
import '../../core/di/service_locator.dart';

/// 绘本详情页数据模型（对应后端 BookDetail 响应）
class BookDetailModel {
  final String id;
  final String title;
  final int level;
  final String theme;
  final List<String> newWords;       // 新字ID列表
  final int newWordCount;
  final List<String> reviewWords;     // 复习字ID列表
  final List<Exercises> exercises;   // 阅读后练习
  final List<BookPage> pages;
  final List<NewWordProgress>? newWordProgress; // 有childId时返回
  final int masteredCount;

  const BookDetailModel({
    required this.id,
    required this.title,
    required this.level,
    required this.theme,
    required this.newWords,
    required this.newWordCount,
    required this.reviewWords,
    required this.exercises,
    required this.pages,
    this.newWordProgress,
    required this.masteredCount,
  });

  factory BookDetailModel.fromJson(Map<String, dynamic> json) {
    return BookDetailModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] ?? 1,
      theme: json['theme'] ?? '',
      newWords: List<String>.from(json['newWords'] ?? []),
      newWordCount: json['newWordCount'] ?? 0,
      reviewWords: List<String>.from(json['reviewWords'] ?? []),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => Exercises.fromJson(e))
              .toList() ??
          [],
      pages: (json['pages'] as List<dynamic>?)
              ?.map((e) => BookPage.fromJson(e))
              .toList() ??
          [],
      newWordProgress: (json['newWordProgress'] as List<dynamic>?)
          ?.map((e) => NewWordProgress.fromJson(e))
          .toList(),
      masteredCount: json['masteredCount'] ?? 0,
    );
  }
}

class Exercises {
  final String type;
  final String question;
  final String instruction;

  const Exercises({
    required this.type,
    required this.question,
    required this.instruction,
  });

  factory Exercises.fromJson(Map<String, dynamic> json) {
    return Exercises(
      type: json['type'] ?? '',
      question: json['question'] ?? '',
      instruction: json['instruction'] ?? '',
    );
  }
}

class BookPage {
  final String id;
  final int pageNumber;
  final String text;
  final String pinyin;
  final String image;
  final String imageDescription;
  final List<WordAnnotation> wordAnnotations;
  final String? teachingNote;

  const BookPage({
    required this.id,
    required this.pageNumber,
    required this.text,
    required this.pinyin,
    required this.image,
    required this.imageDescription,
    required this.wordAnnotations,
    this.teachingNote,
  });

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      id: json['id'] ?? '',
      pageNumber: json['pageNumber'] ?? 1,
      text: json['text'] ?? '',
      pinyin: json['pinyin'] ?? '',
      image: json['image'] ?? '',
      imageDescription: json['imageDescription'] ?? '',
      wordAnnotations: (json['wordAnnotations'] as List<dynamic>?)
              ?.map((e) => WordAnnotation.fromJson(e))
              .toList() ??
          [],
      teachingNote: json['teachingNote'],
    );
  }
}

class WordAnnotation {
  final String characterId;
  final String character;
  final bool isNewWord;
  final String highlightStyle; // underline / color / both
  // P1-002：是否为复习字
  final bool isReviewWord;

  const WordAnnotation({
    required this.characterId,
    required this.character,
    required this.isNewWord,
    required this.highlightStyle,
    this.isReviewWord = false,
  });

  factory WordAnnotation.fromJson(Map<String, dynamic> json) {
    return WordAnnotation(
      characterId: json['characterId'] ?? '',
      character: json['character'] ?? '',
      isNewWord: json['isNewWord'] ?? false,
      highlightStyle: json['highlightStyle'] ?? 'color',
      isReviewWord: json['isReviewWord'] ?? false,
    );
  }
}

class NewWordProgress {
  final String characterId;
  final bool mastered;

  const NewWordProgress({
    required this.characterId,
    required this.mastered,
  });

  factory NewWordProgress.fromJson(Map<String, dynamic> json) {
    return NewWordProgress(
      characterId: json['characterId'] ?? '',
      mastered: json['mastered'] ?? false,
    );
  }
}

/// 绘本阅读器 Repository
class BookReaderRepository {
  ApiClient get _api => ServiceLocator.instance.apiClient;

  /// 获取绘本详情（含所有页面）
  /// GET /api/v1/books/:bookId?childId=xxx
  Future<BookDetailModel?> getBookDetail(
    String bookId, {
    String? childId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (childId != null && childId.isNotEmpty) {
      queryParams['childId'] = childId;
    }

    final response = await _api.get<Map<String, dynamic>>(
      '/books/$bookId',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (!response.isSuccess || response.data == null) {
      return null;
    }
    return BookDetailModel.fromJson(response.data!);
  }

  /// 记录学习完成
  /// POST /api/v1/learning/record
  Future<bool> recordLearning({
    required String childId,
    required String bookId,
    required int pagesRead,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/learning/record',
      data: {
        'childId': childId,
        'type': 'book_complete',
        'bookId': bookId,
        'pagesRead': pagesRead,
      },
    );
    return response.isSuccess;
  }
}
