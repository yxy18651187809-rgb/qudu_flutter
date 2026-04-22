import '../network/api_client.dart';
import '../services/token_storage_impl.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/children_repository.dart';

/// 简单服务定位器
/// Phase 1 轻量DI，后续可替换为 get_it
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance {
    _instance ??= ServiceLocator._();
    return _instance!;
  }

  ServiceLocator._();

  late final ApiClient apiClient;
  late final AuthRepository authRepository;
  late final ChildrenRepository childrenRepository;

  /// 初始化所有服务
  /// 应在main.dart中调用
  void init() {
    final tokenStorage = SecureTokenStorage();
    apiClient = ApiClient(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      ),
      tokenStorage: tokenStorage,
    );
    authRepository = AuthRepository(apiClient: apiClient);
    childrenRepository = ChildrenRepository(apiClient: apiClient);
  }

  /// 重置所有服务（退出登录时使用）
  void reset() {
    _instance = null;
  }
}
