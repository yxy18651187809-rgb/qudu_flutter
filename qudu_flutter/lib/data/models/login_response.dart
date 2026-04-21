/// 登录响应模型
class LoginResponse {
  final bool isNewUser;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      isNewUser: json['isNewUser'] as bool? ?? false,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int? ?? 7200,
      user: json['user'] as Map<String, dynamic>? ?? {},
    );
  }
}
