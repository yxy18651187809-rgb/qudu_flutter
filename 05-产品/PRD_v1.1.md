# 字趣阅读 PRD v1.1（定稿版）

> **产品名称**：字趣阅读  
> **版本**：v1.1  
> **撰写人**：运营  
> **日期**：2026-05-07  
> **状态**：定稿（评审通过）  
> **适用阶段**：Phase 1.1（学习报告 + 家长监控 + 微信登录 + L2内容）  
> **评审会议纪要**：`05-产品/PRD_v1.1_评审会议纪要.md`

---

## 修订记录

| 版本 | 日期 | 修改内容 | 修改人 |
|------|------|---------|--------|
| v1.1初稿 | 2026-05-03 | 初版，覆盖学习报告+家长监控+微信登录+支付体系+L2内容 | 运营 |
| v1.1定稿 | 2026-05-07 | 支付体系调整为v1.1二期；补充真实API细节；修订上线计划 | team-lead |

---

## 一、版本目标

v1.0 完成了 MVP 核心闭环（登录→建档→测评→绘本→识字）。v1.1 的核心目标是：

1. **家长端能力**：学习报告 + 家长监控，提升家长满意度和留存
2. **登录体验优化**：微信登录，降低注册门槛
3. **内容扩展**：L2第一批10本绘本上线
4. **商业化准备**：支付体系基础架构（v1.1二期上线）

---

## 二、与v1.0对比

| 功能模块 | v1.0 | v1.1 | 说明 |
|---------|-------|------|------|
| 登录方式 | 仅手机号+验证码 | 手机号 + 微信登录 | 降低注册门槛 |
| 学习报告 | ❌ 无 | ✅ 日报/周报/月报 | 家长端核心功能 |
| 家长监控 | ❌ 无 | ✅ 实时状态+阈值告警 | 家长控制能力 |
| 微信登录 | ❌ 无 | ✅ 微信授权+手机号绑定 | P0功能 |
| 支付体系 | ❌ 无 | 🔶 架构就绪，二期上线 | 见v1.1二期说明 |
| 绘本内容 | L1（10本） | L1（10本）+ L2（10本） | 内容扩展 |
| 识字测评 | L1分级 | L1-L2分级 | 配合内容扩展 |
| L2教案 | ❌ 无 | ✅ 第二批20篇启动 | 持续产出中 |

---

## 三、新增功能详细设计

### 3.1 学习报告（新功能，P0）

#### 3.1.1 功能概述

学习报告是家长端核心功能，自动统计孩子的识字学习数据，生成日报/周报/月报，帮助家长了解学习进度。

#### 3.1.2 数据来源（真实统计，非模拟）

| 数据项 | 来源 | 计算方式 |
|--------|------|---------|
| 学习时长 | LearningRecord.duration | 指定周期内所有记录的duration求和 |
| 识字数 | LearningRecord.newWords | 指定周期内所有记录的newWords求和 |
| 阅读绘本数 | LearningRecord（type='book'） | 指定周期内去重统计 |
| 测评次数 | Assessment | 指定周期内计数 |
| 平均准确率 | Assessment.accuracy | 指定周期内accuracy求平均 |
| 识字量趋势 | WordMastery（status='mastered'）+ lastReviewAt | 按日期累计真实掌握汉字数 |
| 准确率趋势 | Assessment | 最近7天每日平均准确率 |
| 复习状态 | WordMastery（nextReviewAt ≤ 今天） | 待复习字数和完成率 |

#### 3.1.3 API接口（后端已实现）

**API 1：获取学习报告**
```
GET /api/v1/learning-report/:childId?period=daily&date=2026-05-07
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{
  "code": 0,
  "data": {
    "childId": "680abc...",
    "childName": "小明",
    "period": "daily",
    "date": "2026-05-07",
    "statistics": {
      "studyTime": 25,
      "charactersLearned": 8,
      "booksRead": 2,
      "assessmentCount": 1,
      "averageAccuracy": 85
    },
    "progress": {
      "totalCharacters": 86,
      "level": 2,
      "nextLevelCharacters": 34
    },
    "trends": {
      "accuracy": [
        {"date": "2026-05-01", "accuracy": 78},
        {"date": "2026-05-02", "accuracy": 82},
        ...（最近7天）
      ],
      "characters": [
        {"date": "2026-05-01", "count": 70},
        {"date": "2026-05-02", "count": 75},
        ...（最近30天）
      ]
    },
    "review": {
      "due": 5,
      "completed": 3,
      "rate": 60
    }
  },
  "message": "success"
}
```

