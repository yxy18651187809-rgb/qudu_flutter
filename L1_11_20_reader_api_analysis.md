# L1-11~20 阅读器接口分析报告

> **分析人**：前端负责人
> **日期**：2026-06-16
> **结论**：❌ **不需要新接口** — L1 11-20 故事与 01-10 绘本数据结构完全同构

---

## 一、核心结论

**不需要新接口。** L1 11-20 故事在数据层面与 01-10 绘本完全同构，现有的 `GET /books/:id` 接口可以直接服务两种内容类型。

| 类型 | bookId | 数据结构 | 阅读器 | 接口 |
|------|--------|---------|--------|------|
| 绘本（01-10） | L1_book_01~10 | Book → BookPage[] | BookReaderPage | GET /books/:id |
| 故事（11-20） | L1_book_11~20 | Book → BookPage[] | BookReaderPage | GET /books/:id |

**数据流完全一致**：每篇内容 = 1条 Book 记录 + N条 BookPage 子记录（含 text/pinyin/image/wordAnnotations），API 返回格式无需修改，前端 BookReaderPage / BookReaderRepository / BookDetailModel 无需改动。

---

## 二、现状排查

### 2.1 内容侧（教研）

| 检查项 | 状态 | 详情 |
|--------|:---:|------|
| 总体规划 | ✅ | 100篇故事教案_v1 含 L1-11~20 列表 |
| 故事文案 | ✅ | 插画需求单_L1_第11-20篇.md（1738行）含全10篇分镜 |
| 每页文字 | ✅ | 115条"文字内容"——覆盖所有页面 |
| 拼音标注 | ✅ | 每页均含拼音 |
| 新字标注 | ✅ | 每页均含新字气泡标注方案 |
| 独立教案MD | ⚠️ | 无（与01-10不同，11-20无独立 .md 文件）|

**10篇故事清单**：

| 编号 | 标题 | 主题 | 页数 | 新字数 |
|:---:|------|------|:---:|:---:|
| 11 | 数一数 | 认知（数字） | 10 | 12字 |
| 12 | 小猫钓鱼 | 成长（耐心） | 12 | 15字 |
| 13 | 谁的手 | 认知（方位） | 11 | 14字 |
| 14 | 下雨了 | 自然（天气） | 12 | 16字 |
| 15 | 好朋友 | 社交（友谊） | 10 | 8字 |
| 16 | 吃饭了 | 生活（饮食） | 10 | 8字 |
| 17 | 白白的云 | 自然（天空） | 10 | 8字 |
| 18 | 大和小 | 认知（对比） | 10 | 14字 |
| 19 | 我会自己做 | 成长（自理） | 10 | 14字 |
| 20 | 晚安 | 生活（作息） | 10 | 14字 |

**合计**：105页文案 + ~123个新字

### 2.2 设计侧（插画）

| 检查项 | 状态 | 详情 |
|--------|:---:|------|
| 设计文档 | ✅ | 角色设定 + 分镜脚本 + 对齐回执 全覆盖 |
| 插画 PNG | ❌ | **0张**（与 L3/L4/L5 908张形成对比） |
| 插画规格 | ✅ | 已定义：800×1067px、Q版、暖色系 |

### 2.3 后端侧

| 检查项 | 状态 | 详情 |
|--------|:---:|------|
| 数据模型 | ✅ | Book + BookPage 模型无需修改，完全兼容 |
| 种子数据 | ❌ | seed.js 只到 L1_book_10，需新增 seed_L1_11_20.js |
| API 接口 | ✅ | GET /books/:id 无需修改 |
| 音频文件 | ❌ | 无 L1 11-20 朗读 MP3（01-10 已全量生成）|

### 2.4 前端侧

| 检查项 | 状态 | 详情 |
|--------|:---:|------|
| 阅读器页面 | ✅ | BookReaderPage（700+行），支持任意 bookId |
| 数据仓库 | ✅ | BookReaderRepository.getBookDetail(bookId) |
| 数据模型 | ✅ | BookDetailModel / BookPage / WordAnnotation |
| 插画资源 | ❌ | 无 PNG 可加载（依赖设计交付后部署）|

---

## 三、不需要新接口的原因

### 3.1 绘本 vs 故事：数据结构无差异

```
绘本（01-10）                          故事（11-20）
┌─────────────────┐                  ┌─────────────────┐
│ Book             │                  │ Book             │
│  bookId: L1_01   │                  │  bookId: L1_11   │
│  title: "我的身体"│                  │  title: "数一数"  │
│  level: 1         │                  │  level: 1         │
│  pageCount: 10    │                  │  pageCount: 10    │
│  newWords: [...]  │                  │  newWords: [...]  │
│  pages: [...]     │                  │  pages: [...]     │
└────────┬────────┘                  └────────┬────────┘
         │                                     │
    ┌────▼────┐                          ┌────▼────┐
    │BookPage │                          │BookPage │
    │ pageNum │                          │ pageNum │
    │ text    │                          │ text    │
    │ pinyin  │                          │ pinyin  │
    │ image   │                          │ image   │
    │ annots  │                          │ annots  │
    └─────────┘                          └─────────┘
```

