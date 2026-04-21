# 字趣阅读 Flutter 项目初始化指南

> 版本：v1.0 | 更新日期：2026-04-20  
> 目标平台：iOS + Android | 目标用户：5-12岁儿童

---

## 📋 前置准备

### 1. 开发环境要求

| 组件 | 版本要求 | 说明 |
|------|----------|------|
| Flutter SDK | ≥3.19.0 | 稳定版，支持Impeller渲染引擎 |
| Dart SDK | ≥3.3.0 | 与Flutter版本配套 |
| Android Studio | 最新版 | 用于Android开发 |
| Xcode | ≥15.0 | 用于iOS开发（仅Mac） |
| CocoaPods | ≥1.12.0 | iOS依赖管理 |
| JDK | ≥17 | Android构建需要 |

### 2. 系统检查命令

```bash
# 检查Flutter环境
flutter doctor

# 检查Flutter版本
flutter --version

# 检查设备连接
flutter devices
```

---

## 🚀 项目创建

### 1. 创建新项目

```bash
# 使用稳定通道
flutter channel stable
flutter upgrade

# 创建项目（使用org.qudu包名）
flutter create --org com.qudu --project-name ziqu_reading \
  --description "字趣阅读 - 5-12岁儿童AI识字阅读APP" \
  --platforms ios,android \
  qudu_flutter

cd qudu_flutter
```

### 2. 项目结构初始化

```
qudu_flutter/
├── android/                    # Android原生代码
├── ios/                        # iOS原生代码
├── lib/
│   ├── main.dart              # 入口文件
│   ├── app.dart               # 应用配置
│   ├── core/                  # 核心层
│   │   ├── constants/         # 常量定义
│   │   ├── theme/             # 主题配置
│   │   ├── utils/             # 工具类
│   │   └── services/          # 基础服务
│   ├── data/                  # 数据层
│   │   ├── models/            # 数据模型
│   │   ├── repositories/      # 数据仓库
│   │   └── datasources/       # 数据源
│   ├── domain/                # 领域层
│   │   ├── entities/          # 实体
│   │   └── usecases/          # 用例
│   ├── presentation/          # 表现层
│   │   ├── blocs/             # 状态管理
│   │   ├── pages/             # 页面
│   │   └── widgets/           # 组件
│   └── routes.dart            # 路由配置
├── assets/                    # 静态资源
│   ├── images/                # 图片
│   ├── animations/            # 动画
│   ├── fonts/                 # 字体
│   └── audio/                 # 音频
├── test/                      # 单元测试
└── integration_test/          # 集成测试
```

---

## 📦 依赖配置

### 1. pubspec.yaml 核心依赖

```yaml
name: ziqu_reading
description: 字趣阅读 - 5-12岁儿童AI识字阅读APP
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # UI组件
  cupertino_icons: ^1.0.6
  flutter_svg: ^2.0.9          # SVG支持
  lottie: ^3.0.0               # Lottie动画
  shimmer: ^3.0.0              # 闪光效果
  
  # 状态管理
  flutter_bloc: ^8.1.3         # BLoC模式
  equatable: ^2.0.5            # 相等性比较
  
  # 路由
  go_router: ^13.0.1           # 声明式路由
  
  # 网络请求
  dio: ^5.4.0                  # HTTP客户端
  retrofit: ^4.0.3             # API接口生成
  
  # 本地存储
  hive: ^2.2.3                 # 轻量级数据库
  hive_flutter: ^1.1.0         # Hive Flutter支持
  shared_preferences: ^2.2.2 # 简单键值存储
  
  # 音频播放
  audioplayers: ^5.2.1         # 音频播放
  
  # 图片处理
  cached_network_image: ^3.3.1   # 图片缓存
  image_picker: ^1.0.7         # 图片选择
  
  # 权限管理
  permission_handler: ^11.0.1  # 权限处理
  
  # 设备信息
  device_info_plus: ^9.1.2     # 设备信息
  package_info_plus: ^5.0.1    # 包信息
  
  # 日志与监控
  logger: ^2.0.2               # 日志输出
  firebase_core: ^2.24.2       # Firebase核心
  firebase_crashlytics: ^3.4.8 # 崩溃分析
  
  # 支付
  flutter_inapp_purchase: ^5.9.0  # 应用内购买
  
  # 国际化
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1          # 代码规范
  build_runner: ^2.4.8           # 代码生成
  retrofit_generator: ^8.0.6     # Retrofit生成
  hive_generator: ^2.0.1         # Hive生成
  flutter_launcher_icons: ^0.13.1 # 图标生成
  flutter_native_splash: ^2.3.9    # 启动屏生成

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/animations/
    - assets/audio/
    - assets/fonts/
  
  fonts:
    - family: ZiQuFont
      fonts:
        - asset: assets/fonts/ZiQu-Regular.ttf
        - asset: assets/fonts/ZiQu-Bold.ttf
          weight: 700
```