**API 2：获取学习报告列表（家长视角）**
```
GET /api/v1/learning-report/parent/:parentId?period=daily
Authorization: Bearer <accessToken>
```

**API 3：生成学习报告（手动触发）**
```
POST /api/v1/learning-report/:childId/generate
Body: { "date": "2026-05-07", "period": "daily" }
```

**API 4：获取识字量趋势**
```
GET /api/v1/learning-report/:childId/characters-trend?days=30
Authorization: Bearer <accessToken>
```

#### 3.1.4 前端页面设计

**入口**：Tab3「我的」→「学习报告」

**页面结构**：
```
学习报告页
├── 顶部：孩子选择器（多孩切换）
├── 周期切换：日报 | 周报 | 月报
├── 核心指标卡片：
│   ├── 学习时长（分钟）
│   ├── 识字数（个）
│   ├── 阅读绘本（本）
│   └── 平均准确率（%）
├── 识字量趋势图（折线图，最近30天）
├── 准确率趋势图（柱状图，最近7天）
├── 复习状态：
│   ├── 待复习 X 个字
│   └── 完成率 X%
└── 底部：「查看详情」按钮
```

**交互规则**：
- 周期切换即时刷新数据（不重新生成报告，直接查DB）
- 识字量趋势图支持点击某天查看当日掌握的具体汉字列表
- 复习状态点击跳转生字本「待复习」Tab
- v1.1暂不支持报告分享海报（v1.1二期实现）

---

### 3.2 家长监控中心（新功能，P0）

#### 3.2.1 功能概述

家长监控中心让家长实时了解孩子的学习状态，可配置学习时长阈值、识字数阈值、准确率阈值，超标时触发告警。

#### 3.2.2 告警阈值（可配置）

| 阈值项 | 默认值 | 范围 | 说明 |
|--------|--------|------|------|
| 每日最长学习时长 | 60分钟 | 0-480分钟 | 超过则告警（防止沉迷） |
| 每日最短学习时长 | 15分钟 | 0-120分钟 | 低于则告警（督促学习） |
| 每日最少识字数 | 5个 | 0-50个 | 低于则告警 |
| 最低准确率 | 70% | 0-100% | 低于则告警 |
| 最长复习延迟天数 | 3天 | 0-30天 | 超过则告警 |

#### 3.2.3 API接口（后端已实现）

**API 5：获取监控概览（所有孩子）**
```
GET /api/v1/parent-monitoring/:parentId
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{
  "code": 0,
  "data": {
    "parentId": "680xyz...",
    "children": [
      {
        "childId": "680abc...",
        "childName": "小明",
        "avatarUrl": "https://cdn.ziqu.com/avatars/child1.png",
        "today": {
          "studyTime": 25,
          "maxStudyTime": 60,
          "charactersLearned": 8,
          "minCharacters": 5,
          "accuracy": 85,
          "minAccuracy": 70
        },
        "alerts": [
          {
            "type": "study_time_insufficient",
            "message": "今日学习时长不足15分钟",
            "severity": "warning"
          }
        ]
      }
    ]
  },
  "message": "success"
}
```

**API 6：获取单个孩子监控详情**
```
GET /api/v1/parent-monitoring/:parentId/child/:childId
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{
  "code": 0,
  "data": {
    "childId": "680abc...",
    "childName": "小明",
    "thresholds": {
      "maxDailyStudyTime": 60,
      "minDailyStudyTime": 15,
      "minCharactersPerDay": 5,
      "minAccuracy": 70,
      "maxReviewDelayDays": 3
    },
    "today": {
      "studyTime": 25,
      "charactersLearned": 8,
      "accuracy": 85,
      "reviewDue": 5
    },
    "weekly": {
      "averageStudyTime": 28,
      "averageCharacters": 7.5,
      "averageAccuracy": 82,
      "reviewCompletionRate": 75
    },
    "alertSettings": {
      "enableStudyTimeAlert": true,
      "enableAccuracyAlert": true,
      "enableReviewAlert": true,
      "alertMethods": ["push", "wechat"]
    }
  },
  "message": "success"
}
```

