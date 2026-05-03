# TabBar图标设计稿 v1.0

> **产品**：字趣阅读
> **版本**：v1.0 | 2026-05-02
> **状态**：初稿完成，待前端集成

---

## 一、设计规范

### 1.1 底部TabBar配置

| 位置 | 页面 | 图标 | 选中色 | 未选中色 |
|:---:|:---:|:---:|:---:|:---:|
| 第1个 | 首页 | 🏠 home | #4CAF50 | #9E9E9E |
| 第2个 | 识字 | 📖 book | #4CAF50 | #9E9E9E |
| 第3个 | 书架 | 📚 bookshelf | #4CAF50 | #9E9E9E |
| 第4个 | 我的 | 👤 user | #4CAF50 | #9E9E9E |

### 1.2 图标尺寸

- **iOS**：25×25pt @1x, 50×50pt @2x, 75×75pt @3x
- **Android**：24dp, 36dp, 48dp, 72dp

### 1.3 颜色系统

| 用途 | 色值 | 说明 |
|:---|:---:|:---|
| 选中色 | #4CAF50 | 主绿色 |
| 未选中色 | #9E9E9E | 灰色 |
| 文字色 | #212121 | 深灰（选中）/ #757575（未选） |
| 背景色 | #FFFFFF | 白色 |

---

## 二、图标设计

### 2.1 首页（Home）

```
🏠
```

**SVG代码**：
```svg
<svg viewBox="0 0 24 24" ...>
  <!-- 房屋轮廓 -->
  <path d="M10 20v-8h4v8" fill="#4CAF50"/>
  <!-- 门 -->
  <path d="M12 12h-2v-2h2v2" fill="white"/>
  <!-- 房子主体 -->
  <path d="M12 3L2 12h3v8h14v-8h3L12 3z" fill="none" stroke="#4CAF50" stroke-width="1.5"/>
</svg>
```

### 2.2 识字（Word Learning）

```
📖 书本
```

**设计要点**：
- 打开的书籍，右侧有文字"识"
- 或使用单个书本图标

### 2.3 书架（Bookshelf）

```
📚
```

**设计要点**：
- 三层书架，每层有书本
- 简化版本：单个书本图标+格子

### 2.4 我的（Profile）

```
👤
```

**设计要点**：
- 圆形头像轮廓
- 内部为趣趣头像

---

## 三、Flutter 集成

### 3.1 资源放置

```
qudu_flutter/
└── assets/
    └── icons/
        ├── tab_home.svg
        ├── tab_word.svg
        ├── tab_bookshelf.svg
        └── tab_profile.svg
```

### 3.2 使用方式

```dart
// 在BottomNavigationBar中使用
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: SvgPicture.asset('assets/icons/tab_home.svg'),
      label: '首页',
    ),
    // ...
  ],
)
```

---

## 四、交付物清单

| 文件 | 用途 | 状态 |
|:---|:---|:---:|
| `app_icon_v1.1.svg` | App图标512×512 | ✅ 已交付 |
| `app_icon_v1.svg` | App图标初稿 | ✅ 已交付 |
| `TabBar图标设计稿_v1.md` | 本文档 | ✅ 已交付 |
| `tab_*.svg` | TabBar图标 | 🔶 待生成 |

---

## 五、版本记录

| 版本 | 日期 | 更新内容 |
|:---:|:---:|:---|
| v1.0 | 2026-05-02 | 初稿完成 |

*设计输出：插画师*