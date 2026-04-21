/// 用户模型
class UserModel {
  final String id;
  final String phone;
  final String nickname;
  final String avatar;
  final bool hasChildren;
  final int childrenCount;

  UserModel({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.avatar,
    required this.hasChildren,
    required this.childrenCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      hasChildren: json['hasChildren'] as bool? ?? false,
      childrenCount: json['childrenCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar': avatar,
      'hasChildren': hasChildren,
      'childrenCount': childrenCount,
    };
  }
}
