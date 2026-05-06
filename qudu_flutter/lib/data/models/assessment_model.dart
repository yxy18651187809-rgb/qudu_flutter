/// 测评数据模型
/// 对应后端 Assessment 模型（Assessment.js）
/// 字段与 API 契约文档 v1.2 第七章一致

// 题型枚举
enum QuestionType {
  recognize('recognize', '看字选图'),
  pinyinMatch('pinyin_match', '听音选字'),
  meaningSelect('meaning_select', '看图选字');

  final String apiValue;
  final String displayName;
  const QuestionType(this.apiValue, this.displayName);

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => QuestionType.recognize,
    );
  }
}

// 测评类型枚举
enum AssessmentType {
  initial('initial', '初始测评'),
  review('review', '绘本测评'),
  levelTest('level_test', '级别测评');

  final String apiValue;
  final String displayName;
  const AssessmentType(this.apiValue, this.displayName);

  static AssessmentType fromString(String value) {
    return AssessmentType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => AssessmentType.initial,
    );
  }
}

// 测评状态枚举
enum AssessmentStatus {
  inProgress('in_progress', '进行中'),
  completed('completed', '已完成'),
  abandoned('abandoned', '已放弃');

  final String apiValue;
  final String displayName;
  const AssessmentStatus(this.apiValue, this.displayName);

  static AssessmentStatus fromString(String value) {
    return AssessmentStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => AssessmentStatus.inProgress,
    );
  }
}

/// 测评题目选项模型
class AssessmentOption {
  final String key; // 选项键：A/B/C/D
  final String content; // 选项内容：图片URL或文本
  final String label; // 选项标签：用于语音播报或提示

  AssessmentOption({
    required this.key,
    required this.content,
    required this.label,
  });

