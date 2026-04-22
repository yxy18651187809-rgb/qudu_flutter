import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务定位器
  ServiceLocator.instance.init();

  runApp(const ZiquApp());
}
