/// 登录响应数据模型
/// 对应API契约 2.2 POST /api/v1/auth/login
class LoginResponse {
  final bool isNewUser;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;

  const LoginResponse({
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      isNewUser: json['isNewUser'] as bool? ?? false,
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 7200,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// 用户数据模型
class UserModel {
  final String id;
  final String phone;
  final String nickname;
  final String avatar;
  final bool hasChildren;
  final int childrenCount;

  const UserModel({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.avatar,
    required this.hasChildren,
    required this.childrenCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      hasChildren: json['hasChildren'] as bool? ?? false,
      childrenCount: json['childrenCount'] as int? ?? 0,
    );
  }
}