完全同构！唯一的区别是内容来源（绘本→绘本文案、故事→分镜文案），但对 API 和前端来说，都是 Book 对象，处理逻辑一样。

### 3.2 前端 BookReaderPage 已经是通用的

```dart
// book_reader_page.dart
class BookReaderPage extends StatefulWidget {
  final String bookId;  // ← 接受任意 bookId，不区分类型
  final String? childId;

  // ...翻页、新字高亮、进度记录——全部基于 BookDetailModel
}

// book_reader_repository.dart
Future<BookDetailModel?> getBookDetail(String bookId, {String? childId}) async {
  final response = await _api.get('/books/$bookId', ...);
  return BookDetailModel.fromJson(response.data!);
}
```

传入 `L1_book_11` 和传入 `L1_book_01` 走完全相同的代码路径，不需要任何 if/else 分支。

### 3.3 后端 Book model 也没有类型区分

```javascript
// Book.js — 没有 storyType / bookType 字段
bookId / title / level / theme / newWords / pages / exercises
```

所有字段都是 01-10 和 11-20 共用的。

---

## 四、需要做的工作（不是新接口，而是数据导入）

### 🔴 P0 — 后端 seed 脚本

编写 `seed_L1_11_20.js`，从 `插画需求单_L1_第11-20篇.md` 提取每页文案，生成：

```
10 条 Book 记录 (bookId: L1_book_11 ~ L1_book_20)
~105 条 BookPage 记录 (每页含 text/pinyin/新字标注/image空串)
```

**Book 字段映射**：

| 插画需求单字段 | Book 字段 |
|---------------|-----------|
| 故事编号 → | bookId: "L1_book_11" |
| 标题 → | title: "数一数" |
| 主题 → | theme: "认知（数字）" |
| 页数 → | pageCount: 10 |
| 新字数 → | newWordCount: 12 |
| 主角设定 → | protagonist: { name, description } |

**BookPage 字段映射**：

| 插画需求单字段 | BookPage 字段 |
|---------------|---------------|
| 文字内容 → | text: "一个苹果。" |
| 拼音 → | pinyin: "yī gè píng guǒ。" |
| 画面描述 → | imageDescription |
| 新字标注 → | wordAnnotations[{ character, isNewWord }] |

### 🟡 P1 — 插画交付

等待插画师产出 10篇×~10页 ≈ **100张 PNG**，然后：
1. 部署到 `uploads/images/` 
2. 更新 BookPage.image 字段

### 🟡 P1 — 音频生成

插画定稿后，用 edge-tts 生成 ~105页朗读 MP3，部署到 `uploads/audio/books/`

### 🟢 P2 — 练习配置

部分故事已标注"配套练习"，需录入 Book.exercises

---

## 五、与前端的对接时序

```
现在 ──── seed 脚本 → 后端数据就绪 → 前端可加载文案（无图模式）
   │
   ├── 等待插画师 → 100张PNG → 部署 → 完整阅读体验
   │
   └── 等待插画定稿 → 105个MP3 → 部署 → 朗读功能
```

**前端可以在插画到位前就开始接入**——BookReaderPage 有 `image` 为空时的降级展示（纯文本+拼音+新字标注），可以先验证文案+导航流程。

---

## 六、建议与行动项

| # | 行动项 | 负责人 | 优先级 | 阻塞于 |
|:---:|--------|--------|:---:|--------|
| 1 | 编写 seed_L1_11_20.js 数据导入 | 后端 | 🔴 P0 | 无 |
| 2 | L1 11-20 新字关联字符表 | 教研 → 后端 | 🔴 P0 | 无 |
| 3 | 插画制作（100张PNG） | 插画师 | 🟡 P1 | 无 |
| 4 | 音频生成（105个MP3） | 后端 | 🟡 P1 | #3 插画定稿 |
| 5 | 册列表 UI 展示故事封面 | 前端 | 🟢 P2 | #3 插画交付 |
| 6 | BookReaderPage 无图降级验证 | 前端 | 🟢 P2 | #1 seed 数据 |

> **关键风险**：L1 11-20 插画目前 0 张，整个 L3/L4/L5 插画已交付 908 张但 L1 11-20 完全空白。如果上线时需要完整阅读体验，插画是瓶颈。
