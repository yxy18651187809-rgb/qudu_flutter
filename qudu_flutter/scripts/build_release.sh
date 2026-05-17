#!/usr/bin/env bash
# ============================================================
# 字趣阅读 - Release 构建脚本（含代码混淆）
# ============================================================
# 用法:
#   ./scripts/build_release.sh android      # 构建 Android APK
#   ./scripts/build_release.sh android-aab  # 构建 Android AAB (上架用)
#   ./scripts/build_release.sh ios          # 构建 iOS IPA
#   ./scripts/build_release.sh all          # 构建全部
#
# 混淆说明:
#   --obfuscate          : 对 Dart 代码进行混淆（类名/函数名/变量名替换）
#   --split-debug-info   : 将调试符号拆分到独立目录（crash还原必需）
#
# ⚠️  debug-symbols/ 目录下的文件必须备份！
#     没有这些文件，无法还原混淆后的崩溃堆栈。
# ============================================================

set -euo pipefail

# ---------- 配置 ----------
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEBUG_INFO_DIR="${PROJECT_DIR}/debug-symbols"
VERSION=$(awk '/^version:/' "${PROJECT_DIR}/pubspec.yaml" | sed 's/version: //')

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------- 参数校验 ----------
PLATFORM="${1:-}"
if [[ -z "$PLATFORM" ]]; then
    error "请指定构建平台: android | android-aab | ios | all"
fi

# ---------- 预检查 ----------
info "项目: 字趣阅读 v${VERSION}"
info "混淆: 已启用 (--obfuscate + --split-debug-info)"

cd "$PROJECT_DIR"

# 确保 Flutter 可用
if ! command -v flutter &>/dev/null; then
    error "Flutter 未安装或不在 PATH 中"
fi

# 检查是否有未提交的变更（release构建应该基于干净状态）
if ! git diff --quiet 2>/dev/null; then
    warn "存在未提交的变更，建议先 commit 或 stash"
    read -p "继续构建? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ---------- 创建 debug-info 输出目录 ----------
# 按版本号+构建时间归档，方便后续 crash 还原
BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SYMBOL_OUT_DIR="${DEBUG_INFO_DIR}/v${VERSION}_${BUILD_TIMESTAMP}"
mkdir -p "$SYMBOL_OUT_DIR"

info "Debug symbols 输出目录: ${SYMBOL_OUT_DIR}"

# ---------- 构建函数 ----------

build_android_apk() {
    info "========== 构建 Android APK (release + obfuscate) =========="
    flutter build apk \
        --release \
        --obfuscate \
        --split-debug-info="${SYMBOL_OUT_DIR}/android" \
        --build-name="${VERSION}" \
        ${EXTRA_FLAGS:-}

    info "APK 产物: build/app/outputs/flutter-apk/app-release.apk"
    info "Android symbols: ${SYMBOL_OUT_DIR}/android/"
}

build_android_aab() {
    info "========== 构建 Android AAB (release + obfuscate) =========="
    flutter build appbundle \
        --release \
        --obfuscate \
        --split-debug-info="${SYMBOL_OUT_DIR}/android" \
        --build-name="${VERSION}" \
        ${EXTRA_FLAGS:-}

    info "AAB 产物: build/app/outputs/bundle/release/app-release.aab"
    info "Android symbols: ${SYMBOL_OUT_DIR}/android/"
}

build_ios() {
    info "========== 构建 iOS IPA (release + obfuscate) =========="

    if [[ "$(uname)" != "Darwin" ]]; then
        error "iOS 构建只能在 macOS 上执行"
    fi

    flutter build ipa \
        --release \
        --obfuscate \
        --split-debug-info="${SYMBOL_OUT_DIR}/ios" \
        --build-name="${VERSION}" \
        ${EXTRA_FLAGS:-}

    info "IPA 产物: build/ios/ipa/*.ipa"
    info "iOS symbols: ${SYMBOL_OUT_DIR}/ios/"
}

# ---------- 执行构建 ----------
case "$PLATFORM" in
    android)
        build_android_apk
        ;;
    android-aab)
        build_android_aab
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android_apk
        build_android_aab
        build_ios
        ;;
    *)
        error "未知平台: ${PLATFORM} (支持: android | android-aab | ios | all)"
        ;;
esac

# ---------- 构建后处理 ----------
info "========== 构建完成 =========="
info "版本: v${VERSION}"
info "Debug symbols 归档: ${SYMBOL_OUT_DIR}"

# 列出 debug symbols 文件
info "Debug symbols 文件列表:"
find "$SYMBOL_OUT_DIR" -type f | sed "s|${SYMBOL_OUT_DIR}/||" | while read -r f; do
    echo "  - $f"
done

# 生成符号归档信息
cat > "${SYMBOL_OUT_DIR}/README.md" <<EOF
# Debug Symbols - v${VERSION}

- **构建时间**: ${BUILD_TIMESTAMP}
- **版本号**: ${VERSION}
- **混淆**: 已启用 (--obfuscate)

## ⚠️ 重要提醒

此目录包含代码混淆的调试符号，**必须安全备份**。
没有这些文件，无法还原混淆后的崩溃堆栈。

## Crash 还原方法

\`\`\`bash
# 还原 Android crash 堆栈
flutter symbolize \
    --input=crash_stacktrace.txt \
    --debug-info=debug-symbols/v${VERSION}_${BUILD_TIMESTAMP}/android/app.android-arm.symbols

# 还原 iOS crash 堆栈
flutter symbolize \
    --input=crash_stacktrace.txt \
    --debug-info=debug-symbols/v${VERSION}_${BUILD_TIMESTAMP}/ios/app.ios-arm64.symbols
\`\`\`

## 文件说明

| 文件 | 说明 |
|------|------|
| app.android-arm.symbols | Android ARM32 调试符号 |
| app.android-arm64.symbols | Android ARM64 调试符号 |
| app.android-x86_64.symbols | Android x86_64 调试符号 |
| app.ios-arm64.symbols | iOS ARM64 调试符号 |
| app.*.map.json | Dart 混淆映射文件 |
EOF

warn "⚠️  请将 ${SYMBOL_OUT_DIR} 目录安全备份（勿提交 Git）"
warn "⚠️  备份后可删除本地副本以节省空间"
info "完成！"