**API 7：更新监控阈值**
```
PUT /api/v1/parent-monitoring/:parentId/child/:childId/thresholds
Authorization: Bearer <accessToken>
Body: {
  "maxDailyStudyTime": 90,
  "minDailyStudyTime": 20,
  "minCharactersPerDay": 8,
  "minAccuracy": 75,
  "maxReviewDelayDays": 2
}
```

**API 8：更新告警设置**
```
PUT /api/v1/parent-monitoring/:parentId/alert-settings
Authorization: Bearer <accessToken>
Body: {
  "enableStudyTimeAlert": true,
  "enableAccuracyAlert": true,
  "enableReviewAlert": false,
  "alertMethods": ["push"]
}
```

#### 3.2.4 前端页面设计

**入口**：Tab3「我的」→「家长监控」

**页面结构**：
```
家长监控页
├── 顶部：孩子选择器（多孩切换）
├── 今日概览卡片：
│   ├── 学习时长：25/60 分钟（进度条）
│   ├── 识字数：8/5 个（进度条）
│   ├── 准确率：85%（显示，无阈值对比）
│   └── 待复习：5 个字
├── 本周平均卡片：
│   ├── 日均学习时长：28分钟
│   ├── 日均识字数：7.5个
│   ├── 平均准确率：82%
│   └── 复习完成率：75%
├── 告警列表：
│   ├── ⚠️ 今日学习时长不足15分钟
│   └── ℹ️ 有5个汉字需要复习
└── 设置入口：「监控阈值设置」
```

**阈值设置页**：
```
监控阈值设置页
├── 每日最长学习时长：[60] 分钟（滑块，0-480）
├── 每日最短学习时长：[15] 分钟（滑块，0-120）
├── 每日最少识字数：[5] 个（滑块，0-50）
├── 最低准确率：[70] %（滑块，0-100%）
├── 最长复习延迟：[3] 天（滑块，0-30）
└── 告警方式：
    ├── ✅ Push通知
    ├── ✅ 微信提醒
    └── ☐ 短信提醒（v1.1未实现）
```

---

### 3.3 微信登录（新功能，P0）

#### 3.3.1 功能概述

支持用户通过微信授权快速登录，降低注册门槛。首次微信登录需绑定手机号（用于账号找回和微信解绑场景）。

#### 3.3.2 流程图

```
打开APP → 登录页点击「微信登录」
   → 跳转微信授权（获取code）
   → 后端验证code，获取unionid
   → 判断：该微信是否已绑定账号？
      ├── 已绑定 → 直接登录（返回Token）
      └── 未绑定 → 引导绑定手机号
           → 该手机号已有账号？
              ├── 是 → 合并账号（微信绑定到已有账号）
              └── 否 → 创建新账号 + 绑定微信
   → 登录成功 → 跳转首页
```

#### 3.3.3 后端API

**API：微信登录**
```
POST /api/v1/auth/wechat/login
Body: { "code": "081xyz..." }
```

**Response 200（已绑定）:**
```json
{
  "code": 0,
  "data": {
    "isNewUser": false,
    "accessToken": "eyJhbG...",
    "refreshToken": "dGhpcy...",
    "expiresIn": 7200,
    "user": {
      "id": "680abc...",
      "phone": "138****8000",
      "nickname": "小明妈妈",
      "avatar": "https://thirdwx.qlogo.cn/...",
      "hasChildren": true,
      "childrenCount": 1
    }
  },
  "message": "success"
}
```

**Response 200（未绑定，需前端引导绑定手机号）:**
```json
{
  "code": 0,
  "data": {
    "isNewUser": true,
    "needBindPhone": true,
    "wechatTempToken": "temp_token_xyz...",
    "user": {
      "id": "",
      "phone": "",
      "nickname": "",
      "avatar": "https://thirdwx.qlogo.cn/...",
      "hasChildren": false,
      "childrenCount": 0
    }
  },
  "message": "success"
}
```

#### 3.3.4 前端实现（已完成Task #25）

- `fluwx: ^4.5.0` 已加入 `pubspec.yaml`
- `WechatAuthService` 已封装微信SDK调用
- 登录页已添加微信登录按钮
- 微信登录后引导绑定手机号的UI已就绪

