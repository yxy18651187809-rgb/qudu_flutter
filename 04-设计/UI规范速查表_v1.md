# 字趣阅读 · UI规范速查表 v1.0

> **面向**：前端开发（Flutter）
> **来源**：视觉风格方案_v1.md
> **版本**：v1.0 | 2026-04-21
> **状态**：待前端确认色值对齐

---

## 一、色彩系统

### 品牌主色板

| Token | 色值 | 用途 |
|-------|------|------|
| `primary` | `#8BC34A` | 主按钮、导航高亮、进度条 |
| `primaryLight` | `#C5E8A8` | 浅色背景、hover态 |
| `primaryDark` | `#689F38` | 深色强调、按下态 |
| `secondary` | `#FFAB91` | 辅色卡片、趣趣腮红 |
| `accent` | `#FFD54F` | 新字高亮背景、徽章 |
| `warning` | `#FF7043` | 警示、新字文字色 |
| `bg` | `#F5F5DC` | 全局背景（米白护眼） |
| `surface` | `#FFFFFF` | 卡片/页面白底 |
| `textPrimary` | `#424242` | 正文文字 |
| `textSecondary` | `#757575` | 辅助说明文字 |
| `textHint` | `#BDBDBD` | 占位符、hint文字 |

### 情绪配色

| 情绪 | 用色 |
|------|------|
| 开心 | `#FFAB91` 暖粉 + `#FFD54F` 阳光黄 |
| 安静 | `#B3E5FC` 淡蓝 + `#C8E6C9` 浅绿 |
| 惊喜 | `#FFAB91` 亮橙 + `#F8BBD9` 粉红 |
| 温馨 | `#FFE0B2` 暖黄 + `#D7CCC8` 淡棕 |

### ⚠️ 色值对齐提醒

> **前端已定义**：`primary = #FFA726`（暖橙）
> **视觉方案**：`primary = #8BC34A`（春绿）
>
> **建议**：统一使用 `#8BC34A`，更符合儿童护眼、品牌温暖的定位。
> 如调整成本高，可暂时保留 `#FFA726`，但需在设计中注明。

---

## 二、字体规范

### 字体族

| 用途 | 字体 | 备选 |
|------|------|------|
| 标题/品牌 | 圆润手写体（如站酷快乐体） | Noto Sans SC Bold |
| 正文 | 思源黑体 Regular/Medium | 系统默认 |
| 英文 | Comic Sans MS / Nunito | system-ui |

> Flutter 注意事项：圆润手写体需下载 `.ttf` 文件放入 `assets/fonts/`，在 `pubspec.yaml` 注册。
> 暂未提供字体文件期间，使用系统默认字体 + `fontWeight: FontWeight.w600` 实现类似效果。

### 字号层级

| Token | 字号 | 行高 | 用途 |
|-------|------|------|------|
| `textH1` | 28sp | 1.4 | 页面大标题 |
| `textH2` | 24sp | 1.4 | 页面标题 |
| `textH3` | 20sp | 1.4 | 章节标题 |
| `textBody` | 16sp | 1.6 | 正文内容 |
| `textBodySmall` | 14sp | 1.5 | 次要正文 |
| `textCaption` | 12sp | 1.4 | 辅助说明 |
| `textNewWord` | 18sp Bold | 1.4 | 新字展示（加粗+底色） |

---

## 三、间距系统

### 基础间距单位：4dp

| Token | 数值 | 用途 |
|-------|------|------|
| `space4` | 4dp | 元素内最小间距 |
| `space8` | 8dp | 同组元素间距 |
| `space12` | 12dp | 卡片内部间距 |
| `space16` | 16dp | 页面边距/大间距 |
| `space24` | 24dp | 区块间距 |
| `space32` | 32dp | 大区块间距 |

### 页面布局规范

| 规范 | 数值 |
|------|------|
| 页面水平边距 | 16-24dp |
| 安全边距（绘本画面） | 各边 8%（即约 24-32dp on 375dp 宽屏） |
| 底部安全区 | 34dp（含刘海屏） |

---

## 四、圆角规范

| 元素 | 圆角 |
|------|------|
| 大卡片 | 16dp |
| 按钮/输入框 | 12dp |
| 小元素（徽章/头像框） | 8dp |
| 头像（圆形） | 50% |
| 新字气泡 | 20dp |

---

## 五、组件规范

### 按钮

