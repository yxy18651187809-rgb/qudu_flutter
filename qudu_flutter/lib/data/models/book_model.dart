/// 绘本数据模型
/// 对应后端 Book 模型（Book.js）
/// 字段与 API 契约文档 v1.2 第4章一致
class BookModel {
  final String id;
  final String title;        // 书名
  final String cover;       // 封面图URL
  final String level;       // 级别：L1~L5
  final List<String> newWords; // 本书新字列表
  final int totalPages;     // 总页数
  final int readCount;      // 已读次数
  final bool isCompleted;   // 是否已读完
  final DateTime? lastReadAt; // 上次阅读时间

  const BookModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.level,
    required this.newWords,
    required this.totalPages,
    this.readCount = 0,
    this.isCompleted = false,
    this.lastReadAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      level: json['level'] ?? 'L1',
      newWords: List<String>.from(json['newWords'] ?? []),
      totalPages: json['totalPages'] ?? 0,
      readCount: json['readCount'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cover': cover,
        'level': level,
        'newWords': newWords,
        'totalPages': totalPages,
        'readCount': readCount,
        'isCompleted': isCompleted,
        'lastReadAt': lastReadAt?.toIso8601String(),
      };

  /// 掌握进度百分比（0.0 ~ 1.0）
  double get masteryProgress =>
      readCount == 0 ? 0.0 : (readCount / (totalPages * 2)).clamp(0.0, 1.0);

  /// 难度标签文字
  String get levelLabel {
    switch (level) {
      case 'L1':
        return '⭐ 启蒙';
      case 'L2':
        return '⭐⭐ 基础';
      case 'L3':
        return '⭐⭐⭐ 进阶';
      case 'L4':
        return '⭐⭐⭐⭐ 提升';
      case 'L5':
        return '⭐⭐⭐⭐⭐ 挑战';
      default:
        return level;
    }
  }
}