  factory AssessmentOption.fromJson(Map<String, dynamic> json) {
    return AssessmentOption(
      key: json['key'] ?? '',
      content: json['content'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

/// 测评题目模型
class AssessmentQuestion {
  final String characterId;
  final String character;
  final QuestionType questionType;
  final List<AssessmentOption> options; // 修改为Option对象数组
  final String? correctAnswer; // 正确答案，由后端返回
  final String? audioUrl; // 音频URL，由后端返回
  final String? imageUrl; // 题目图片URL，用于meaningSelect题型
  /// 是否为复习字题目（P1-002）
  final bool isReview;
  // 前端本地状态，非API返回
  String? userAnswer;
  bool? isCorrect;
  int? responseTime;

  AssessmentQuestion({
    required this.characterId,
    required this.character,
    required this.questionType,
    required this.options,
    this.correctAnswer,
    this.audioUrl,
    this.imageUrl,
    this.isReview = false,
    this.userAnswer,
    this.isCorrect,
    this.responseTime,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    // 解析options：后端可能返回字符串数组或对象数组
    List<AssessmentOption> parseOptions(dynamic optionsData) {
      if (optionsData == null || optionsData is! List) return [];
      
      final keys = ['A', 'B', 'C', 'D'];
      return optionsData.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final key = index < keys.length ? keys[index] : String.fromCharCode(65 + index);
        
        if (value is String) {
          // 后端返回字符串数组，自动转换为Option对象
          return AssessmentOption(
            key: key,
            content: value,
            label: value,
          );
        } else if (value is Map<String, dynamic>) {
          // 后端返回对象数组（标准格式）
          return AssessmentOption.fromJson(value);
        } else {
          return AssessmentOption(key: key, content: '', label: '');
        }
      }).toList();
    }

    return AssessmentQuestion(
      characterId: json['characterId'] ?? '',
      character: json['character'] ?? '',
      questionType: QuestionType.fromString(json['questionType'] ?? 'recognize'),
      options: parseOptions(json['options']),
      correctAnswer: json['correctAnswer'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
      isReview: json['isReview'] as bool? ?? false,
    );
  }
}

/// 测评答案提交模型
class AssessmentAnswer {
  final String characterId;
  final String userAnswer;
  final int? responseTime;

  AssessmentAnswer({
    required this.characterId,
    required this.userAnswer,
    this.responseTime,
  });

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'userAnswer': userAnswer,
        if (responseTime != null) 'responseTime': responseTime,
      };
}

/// 级别结果模型
class LevelResult {
  final int level;
  final int testedCount;
  final int correctCount;
  final int accuracy;

  LevelResult({
    required this.level,
    required this.testedCount,
    required this.correctCount,
    required this.accuracy,
  });

  factory LevelResult.fromJson(Map<String, dynamic> json) {
    return LevelResult(
      level: json['level'] ?? 1,
      testedCount: json['testedCount'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      accuracy: json['accuracy'] ?? 0,
    );
  }
}

/// 测评结果模型
class AssessmentResult {
  final String assessmentId;
  final AssessmentStatus status;
  final int correctCount;
  final int totalCount;
  final int accuracy;
  final int estimatedWordCount;
  final int recommendedLevel;
  final List<LevelResult> levelResults;
  final int starsEarned;
  final int coinsEarned;
  final int duration;
  // P1-002：新字/复习字分别统计
  final int newWordsCorrect;
  final int newWordsTotal;
  final int reviewWordsCorrect;
  final int reviewWordsTotal;

  AssessmentResult({
    required this.assessmentId,
    required this.status,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.estimatedWordCount,
    required this.recommendedLevel,
    required this.levelResults,
    required this.starsEarned,
    required this.coinsEarned,
    required this.duration,
    this.newWordsCorrect = 0,
    this.newWordsTotal = 0,
    this.reviewWordsCorrect = 0,
    this.reviewWordsTotal = 0,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      assessmentId: json['assessmentId'] ?? '',
      status: AssessmentStatus.fromString(json['status'] ?? 'completed'),
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      accuracy: json['accuracy'] ?? 0,
      estimatedWordCount: json['estimatedWordCount'] ?? 0,
      recommendedLevel: json['recommendedLevel'] ?? 1,
      levelResults: (json['levelResults'] as List<dynamic>?)
              ?.map((e) => LevelResult.fromJson(e))
              .toList() ??
          [],
      starsEarned: json['starsEarned'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      duration: json['duration'] ?? 0,
      newWordsCorrect: json['newWordsCorrect'] ?? 0,
      newWordsTotal: json['newWordsTotal'] ?? 0,
      reviewWordsCorrect: json['reviewWordsCorrect'] ?? 0,
      reviewWordsTotal: json['reviewWordsTotal'] ?? 0,
    );
  }
}

/// 测评主模型
class AssessmentModel {
  final String assessmentId;
  final AssessmentType type;
  final AssessmentStatus status;
  final int? targetLevel;
  final int? questionCount;
  final List<AssessmentQuestion> questions;
  final DateTime startedAt;
  final DateTime? completedAt;
  final AssessmentResult? result;

  AssessmentModel({
    required this.assessmentId,
    required this.type,
    required this.status,
    this.targetLevel,
    this.questionCount,
    required this.questions,
    required this.startedAt,
    this.completedAt,
    this.result,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      assessmentId: json['assessmentId'] ?? json['id'] ?? '',
      type: AssessmentType.fromString(json['type'] ?? 'initial'),
      status: AssessmentStatus.fromString(json['status'] ?? 'in_progress'),
      targetLevel: json['targetLevel'],
      questionCount: json['questionCount'],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => AssessmentQuestion.fromJson(e))
              .toList() ??
          [],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      result: json['result'] != null
          ? AssessmentResult.fromJson(json['result'])
          : null,
    );
  }

  /// 获取进度百分比
  double get progress {
    if (questions.isEmpty) return 0.0;
    final answered = questions.where((q) => q.userAnswer != null).length;
    return answered / questions.length;
  }

  /// 当前题号（从1开始）
  int get currentQuestionNumber {
    return questions.where((q) => q.userAnswer != null).length + 1;
  }

  /// 是否所有题目已答完
  bool get isAllAnswered {
    return questions.every((q) => q.userAnswer != null);
  }
}

/// 测评历史记录
class AssessmentHistory {
  final String id;
  final AssessmentType type;
  final AssessmentStatus status;
  final int correctCount;
  final int totalCount;
  final int accuracy;
  final int estimatedWordCount;
  final int recommendedLevel;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int duration;

  AssessmentHistory({
    required this.id,
    required this.type,
    required this.status,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.estimatedWordCount,
    required this.recommendedLevel,
    required this.startedAt,
    this.completedAt,
    required this.duration,
  });

  factory AssessmentHistory.fromJson(Map<String, dynamic> json) {
    return AssessmentHistory(
      id: json['id'] ?? '',
      type: AssessmentType.fromString(json['type'] ?? 'initial'),
      status: AssessmentStatus.fromString(json['status'] ?? 'completed'),
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      accuracy: json['accuracy'] ?? 0,
      estimatedWordCount: json['estimatedWordCount'] ?? 0,
      recommendedLevel: json['recommendedLevel'] ?? 1,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      duration: json['duration'] ?? 0,
    );
  }
}
