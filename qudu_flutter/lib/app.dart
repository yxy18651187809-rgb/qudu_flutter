import 'package:flutter/material.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/children/children_page.dart';
import 'core/theme/app_theme.dart';

class ZiquApp extends StatelessWidget {
  const ZiquApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '字趣阅读',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/children': (_) => const ChildrenPage(),
      },
    );
  }
}
