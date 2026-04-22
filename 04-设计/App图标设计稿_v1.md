# 字趣阅读 · App图标设计稿 v1.0

> **产品**：字趣阅读（5-12岁儿童AI识字阅读APP）  
> **图标名称**：App Icon / 应用图标  
> **版本**：v1.0 | 2026-04-22  
> **状态**：初稿完成，待前端集成

---

## 一、图标设计规范

### 1.1 设计概念

**核心形象**：趣趣（Qùqu）—— 小书虫IP

趣趣是一只可爱的绿色小书虫，头顶一片嫩绿的叶子，手持一本小书，代表"在阅读中寻找乐趣"的品牌理念。

**设计风格**：
- 圆润可爱的卡通风格
- 温暖明亮的儿童向配色
- 简洁清晰的辨识度

### 1.2 色彩系统

| 用途 | 色值 | 说明 |
|:---|:---:|:---|
| 主色（趣趣身体） | #C5E1A5 | 淡黄绿色 |
| 叶子色 | #8BC34A | 春绿色 |
| 腮红色 | #FFAB91 | 暖粉色 |
| 书颜色 | #FF8A65 | 珊瑚橙 |
| 眼睛色 | #212121 | 深灰色 |
| 描边色 | #A5C487 | 灰绿色 |
| 背景渐变起点 | #8BC34A | 春绿色 |
| 背景渐变终点 | #4CAF50 | 翠绿色 |

### 1.3 尺寸规格

| 平台 | 尺寸 | 用途 |
|:---|:---:|:---|
| iOS App Store | 1024×1024px | App Store展示 |
| iOS 设备图标 | 180×180px @3x | iPhone |
| iOS 设备图标 | 167×167px @2x | iPad Pro |
| iOS 设备图标 | 152×152px @2x | iPad |
| iOS 设备图标 | 120×120px @3x | iPhone Spotlight |
| Android | 512×512px | Play Store |
| Android | 48/72/96/144/192dp | 各分辨率 |

---

## 二、图标设计方案

### 方案A：趣趣圆形头像

**设计说明**：
趣趣的可爱圆形头像，背景是渐变绿色圆角矩形，带有柔和阴影。

```
┌─────────────────────────────────────┐
│                                     │
│    ┌─────────────────────────┐      │
│    │                         │      │
│    │      🍃 趣趣头像        │      │
│    │      （绿色圆形）        │      │
│    │                         │      │
│    │     (◕‿◕) 开心微笑     │      │
│    │                         │      │
│    │      📖 手持小书        │      │
│    │                         │      │
│    └─────────────────────────┘      │
│                                     │
│         字  趣  阅  读              │
│                                     │
└─────────────────────────────────────┘
```

**视觉元素**：
- 主体：趣趣圆形头像，占图标60%
- 背景：渐变绿色圆角矩形
- 底部：品牌名"字趣阅读"四个字

---

### 方案B：趣趣全身像（推荐）

**设计说明**：
趣趣站立全身像，背景是简单的渐变色，搭配品牌名。

```
┌─────────────────────────────────────┐
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │          🍃                   │  │
│  │                               │  │
│  │      ╭──────────╮             │  │
│  │      │  (◕‿◕)  │ ← 趣趣     │  │
│  │      │   微笑    │             │  │
│  │      ╰──────────╯             │  │
│  │           📖                  │  │
│  │       ╭────────╮              │  │
│  │       │ 身体    │              │  │
│  │       ╰────────╯              │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│         字  趣  阅  读              │
│                                     │
└─────────────────────────────────────┘
```

**视觉元素**：
- 主体：趣趣全身像（3节身体+叶子头）
- 表情：开心微笑（默认表情）
- 手持：红色小书
- 背景：渐变绿色
- 底部：品牌名

---

## 三、图标视觉细节

### 3.1 趣趣造型参数

```
趣趣标准全身像参数：

头部：
- 头部形状：椭圆形
- 头部尺寸：宽度42px，高度38px（基于160px总高）
- 叶子位置：头顶中央，倾斜-10度
- 叶子尺寸：宽度13px，高度20px

眼睛：
- 眼睛类型：圆眼
- 眼睛尺寸：直径14px
- 瞳孔：直径9.5px，深灰色
- 高光：直径3px，白色，位于左上方

嘴巴：
- 类型：微笑弧线
- 弧度：Q60 96 94（基于大尺寸）

腮红：
- 位置：眼睛下方两侧
- 尺寸：12×9px
- 颜色：#FFAB91，透明度55%

身体：
- 节数：3节
- 第一节：32×26px
- 第二节：28×22px
- 第三节：22×18px
- 腹部：乳白色椭圆

手：
- 尺寸：直径11px圆形
- 位置：第一节身体两侧

书：
- 尺寸：28×22px
- 颜色：#FF8A65
```

### 3.2 阴影与立体感

**投影参数**：
```css
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
```

