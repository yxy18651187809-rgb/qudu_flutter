import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

class ZiquApp extends StatefulWidget {
  const ZiquApp({super.key});

  @override
  State<ZiquApp> createState() => _ZiquAppState();
}

class _ZiquAppState extends State<ZiquApp> {
  late final AuthNotifier _authNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _router = createRouter(_authNotifier);
    // 启动时检查登录状态
    _authNotifier.checkAuth();
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '字趣阅读',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        // 站酷快乐体：圆润活泼，免费商用，契合5-12岁儿童审美
        textTheme: GoogleFonts.zcoolKuaiLeTextTheme(
          AppTheme.lightTheme.textTheme,
        ),
      ),
      routerConfig: _router,
    );
  }
}