#### 3.3.5 业务规则

- 一个微信（unionid）只能绑定一个账号
- 解绑微信需在「设置」中操作，需验证手机号
- 微信登录与手机号登录可并存（一个账号可同时用两种方式登录）
- 微信登录的 `accessToken` 有效期同样为2小时，`refreshToken` 7天

#### 3.3.6 风险

| 风险 | 影响 | 概率 | 应对 |
|------|------|------|------|
| 微信开放平台审核周期长（3-7天） | 微信登录延迟上线 | 中 | 提前2周提交审核；备用方案：v1.1先用手机号登录 |
| 微信API变更 | 登录失败 | 低 | 关注微信开放平台公告，及时更新SDK |

---

### 3.4 L2内容扩展（新内容，P0）

#### 3.4.1 范围

| 批次 | 级别 | 数量 | 上线时间 | 状态 |
|--------|------|------|---------|------|
| 第一批 | L2 | 10本 | 5/17 | 🔶 进行中 |
| 第二批 | L2 | 10本 | 5/31 | 🔶 进行中 |
| 第三批 | L3 | 20本 | Phase 1.2 | 🔲 待启动 |

#### 3.4.2 前端适配

- 书架页已支持按级别筛选L1-L5
- L2绘本与L1绘本体例一致（封面图、内页、新字列表）
- 阅读器无需修改（通用渲染L1-L5）

#### 3.4.3 后端seed数据

- `seed_L2_books.js` 已创建（Task #26），包含20本L2绘本框架
- 教研员完成教案后，填充新字列表，后端执行seed
- 状态初始为 `draft`，填充后改为 `published`

---

### 3.5 支付体系（v1.1二期，P1）

> **说明**：支付体系原纳入v1.1核心，经5/7评审会议决定，调整为v1.1二期（5/25公测版上线），降低v1.1核心上线风险。

#### 3.5.1 VIP会员方案（草案，供v1.1二期参考）

| 会员类型 | 价格 | 权益 |
|---------|------|------|
| 月卡 | ¥18/月 | 解锁当月新绘本20本 |
| 季卡 | ¥48/季 | 解锁当季新绘本60本 |
| 年卡 | ¥168/年 | 解锁全部绘本 + 学习报告高级版 |

#### 3.5.2 对v1.1核心的影响

- v1.1核心（5/17）上线时，所有绘本暂时免费开放（L1 10本 + L2 10本）
- 支付体系上线后（5/25），L2绘本品设为VIP专属
- 学习报告高级版（同龄对比+薄弱项分析）随支付体系一起上线

---

## 四、用户流程更新

### 4.1 家长端新流程

```
打开APP → 底部Tab「我的」→ 点击「学习报告」
    → 选择周期（日报/周报/月报）
    → 查看数据 + 趋势图
    → v1.1二期：点击「分享」→ 生成海报 → 分享到微信
```

### 4.2 微信登录新流程

```
打开APP → 登录页点击「微信登录」
    → 跳转到微信授权
    → 首次使用：引导绑定手机号 + 创建儿童档案
    → 非首次：直接登录进入首页
```

### 4.3 家长监控新流程

```
打开APP → 底部Tab「我的」→ 点击「家长监控」
    → 查看今日概览 + 本周平均
    → 点击「监控阈值设置」
    → 调整阈值 + 告警方式
    → 保存（调用API 7/8）
```

---

## 五、前端开发任务分配

| 页面 | 对应API | 负责人 | 截止时间 | 状态 |
|------|---------|--------|---------|------|
| 学习报告页 | API 1/3/4 | 前端负责人 | 5/12 | 🔶 进行中（Task #30） |
| 家长监控页 | API 5/6 | 前端负责人 | 5/14 | 🔶 待启动 |
| 监控阈值设置页 | API 7/8 | 前端负责人 | 5/14 | 🔶 待启动 |
| 微信登录按钮+逻辑 | 微信SDK + API | 前端负责人 | 已完成（Task #25） | ✅ |
| L2书架适配 | 无（现有功能已支持） | — | — | ✅ |

---

## 六、后端开发任务分配

