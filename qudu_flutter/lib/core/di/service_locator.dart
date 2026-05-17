import '../network/api_client.dart';
import '../services/token_storage_impl.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/children_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/learning_report_repository.dart';
import '../../data/repositories/books_repository.dart';
import '../../data/repositories/parent_monitoring_repository.dart';
// TODO(P1): 微信登录服务待修复后启用
// import '../services/wechat_auth_service.dart';

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
  late final LearningRepository learningRepository;
  late final LearningReportRepository learningReportRepository;
  late final ParentMonitoringRepository parentMonitoringRepository;
  late final BooksRepository booksRepository;
  // TODO(P1): 微信登录服务待修复后启用
  // late final WechatAuthService wechatAuthService;

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
    learningRepository = LearningRepository(apiClient: apiClient);
    learningReportRepository = LearningReportRepository(apiClient: apiClient);
    parentMonitoringRepository = ParentMonitoringRepository(apiClient: apiClient);
    booksRepository = BooksRepository(apiClient: apiClient);
    // TODO(P1): 微信登录服务待修复后启用
    // wechatAuthService = WechatAuthService();
  }

  /// 重置所有服务（退出登录时使用）
  void reset() {
    _instance = null;
  }
}
