/// 汉字/生字数据模型
/// 对应后端 Character Model（seed.js 导入的 L1 300字）
/// 字段来源：01-内容/L1完整字300_后端导入.json
class CharacterModel {
  final String id; // MongoDB ObjectId
  final String character; // 汉字
  final String pinyin; // 拼音（带声调符号，如 hǎo）
  final String radical; // 部首
  final int strokeCount; // 总笔画数
  final String structure; // 结构：独体/左右/上下/半包围/全包围/品字
  final String coreLevel; // 级别：core（核心）/extended（扩展）
  final int level; // 难度等级 1-5（L1=1）
  final String? etymology; // 字源说明（可选）
  final List<String> words; // 常用词组（3-5个）
  final List<String> sentences; // 例句（1-2个）

  /// 掌�性：0=未学, 0.0-1.0=掌握程度
  final double mastery;

  /// 是否已掌握
  bool get isMastered => mastery >= 0.8;

  /// 是否为新字（当前学习进度中）
  bool get isNew => mastery == 0;

  /// 是否待复习
  bool get needsReview => mastery > 0 && mastery < 0.8;

  const CharacterModel({
    required this.id,
    required this.character,
    required this.pinyin,
    required this.radical,
    required this.strokeCount,
    required this.structure,
    required this.coreLevel,
    required this.level,
    this.etymology,
    required this.words,
    required this.sentences,
    this.mastery = 0.0,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id']?.toString() ?? '',
      character: json['character'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      radical: json['radical'] as String? ?? '',
      strokeCount: json['strokeCount'] as int? ?? 0,
      structure: json['structure'] as String? ?? '独体',
      coreLevel: json['coreLevel'] as String? ?? 'core',
      level: json['level'] as int? ?? 1,
      etymology: json['etymology'] as String?,
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sentences: (json['sentences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mastery: (json['mastery'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 复制并更新掌握度
  CharacterModel copyWith({double? mastery}) {
    return CharacterModel(
      id: id,
      character: character,
      pinyin: pinyin,
      radical: radical,
      strokeCount: strokeCount,
      structure: structure,
      coreLevel: coreLevel,
      level: level,
      etymology: etymology,
      words: words,
      sentences: sentences,
      mastery: mastery ?? this.mastery,
    );
  }

  /// 级别标签
  String get levelLabel => 'L$level';

  /// 笔画数标签
  String get strokeLabel => '$strokeCount画';
}