```
主按钮：
  - 背景：primary (#8BC34A)
  - 文字：#FFFFFF, 16sp Bold
  - 高度：48dp
  - 圆角：12dp
  - 内边距：16dp horizontal, 12dp vertical
  - 按下态：primaryDark (#689F38)

次按钮：
  - 背景：transparent
  - 边框：1.5dp primary
  - 文字：primary, 16sp
  - 高度：44dp
  - 圆角：12dp

禁用态：
  - 背景：#E0E0E0
  - 文字：#9E9E9E
```

### 卡片

```
标准卡片：
  - 背景：surface (#FFFFFF)
  - 圆角：16dp
  - 阴影：elevation 2dp（模拟：box-shadow: 0 2px 8px rgba(0,0,0,0.08)）
  - 内边距：16dp
  - 间距：与相邻卡片至少 space12 (12dp)

绘本页面卡片：
  - 背景：米白/纯白
  - 圆角：12dp
  - 无阴影（保持轻量感）
```

### 输入框

```
标准输入框：
  - 背景：#FFFFFF
  - 边框：1.5dp #E0E0E0（未聚焦）/ primary（聚焦）
  - 圆角：12dp
  - 高度：48dp
  - 内边距：16dp
  - 文字：textPrimary
  - hint文字：textHint
```

### 新字气泡

```
新字标注气泡：
  - 背景：#FFD54F（阳光黄）透明度 85%
  - 圆角：20dp
  - 内边距：6dp 10dp
  - 文字：#FF7043（橙红）18sp Bold
  - 位置：紧邻对应物体右侧或下方
  - 气泡样式：圆角矩形，无边框，像漫画气泡
```

---

## 六、图标规范

### 风格

- 扁平插画风，与绘本水彩风区分但色调统一
- 线条粗细：2px
- 线条色：`#424242`（textPrimary）或 `#8BC34A`（功能色）
- 填充色：使用品牌色系

### 尺寸

| 用途 | 尺寸 |
|------|------|
| TabBar图标 | 28×28dp |
| 功能图标 | 24×24dp |
| 大图标（空状态） | 80×80dp |
| 表情/反馈图标 | 48×48dp |

### TabBar 预估清单

| 页面 | 图标描述 |
|------|---------|
| 首页 | 小房子 |
| 学习 | 打开的书 |
| 绘本 | 绘本封面 |
| 成就 | 星星徽章 |
| 我的 | 趣趣头像 |

---

## 七、IP形象规范（趣趣）

### 趣趣配色

| 部位 | 色值 |
|------|------|
| 身体 | `#C5E1A5`（淡黄绿） |
| 腹部 | `#FFF8E1`（乳白） |
| 腮红 | `#FFAB91`（粉红） |
| 头顶叶子 | `#8BC34A`（春绿） |
| 眼睛/嘴巴 | `#424242`（深灰） |

### 使用尺寸

| 场景 | 尺寸 |
|------|------|
| 头像/头像框 | 64×64dp（圆形裁剪） |
| TabBar我的 | 28×28dp |
| 引导角色 | 100×140dp |
| 全屏展示 | 200×280dp |

---

## 八、快速参考（复制粘贴用）

```dart
// 色彩常量
const primary = Color(0xFF8BC34A);
const primaryLight = Color(0xFFC5E8A8);
const primaryDark = Color(0xFF689F38);
const secondary = Color(0xFFFFAB91);
const accent = Color(0xFFFFD54F);
const warning = Color(0xFFFF7043);
const bg = Color(0xFFF5F5DC);
const surface = Color(0xFFFFFFFF);
const textPrimary = Color(0xFF424242);
const textSecondary = Color(0xFF757575);

// 间距
const space8 = 8.0;
const space12 = 12.0;
const space16 = 16.0;
const space24 = 24.0;

// 圆角
const radiusSmall = 8.0;
const radiusMedium = 12.0;
const radiusLarge = 16.0;
```

---

## 九、待确认事项

| 事项 | 状态 | 备注 |
|------|------|------|
| 主色色值对齐（#FFA726 vs #8BC34A） | ⏳ 待前端确认 | 需前端负责人回复 |
| 圆润字体文件 | ⏳ 待提供 | 暂用系统字体替代 |
| 登录页功能需求 | ⏳ 待前端提供 | 方便设计匹配 |
| 绘本页面特殊交互 | ⏳ 待确认 | 翻页动画、点击反馈等 |

---

*文档版本：v1.0*
*作者：插画师*
*更新日期：2026-04-21*
*配套文件：04-设计/视觉风格方案_v1.md*
