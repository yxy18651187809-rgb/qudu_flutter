/// 儿童档案数据模型
/// 对应API契约 v1.2 第三章
class ChildModel {
  final String id;
  final String name;
  final String avatar;
  final String gender; // male/female/unknown
  final String birthDate; // YYYY-MM-DD
  final int grade; // 0=学前, 1-6=小学
  final int currentLevel; // L1-L5
  final int knownCharacterCount;
  final int streakDays;
  final int totalStars;
  final int totalReadingMinutes;
  final bool isVip;
  final String? vipExpireAt;
  final String? lastLearningAt;
  final String? createdAt;

  const ChildModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.gender,
    required this.birthDate,
    required this.grade,
    required this.currentLevel,
    required this.knownCharacterCount,
    required this.streakDays,
    required this.totalStars,
    required this.totalReadingMinutes,
    required this.isVip,
    this.vipExpireAt,
    this.lastLearningAt,
    this.createdAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      gender: json['gender'] as String? ?? 'unknown',
      birthDate: json['birthDate'] as String? ?? '',
      grade: json['grade'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      knownCharacterCount: json['knownCharacterCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      totalReadingMinutes: json['totalReadingMinutes'] as int? ?? 0,
      isVip: json['isVip'] as bool? ?? false,
      vipExpireAt: json['vipExpireAt'] as String?,
      lastLearningAt: json['lastLearningAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// 创建/更新时提交给API的数据
  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'gender': gender,
    'birthDate': birthDate,
    'grade': grade,
  };

  Map<String, dynamic> toUpdateJson() => {
    if (avatar.isNotEmpty) 'avatar': avatar,
    if (name.isNotEmpty) 'name': name,
    'grade': grade,
  };

  /// 计算年龄（基于birthDate）
  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  /// 等级标签
  String get levelLabel => 'L$currentLevel';
}
