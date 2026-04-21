/// 儿童档案模型
class ChildModel {
  final String id;
  String name;
  String avatar;
  String gender;
  String birthDate;
  int grade;
  int currentLevel;
  int knownCharacterCount;
  int streakDays;
  int totalStars;
  int totalReadingMinutes;
  bool isVip;

  ChildModel({
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
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      grade: json['grade'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      knownCharacterCount: json['knownCharacterCount'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      totalReadingMinutes: json['totalReadingMinutes'] as int? ?? 0,
      isVip: json['isVip'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthDate': birthDate,
      'grade': grade,
    };
  }

  /// 获取等级名称
  String get levelName {
    switch (currentLevel) {
      case 1: return 'L1 启蒙级';
      case 2: return 'L2 起步级';
      case 3: return 'L3 发展级';
      case 4: return 'L4 提升级';
      case 5: return 'L5 进阶级';
      default: return 'L1 启蒙级';
    }
  }

  /// 获取等级星星数
  int get levelStars => currentLevel;
}