### 2. 安装依赖

```bash
flutter pub get
```

---

## 🎨 主题配置（儿童友好设计）

### 1. 色彩系统

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 温暖活泼
  static const Color primary = Color(0xFFFFA726);      // 暖橙色
  static const Color primaryLight = Color(0xFFFFCC80); // 浅橙色
  static const Color primaryDark = Color(0xFFF57C00);  // 深橙色
  
  // 辅助色
  static const Color secondary = Color(0xFF66BB6A);    // 清新绿
  static const Color accent = Color(0xFF42A5F5);       // 天空蓝
  static const Color highlight = Color(0xFFFFEE58);    // 柠檬黄
  
  // 中性色
  static const Color background = Color(0xFFFFFBF5);   // 米白背景
  static const Color surface = Color(0xFFFFFFFF);      // 纯白
  static const Color textPrimary = Color(0xFF3E2723);  // 深棕文字
  static const Color textSecondary = Color(0xFF6D4C41);// 次要文字
  
  // 状态色
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);
}
```

### 2. 字体与排版

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';

class AppTypography {
  // 标题样式
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  // 正文样式
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.3,
  );
  
  // 儿童阅读专用 - 大字号
  static const TextStyle readingText = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.8,
    letterSpacing: 1.0,
  );
  
  // 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}
```

