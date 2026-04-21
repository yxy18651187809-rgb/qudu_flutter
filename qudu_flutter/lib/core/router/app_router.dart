import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/children/children_page.dart';
import '../../presentation/pages/home/home_shell.dart';

/// 路由路径常量
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String children = '/children';
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
