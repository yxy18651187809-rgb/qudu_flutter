# Flutter 混淆 ProGuard 规则
# 配合 flutter build --obfuscate 使用
# Dart 代码混淆由 --obfuscate 处理，此文件仅处理 Android Java/Kotlin 层

# 保留 Flutter 引擎调用
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保留 MainActivity
-keep class com.qudu.ziqu_reading.MainActivity { *; }

# 保留 WebView 相关（如有）
-keep class * extends android.webkit.WebViewClient { *; }

# 保留序列化类
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Gson
-keepattributes Signature
-keepattributes *Annotation*
