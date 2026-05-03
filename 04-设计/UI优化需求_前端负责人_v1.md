# UI优化需求 - 前端负责人反馈

**日期**：2026-05-02  
**反馈人**：前端负责人  
**优先级**：P0（影响用户体验和上架审核）

---

## 当前问题清单

### 1. 品牌视觉缺失（P0）
**问题**：
- 登录页Logo使用Material Design图标（`Icons.auto_stories_rounded`）作为占位
- 首页顶部头像使用相同图标占位
- 缺少品牌IP形象"趣趣"

**影响**：
- 用户无法建立品牌认知
- App看起来像Demo而非正式产品
- 儿童用户缺少情感连接

**需求**：
- 使用插画师已完成的"趣趣IP形象"替换所有占位图标
- 登录页Logo区域使用正式App图标（已设计完成）
- 首页头像区域使用趣趣表情（根据时间/场景变化）

---

### 2. 图标系统不统一（P1）
**问题**：
- 快速入口卡片使用Material Design图标
- 底部导航栏使用Material Design图标
- 统计区域使用Material Design图标

**影响**：
- 风格不统一，看起来像通用模板
- 缺少儿童友好性（Material图标偏商务）

**需求**：
- 为所有图标设计/提供自定义图标资源
- 或使用插画师提供的图标集
- 确保图标风格一致（圆润、鲜艳、儿童友好）

---

### 3. 色彩搭配偏成熟（P1）
**问题**：
- 当前使用Material Design默认配色
- 缺少针对5-12岁儿童的活泼配色

**影响**：
- 对儿童吸引力不足
- 与竞品（洪恩、悟空）相比缺乏活力

**需求**：
- 根据设计稿v1规范调整配色
- 增加渐变、阴影等视觉层次
- 使用更鲜艳的辅助色

---

### 4. 插画和装饰元素缺失（P1）
**问题**：
- 页面以文字和简单图形为主
- 缺少情景插画和装饰元素

**影响**：
- 页面显得单调
- 不符合儿童App的视觉习惯

**需求**：
- 登录页背景添加情景插画
- 空状态页面添加趣趣引导插画
- 按钮、卡片等添加装饰元素

---

### 5. 绘本封面图缺失（P0）
**问题**：
- 书架页显示绘本列表，但封面图是占位符
- 用户无法直观选择想读的绘本

**影响**：
- 核心功能（绘本阅读）无法正常展示
- 影响用户决策和点击率

**需求**：
- 优先提供绘本01-10的封面图
- 格式：png，宽高比3:4，分辨率至少300×400
- 命名规范：`book_cover_01.png`（对应绘本01）

---

## 急需交付的资源清单

### 品牌资源（P0）
- [ ] App图标（已设计，需导出png）→ `assets/icons/app_icon.png`
- [ ] 趣趣IP形象（已设计）→ `assets/images/ququ_normal.png`
- [ ] 趣趣10种表情（已设计）→ `assets/images/ququ_[happy/thinking/encourage/cheer/surprise/sleep/sad/confused/angry].png`

### 界面图标（P1）
- [ ] 底部导航栏图标（4个Tab）× 2状态（普通/选中）→ `assets/icons/tab_*.png`
- [ ] 快速入口图标（继续阅读/今日识字/汉字测评/每日挑战）→ `assets/icons/action_*.png`
- [ ] 功能图标（设置/通知/帮助）→ `assets/icons/func_*.png`

### 绘本封面（P0）
- [ ] 绘本01《我的身体》→ `assets/images/book_covers/book_01.png`
- [ ] 绘本02《早上好》→ `assets/images/book_covers/book_02.png`
- [ ] 绘本03-10（按计划交付）

### 情景插画（P1）
- [ ] 登录页背景插画 → `assets/images/illustrations/login_bg.png`
- [ ] 空状态插画（无孩子档案）→ `assets/images/illustrations/empty_child.png`
- [ ] 空状态插画（无学习记录）→ `assets/images/illustrations/empty_study.png`
- [ ] 完成挑战插画 → `assets/images/illustrations/challenge_done.png`

---

## 技术方案

### 资源目录结构
```
qudu_flutter/assets/
├── icons/              # 图标（App图标、Tab图标、功能图标）
├── images/
│   ├── ququ/          # 趣趣IP形象和表情
│   ├── book_covers/   # 绘本封面
│   ├── illustrations/  # 情景插画
│   └── placeholders/  # 占位图
└── audio/              # 音频文件
```

### 集成步骤
1. 插画师提供资源 → 前端放入对应目录
2. 更新 `pubspec.yaml` 声明资源路径
3. 替换代码中的占位Icon
4. 自测 + 提交PR

---

## 时间计划

| 任务 | 负责人 | 预计完成时间 | 状态 |
|------|---------|--------------|------|
| 品牌资源交付 | 插画师 | 2026-05-03 | ⏳ 待开始 |
| 绘本封面01-06 | 插画师 | 2026-05-05 | ⏳ 待开始 |
| 界面图标设计 | 插画师 | 2026-05-07 | ⏳ 待开始 |
| 前端集成 | 前端负责人 | 2026-05-08 | ⏳ 待开始 |
| 自测 + 提交PR | 前端负责人 | 2026-05-09 | ⏳ 待开始 |

---

## 附录：当前UI代码位置

### 登录页
- 文件：`lib/presentation/pages/login/login_page.dart`
- 占位位置：
  - 第174-186行：Logo区域（Container + Icon）
  - 第228-271行：协议勾选区域

### 首页
- 文件：`lib/presentation/pages/home/home_page.dart`
- 占位位置：
  - 第99-112行：头像区域（Container + Icon）
  - 第188-196行：快速入口卡片（_ActionCard）
  - 第279-306行：连续学习打卡（_MyWidget）

### 书架页
- 文件：`lib/presentation/pages/bookshelf/bookshelf_page.dart`
- 占位位置：绘本封面图

---

**请联系前端负责人讨论详细设计方案。**
