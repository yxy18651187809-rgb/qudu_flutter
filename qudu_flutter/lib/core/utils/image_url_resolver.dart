/// 图片 URL 解析工具
/// 将相对路径拼接为完整的 API 服务器地址
class ImageUrlResolver {
  /// 将相对URL转为完整URL
  static String resolve(String url) {
    if (url.startsWith('http')) return url;
    const serverBase = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3001',
    );
    return '$serverBase$url';
  }
}