### 3. 圆角与阴影

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      cardTheme: _buildCardTheme(),
      appBarTheme: _buildAppBarTheme(),
    );
  }
  
  // 卡片主题 - 大圆角
  static CardTheme _buildCardTheme() {
    return CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: AppColors.primary.withOpacity(0.2),
    );
  }
  
  // 按钮主题 - 大圆角
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTypography.button,
      ),
    );
  }
}
```

---

## 🔧 核心配置

### 1. Android配置

#### android/app/build.gradle

```gradle
android {
    namespace = "com.qudu.ziqu_reading"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.qudu.ziqu_reading"
        minSdk = 21        // 支持Android 5.0+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // 签名配置（发布时）
    signingConfigs {
        release {
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
            storeFile = file(System.getenv("KEYSTORE_PATH"))
            storePassword = System.getenv("STORE_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### Android权限配置

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- 网络权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- 存储权限 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- 音频权限 -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <!-- 相机权限（如需拍照） -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="字趣阅读"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:screenOrientation="portrait">  <!-- 锁定竖屏 -->
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
                
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 2. iOS配置

#### ios/Runner/Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>字趣阅读</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ziqu_reading</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    
    <!-- 屏幕方向 - 仅竖屏 -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    
    <!-- 权限说明 -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>需要访问相册以选择头像图片</string>
    <key>NSCameraUsageDescription</key>
    <string>需要相机权限以拍摄头像</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>需要麦克风权限以录制语音跟读</string>
    
    <!-- 后台音频 -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>
</dict>
</plist>
```

#### ios/Podfile

```ruby
platform :ios, '13.0'

# ... 标准配置 ...

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

---

## 🔄 CI/CD 配置

### 1. GitHub Actions 工作流

#### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Check formatting
        run: dart format --set-exit-if-changed .
      
      - name: Run tests
        run: flutter test

  build-android:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build AppBundle
        run: flutter build appbundle --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: |
            build/app/outputs/flutter-apk/*.apk
            build/app/outputs/bundle/release/*.aab

  build-ios:
    runs-on: macos-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: |
          flutter pub get
          cd ios && pod install
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: build/ios/iphoneos/*.app
```

#### .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
      
      - name: Build Release AAB
        run: flutter build appbundle --release
        env:
          KEYSTORE_PATH: android/app/keystore.jks
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.qudu.ziqu_reading
          releaseFiles: build/app/outputs/bundle/release/*.aab
          track: internal
```

### 2. 代码质量配置

#### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
  language:
    strict-casts: true
    strict-raw-types: true

linter:
  rules:
    # 代码风格
    prefer_single_quotes: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_fields: true
    prefer_final_locals: true
    
    # 命名规范
    constant_identifier_names: true
    file_names: true
    library_names: true
    
    # 文档
    public_member_api_docs: false  # 开发阶段关闭，上线前开启
    
    # 性能
    avoid_slow_async_io: true
    avoid_unnecessary_containers: true
    
    # 安全
    avoid_dynamic_calls: true
    avoid_print: true
    
    # Flutter特有
    use_build_context_synchronously: true
    use_colored_box: true
    use_decorated_box: true
```

---

## 📱 应用商店准备

### 1. 应用图标与启动屏

```yaml
# pubspec.yaml 中添加配置
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#FFFBF5"
  adaptive_icon_foreground: "assets/images/app_icon_foreground.png"

flutter_native_splash:
  color: "#FFFBF5"
  image: assets/images/splash_logo.png
  android: true
  ios: true
  fullscreen: true
```

生成命令：

```bash
# 生成图标
flutter pub run flutter_launcher_icons:main

# 生成启动屏
flutter pub run flutter_native_splash:create
```

### 2. 应用商店素材清单

| 平台 | 素材项 | 规格要求 | 状态 |
|------|--------|----------|------|
| App Store | 应用图标 | 1024×1024px | ⏳ 待设计 |
| App Store | 截图(5张) | 1290×2796px (iPhone) | ⏳ 待制作 |
| App Store | 预览视频 | 15-30秒 | ⏳ 待制作 |
| Play Store | 应用图标 | 512×512px | ⏳ 待设计 |
| Play Store | 截图(8张) | 1242×2208px | ⏳ 待制作 |
| Play Store | 特色大图 | 1024×500px | ⏳ 待设计 |

---

## 🧪 测试策略

### 1. 测试结构

```
test/
├── unit/                      # 单元测试
│   ├── models/                # 模型测试
│   ├── repositories/          # 仓库测试
│   └── utils/                 # 工具测试
├── widget/                    # 组件测试
│   ├── pages/                 # 页面测试
│   └── widgets/               # 组件测试
├── bloc/                      # BLoC测试
└── integration/               # 集成测试
    └── app_test.dart
```

### 2. 测试命令

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/models/

# 运行带覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 集成测试
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

---

## 🚀 常用开发命令

```bash
# 运行开发版本
flutter run

# 运行指定设备
flutter run -d <device_id>

# 热重载（按r）
# 热重启（按R）
# 退出（按q）

# 构建发布版本
flutter build apk --release                    # Android APK
flutter build appbundle --release             # Android AAB
flutter build ios --release                   # iOS

# 清理构建缓存
flutter clean
flutter pub get

# 检查依赖过时
flutter pub outdated

# 升级依赖
flutter pub upgrade

# 生成代码（如需要）
flutter pub run build_runner build --delete-conflicting-outputs

# 查看设备列表
flutter devices

# 查看日志
flutter logs
```

---

## 📋 上线前检查清单

### 功能检查
- [ ] 所有页面导航正常
- [ ] 状态管理无内存泄漏
- [ ] 网络请求错误处理完善
- [ ] 离线模式基础功能可用
- [ ] 音频播放正常，后台播放支持
- [ ] 支付流程完整测试

### 性能检查
- [ ] 启动时间 < 3秒
- [ ] 页面切换流畅（60fps）
- [ ] 图片加载优化（懒加载+缓存）
- [ ] APK大小 < 50MB

### 安全检查
- [ ] API密钥不在代码中硬编码
- [ ] 敏感数据加密存储
- [ ] 日志中无敏感信息
- [ ] HTTPS强制使用

### 儿童保护检查
- [ ] 无第三方广告SDK
- [ ] 无不当内容
- [ ] 家长控制功能可用
- [ ] 隐私政策完整

---

## 📚 参考资源

- [Flutter官方文档](https://docs.flutter.dev/)
- [Flutter中文社区](https://flutter.cn/)
- [Dart语言指南](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)
- [Flutter状态管理](https://bloclibrary.dev/)

---

**文档版本：** v1.0  
**最后更新：** 2026-04-20  
**维护人：** 前端负责人