**内阴影**（趣趣身体）：
```css
/* 身体渐变，增加立体感 */
linear-gradient(
  180deg,
  #C5E1A5 0%,
  #B5D495 50%,
  #A5C485 100%
)
```

---

## 四、背景设计

### 4.1 渐变背景

```css
/* 背景渐变 */
background: linear-gradient(
  135deg,    /* 渐变角度：从左上到右下 */
  #8BC34A 0%,   /* 春绿色 */
  #4CAF50 100%  /* 翠绿色 */
);
```

### 4.2 可选背景方案

| 方案 | 描述 | 适用场景 |
|:---:|:---|:---|
| A | 纯渐变绿背景 | 简洁现代风格 |
| B | 渐变绿+音符/书本装饰 | 童趣风格 |
| C | 纯白背景+彩色趣趣 | 极简风格 |

---

## 五、前端实现指南

### 5.1 Flutter 集成

```dart
// App图标组件示例
class AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8BC34A), // 春绿色
            Color(0xFF4CAF50), // 翠绿色
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/ququ_logo.svg',
          width: 80,
          height: 80,
        ),
      ),
    );
  }
}
```

### 5.2 导出格式

**矢量格式（首选）**：
- SVG：用于Flutter的svg插件
- PDF：用于iOS/Android原生开发

**位图格式**：
- PNG：用于不支持矢量的场景
- 建议导出：1x, 2x, 3x三种尺寸

---

## 六、设计资源

### 6.1 趣趣IP SVG源文件

趣趣IP的SVG矢量图形已定义在以下文件：
- `04-设计/趣趣IP形象概念图.html` — 包含趣趣全身像SVG代码

### 6.2 趣趣形象代码片段

**趣趣标准正面全身像**（可直接复制到设计工具）：

```svg
<svg viewBox="0 0 160 210" xmlns="http://www.w3.org/2000/svg">
  <!-- 身体节3 -->
  <ellipse cx="80" cy="180" rx="22" ry="18" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <!-- 身体节2 -->
  <ellipse cx="80" cy="150" rx="28" ry="22" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <!-- 身体节1 -->
  <ellipse cx="80" cy="116" rx="32" ry="26" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <!-- 尾巴 -->
  <path d="M80 195 Q90 208 80 218 Q70 208 80 195" fill="#A5C487"/>
  <!-- 腹部 -->
  <ellipse cx="80" cy="180" rx="12" ry="9" fill="#FFF8E1" opacity="0.85"/>
  <ellipse cx="80" cy="150" rx="17" ry="13" fill="#FFF8E1" opacity="0.85"/>
  <ellipse cx="80" cy="116" rx="20" ry="15" fill="#FFF8E1" opacity="0.85"/>
  <!-- 手 -->
  <circle cx="40" cy="112" r="11" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <circle cx="120" cy="112" r="11" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <!-- 书 -->
  <rect x="116" y="94" width="28" height="22" rx="4" fill="#FF8A65" stroke="#E64A19" stroke-width="1.5"/>
  <line x1="130" y1="94" x2="130" y2="116" stroke="#E64A19" stroke-width="1.5"/>
  <!-- 头部 -->
  <ellipse cx="80" cy="68" rx="42" ry="38" fill="#C5E1A5" stroke="#A5C487" stroke-width="2"/>
  <!-- 叶子 -->
  <ellipse cx="80" cy="30" rx="13" ry="20" fill="#8BC34A" stroke="#689F38" stroke-width="1.5" transform="rotate(-8 80 30)"/>
  <line x1="80" y1="36" x2="80" y2="50" stroke="#689F38" stroke-width="2"/>
  <!-- 腮红 -->
  <ellipse cx="48" cy="78" rx="12" ry="9" fill="#FFAB91" opacity="0.55"/>
  <ellipse cx="112" cy="78" rx="12" ry="9" fill="#FFAB91" opacity="0.55"/>
  <!-- 眼睛 -->
  <circle cx="63" cy="62" r="14" fill="white" stroke="#E0E0E0" stroke-width="1"/>
  <circle cx="63" cy="63" r="9.5" fill="#212121"/>
  <circle cx="67" cy="58" r="3" fill="white"/>
  <circle cx="97" cy="62" r="14" fill="white" stroke="#E0E0E0" stroke-width="1"/>
  <circle cx="97" cy="63" r="9.5" fill="#212121"/>
  <circle cx="101" cy="58" r="3" fill="white"/>
  <!-- 嘴巴 -->
  <path d="M66 84 Q80 96 94 84" stroke="#795548" stroke-width="2.5" fill="none" stroke-linecap="round"/>
</svg>
```

---

## 七、版本记录

| 版本 | 日期 | 更新内容 |
|:---:|:---:|:---|
| v1.0 | 2026-04-22 | 初稿完成，包含设计方案和SVG代码 |

---

*设计输出：插画师*  
*文档版本：v1.0*  
*配套文件：`04-设计/趣趣IP形象概念图.html`*