| API/功能 | 负责人 | 截止时间 | 状态 |
|---------|--------|---------|------|
| 学习报告4个API | 后端负责人 | 已完成（Task #24） | ✅ |
| 家长监控4个API | 后端负责人 | 已完成 | ✅ |
| 微信登录API | 后端负责人 | 5/13 | 🔶 进行中 |
| L2 seed数据执行 | 后端负责人 | 5/13 | 🔶 进行中 |
| 支付体系基础架构 | 后端负责人 | 5/20（v1.1二期） | 🔲 待启动 |

---

## 七、非功能需求（v1.1新增）

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 学习报告生成 | < 3秒 | 基于已有数据聚合，非实时计算 |
| 监控告警延迟 | < 10秒 | 前端轮询或WebSocket推送 |
| 微信登录授权 | < 5秒 | 从点击到获取code |
| L2绘本加载 | < 2秒 | 同L1性能标准 |

---

## 八、上线计划（修订后）

| 阶段 | 时间 | 内容 | 状态 |
|------|------|------|------|
| v1.1 核心内测 | 5/13-5/16 | 学习报告+家长监控+微信登录（限50用户） | 🔶 进行中 |
| v1.1 核心上线 | 5/17 | L2第一批10本 + 全功能 | 🔶 进行中 |
| v1.1 二期内测 | 5/20-5/24 | 支付体系 + VIP权益（限100用户） | 🔲 待启动 |
| v1.1 二期上线 | 5/25 | 支付体系 + 报告分享海报 | 🔲 待启动 |

---

## 九、验收标准（v1.1核心）

| 功能 | 验收标准 |
|------|---------|
| 学习报告 | 日报/周报/月报生成成功率100%，数据与后端API一致 |
| 家长监控 | 阈值配置保存成功率100%，告警触发准确率100% |
| 微信登录 | 授权成功率 ≥ 99%，绑定手机号成功率 ≥ 95% |
| L2内容 | 第一批10本绘本全部可在APP内阅读，新字高亮正常 |
| 性能 | 学习报告页加载 < 3秒，监控页加载 < 2秒 |

---

## 十、风险登记（v1.1）

| 风险ID | 描述 | 影响 | 概率 | 应对 | 负责人 |
|--------|------|------|------|------|--------|
| R009 | 微信开放平台审核延迟 | 微信登录无法按时上线 | 中 | 提前2周提交审核；备用：v1.1先用手机号登录 | 运营 |
| R010 | L2新字填充延迟 | seed数据无法按时导入 | 低 | seed框架已就绪，教研员只需填充新字列表 | 教研员 |
| R011 | 插画师绘本06-10上色延迟 | L2绘本无插图 | 中 | 先用占位图上线，上色完成后热更新 | 插画师 |
| R012 | fl_chart图表性能问题 | 学习报告页卡顿 | 低 | 限制趋势数据点为30天 | 前端负责人 |

---

## 十一、附录：API速查表

| API | 方法 | 路径 | 说明 |
|-----|------|------|------|
| 1 | GET | `/api/v1/learning-report/:childId` | 获取学习报告 |
| 2 | GET | `/api/v1/learning-report/parent/:parentId` | 获取学习报告列表（家长视角） |
| 3 | POST | `/api/v1/learning-report/:childId/generate` | 手动生成学习报告 |
| 4 | GET | `/api/v1/learning-report/:childId/characters-trend` | 获取识字量趋势 |
| 5 | GET | `/api/v1/parent-monitoring/:parentId` | 获取监控概览 |
| 6 | GET | `/api/v1/parent-monitoring/:parentId/child/:childId` | 获取孩子监控详情 |
| 7 | PUT | `/api/v1/parent-monitoring/:parentId/child/:childId/thresholds` | 更新监控阈值 |
| 8 | PUT | `/api/v1/parent-monitoring/:parentId/alert-settings` | 更新告警设置 |
| 9 | POST | `/api/v1/auth/wechat/login` | 微信登录（待后端实现） |

> 完整API契约文档：`03-后端/API契约文档_v1.md`（持续更新）

---

*文档版本：v1.1定稿版*  
*撰写日期：2026-05-03（初稿）/ 2026-05-07（定稿）*  
*审核状态：✅ 已通过评审（2026-05-07）*  
*归档路径：`05-产品/PRD_v1.1.md`*
