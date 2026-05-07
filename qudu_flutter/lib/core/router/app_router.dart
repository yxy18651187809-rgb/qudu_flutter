import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/children/children_page.dart';
import '../../presentation/pages/home/home_shell.dart';
import '../../presentation/pages/book_reader/book_reader_page.dart';
import '../../data/models/assessment_model.dart';
import '../../presentation/pages/assessment/assessment_start_page.dart';
import '../../presentation/pages/assessment/assessment_question_page.dart';
import '../../presentation/pages/assessment/assessment_result_page.dart';
import '../../presentation/pages/learning/learning_report_page.dart';
import '../../presentation/pages/profile/parent_monitoring_page.dart';
import '../../presentation/pages/profile/parent_monitoring_detail_page.dart';

/// 路由路径常量
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String children = '/children';
  static const String bookReader = '/book-reader/:bookId';
  static const String assessment = '/assessment/:assessmentId';
  static const String monitoring = '/parent-monitoring/:parentId';
  static const String monitoringDetail = '/parent-monitoring/:parentId/child/:childId';
}

/// 路由刷新监听器 — 监听登录状态变化自动跳转
class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// 检查本地Token是否有效
  Future<void> checkAuth() async {
    _isLoggedIn = await StorageService.isLoggedIn();
    notifyListeners();
  }

  /// 标记已登录（登录成功后调用）
  void markLoggedIn() {
    _isLoggedIn = true;
    notifyListeners();
  }

  /// 标记已登出（退出登录后调用）
  void markLoggedOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

/// 创建全局路由配置
GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // 未登录且不在登录页 → 跳转登录页
      if (!isLoggedIn && !isLoginRoute) {
        return AppRoutes.login;
      }
      // 已登录且在登录页 → 跳转首页
      if (isLoggedIn && isLoginRoute) {
        return AppRoutes.home;
      }
      return null; // 不做重定向
    },
    routes: [
      // 登录页
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // 首页壳（含底部TabBar）
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeShell(),
      ),
      // 儿童档案管理页
      GoRoute(
        path: AppRoutes.children,
        name: 'children',
        builder: (context, state) => const ChildrenPage(),
      ),
      // 绘本阅读器
      GoRoute(
        path: '/book-reader/:bookId',
        name: 'bookReader',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '';
          final childId = state.uri.queryParameters['childId'];
          return BookReaderPage(bookId: bookId, childId: childId);
        },
      ),
      // 测评首页
      GoRoute(
        path: '/assessment/start',
        name: 'assessmentStart',
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          final typeParam = state.uri.queryParameters['type'] ?? 'initial';
          final type = AssessmentType.values.firstWhere(
            (e) => e.apiValue == typeParam,
            orElse: () => AssessmentType.initial,
          );
          return AssessmentStartPage(childId: childId, assessmentType: type);
        },
      ),
      // 答题页面
      GoRoute(
        path: '/assessment/question',
        name: 'assessmentQuestion',
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          final assessment = state.extra as AssessmentModel?;
          return AssessmentQuestionPage(
            childId: childId,
            assessment: assessment ?? AssessmentModel(
              assessmentId: '',
              type: AssessmentType.initial,
              status: AssessmentStatus.inProgress,
              questions: [],
              startedAt: DateTime.now(),
            ),
          );
        },
      ),
      // 结果页面
      GoRoute(
        path: '/assessment/result',
        name: 'assessmentResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AssessmentResultPage(
            assessment: extra?['assessment'] as AssessmentModel? ??
                AssessmentModel(
                  assessmentId: '',
                  type: AssessmentType.initial,
                  status: AssessmentStatus.completed,
                  questions: [],
                  startedAt: DateTime.now(),
                ),
            result: extra?['result'] as AssessmentResult?,
          );
        },
      ),
      // 学习报告页
      GoRoute(
        path: '/learning-report',
        name: 'learningReport',
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          final childName = state.uri.queryParameters['childName'];
          return LearningReportPage(childId: childId, childName: childName);
        },
      ),
      // 家长监控概览
      GoRoute(
        path: '/parent-monitoring/:parentId',
        name: 'parentMonitoring',
        builder: (context, state) {
          final parentId = state.pathParameters['parentId'] ?? '';
          return ParentMonitoringPage(parentId: parentId);
        },
      ),
      // 家长监控-孩子详情
      GoRoute(
        path: '/parent-monitoring/:parentId/child/:childId',
        name: 'parentMonitoringDetail',
        builder: (context, state) {
          final parentId = state.pathParameters['parentId'] ?? '';
          final childId = state.pathParameters['childId'] ?? '';
          final overview = state.extra as MonitoringChildOverview?;
          return ParentMonitoringDetailPage(
            parentId: parentId,
            childId: childId,
            overview: overview,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('页面不存在', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}
