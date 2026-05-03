# API契约文档 v1.1 · 学习报告 + 家长监控

> **文档状态**：草案  
> **编写人**：后端负责人  
> **编写日期**：2026-05-03  
> **对应计划**：Week 1（5/7-5/8）v1.1 API 规划  

---

## 一、版本说明

| 字段 | 说明 |
|------|------|
| 版本 | v1.1 |
| 新增 API | 8个（学习报告×4 + 家长监控×4） |
| 修改 API | 0个 |
| 废弃 API | 0个 |
| 兼容 v1.0 | ✅ 完全兼容 |

---

## 二、学习报告 API

### 2.1 业务背景

家长需要了解孩子的学习进度和效果，学习报告提供：
- 今日/本周/本月学习统计
- 识字量增长趋势
- 测评准确率变化
- 复习及时率

### 2.2 数据模型

#### LearningReport Collection（新增）

```javascript
const LearningReportSchema = new Schema({
  childId: { type: ObjectId, ref: 'Child', required: true },
  date: { type: Date, required: true },           // 报告日期
  period: { type: String, enum: ['daily', 'weekly', 'monthly'] },
  
  // 学习统计
  studyTime: Number,          // 学习时长（分钟）
  charactersLearned: Number,   // 新学汉字数
  booksRead: Number,          // 阅读绘本数
  assessmentCount: Number,   // 测评次数
  
  // 准确率统计
  averageAccuracy: Number,    // 平均准确率（0-100）
  accuracyTrend: [            // 准确率趋势（最近7天）
    { date: Date, accuracy: Number }
  ],
  
  // 识字量统计
  totalCharacters: Number,   // 累计识字量
  charactersTrend: [          // 识字量趋势（最近30天）
    { date: Date, count: Number }
  ],
  
  // 复习统计
  reviewDue: Number,          // 待复习字数
  reviewCompleted: Number,   // 已完成复习字数
  reviewRate: Number,        // 复习及时率（0-100）
  
  createdAt: { type: Date, default: Date.now },
});

LearningReportSchema.index({ childId: 1, date: 1, period: 1 }, { unique: true });
```

### 2.3 API 接口

---

#### API 1：获取学习报告

**GET** `/api/v1/learning-report/:childId`

**描述**：获取指定孩子的学习报告（支持日/周/月维度）

**鉴权**：需要（家长或老师）

**Query 参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period` | String | 否 | `daily`(默认) / `weekly` / `monthly` |
| `date` | String | 否 | 报告日期（YYYY-MM-DD），默认今天 |
| `days` | Number | 否 | 趋势数据天数（默认7） |

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "childId": "507f1f77bcf86cd799439011",
    "childName": "小明",
    "period": "daily",
    "date": "2026-05-03",
    "statistics": {
      "studyTime": 25,
      "charactersLearned": 5,
      "booksRead": 2,
      "assessmentCount": 1,
      "averageAccuracy": 85
    },
    "progress": {
      "totalCharacters": 120,
      "level": 2,
      "nextLevelCharacters": 80
    },
    "trends": {
      "accuracy": [
        { "date": "2026-04-27", "accuracy": 78 },
        { "date": "2026-04-28", "accuracy": 82 },
        { "date": "2026-04-29", "accuracy": 85 },
        { "date": "2026-04-30", "accuracy": 80 },
        { "date": "2026-05-01", "accuracy": 88 },
        { "date": "2026-05-02", "accuracy": 83 },
        { "date": "2026-05-03", "accuracy": 85 }
      ],
      "characters": [
        { "date": "2026-04-03", "count": 20 },
        { "date": "2026-04-10", "count": 45 },
        { "date": "2026-04-17", "count": 75 },
        { "date": "2026-04-24", "count": 100 },
        { "date": "2026-05-01", "count": 120 }
      ]
    },
    "review": {
      "due": 8,
      "completed": 6,
      "rate": 75
    }
  }
}
```

**响应示例（失败）**：
```json
{
  "success": false,
  "code": "CHILD_NOT_FOUND",
  "message": "孩子不存在或无权访问"
}
```

---

#### API 2：获取学习报告列表（家长视角）

**GET** `/api/v1/learning-report/parent/:parentId`

**描述**：获取某家长所有孩子的学习报告汇总

**鉴权**：需要（仅本人）

**Query 参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period` | String | 否 | `daily`(默认) / `weekly` |
| `date` | String | 否 | 报告日期，默认今天 |

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "date": "2026-05-03",
    "period": "daily",
    "children": [
      {
        "childId": "507f1f77bcf86cd799439011",
        "childName": "小明",
        "avatarUrl": "https://...",
        "statistics": {
          "studyTime": 25,
          "charactersLearned": 5,
          "averageAccuracy": 85,
          "totalCharacters": 120
        },
        "alerts": [
          { "type": "review_due", "message": "有8个汉字需要复习" }
        ]
      },
      {
        "childId": "507f1f77bcf86cd799439012",
        "childName": "小红",
        "avatarUrl": "https://...",
        "statistics": {
          "studyTime": 30,
          "charactersLearned": 6,
          "averageAccuracy": 90,
          "totalCharacters": 150
        },
        "alerts": []
      }
    ]
  }
}
```

---

#### API 3：生成学习报告（手动触发）

**POST** `/api/v1/learning-report/:childId/generate`

**描述**：手动触发生成指定日期的学习报告（通常用于后台定时任务）

**鉴权**：需要（管理员或系统）

**请求体**：
```json
{
  "date": "2026-05-03",
  "period": "daily"
}
```

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "reportId": "507f1f77bcf86cd799439020",
    "message": "学习报告已生成"
  }
}
```

---

#### API 4：获取识字量趋势（简化版）

**GET** `/api/v1/learning-report/:childId/characters-trend`

**描述**：仅获取识字量趋势数据（用于首页图表）

**鉴权**：需要

**Query 参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `days` | Number | 否 | 天数（默认30） |

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "childId": "507f1f77bcf86cd799439011",
    "totalCharacters": 120,
    "trend": [
      { "date": "2026-04-03", "count": 20 },
      { "date": "2026-04-10", "count": 45 },
      { "date": "2026-04-17", "count": 75 },
      { "date": "2026-04-24", "count": 100 },
      { "date": "2026-05-01", "count": 120 }
    ]
  }
}
```

---

## 三、家长监控 API

### 3.1 业务背景

家长需要监控孩子的学习行为和进度，包括：
- 学习时长监控（防止过度使用）
- 识字进度监控（是否跟上计划）
- 测评表现监控（准确率是否达标）
- 自定义阈值和提醒

### 3.2 数据模型

#### ParentMonitoring Collection（新增）

```javascript
const ParentMonitoringSchema = new Schema({
  parentId: { type: ObjectId, ref: 'User', required: true },
  childId: { type: ObjectId, ref: 'Child', required: true },
  
  // 监控阈值设置
  thresholds: {
    maxDailyStudyTime: { type: Number, default: 60 },     // 每日最长学习时长（分钟）
    minDailyStudyTime: { type: Number, default: 15 },     // 每日最短学习时长（分钟）
    minCharactersPerDay: { type: Number, default: 3 },    // 每日最少识字数
    minAccuracy: { type: Number, default: 70 },          // 最低测评准确率（0-100）
    maxReviewDelayDays: { type: Number, default: 2 },    // 最长复习延迟天数
  },
  
  // 当前监控状态
  status: {
    dailyStudyTime: Number,         // 今日已学习时长
    dailyCharactersLearned: Number,  // 今日已学字数
    weeklyAccuracy: Number,        // 本周平均准确率
    reviewDueCount: Number,         // 待复习字数
    lastAlertSentAt: Date,         // 最后告警发送时间
  },
  
  // 告警设置
  alertSettings: {
    enableStudyTimeAlert: { type: Boolean, default: true },
    enableAccuracyAlert: { type: Boolean, default: true },
    enableReviewAlert: { type: Boolean, default: true },
    alertMethods: [{ type: String, enum: ['push', 'sms', 'wechat'] }],
  },
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

ParentMonitoringSchema.index({ parentId: 1, childId: 1 }, { unique: true });
```

### 3.3 API 接口

---

#### API 5：获取监控概览

**GET** `/api/v1/parent-monitoring/:parentId`

**描述**：获取某家长所有孩子的监控概览

**鉴权**：需要（仅本人）

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "parentId": "507f1f77bcf86cd799439005",
    "children": [
      {
        "childId": "507f1f77bcf86cd799439011",
        "childName": "小明",
        "avatarUrl": "https://...",
        "today": {
          "studyTime": 25,
          "maxStudyTime": 60,
          "charactersLearned": 5,
          "minCharacters": 3,
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
  }
}
```

---

#### API 6：获取单个孩子的监控详情

**GET** `/api/v1/parent-monitoring/:parentId/child/:childId`

**描述**：获取单个孩子的详细监控数据

**鉴权**：需要（仅本人）

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "childId": "507f1f77bcf86cd799439011",
    "childName": "小明",
    "thresholds": {
      "maxDailyStudyTime": 60,
      "minDailyStudyTime": 15,
      "minCharactersPerDay": 3,
      "minAccuracy": 70,
      "maxReviewDelayDays": 2
    },
    "today": {
      "studyTime": 25,
      "charactersLearned": 5,
      "accuracy": 85,
      "reviewDue": 8
    },
    "weekly": {
      "averageStudyTime": 28,
      "averageCharacters": 4.5,
      "averageAccuracy": 83,
      "reviewCompletionRate": 75
    },
    "alertSettings": {
      "enableStudyTimeAlert": true,
      "enableAccuracyAlert": true,
      "enableReviewAlert": true,
      "alertMethods": ["push", "wechat"]
    }
  }
}
```

---

#### API 7：更新监控阈值

**PUT** `/api/v1/parent-monitoring/:parentId/child/:childId/thresholds`

**描述**：更新监控阈值设置

**鉴权**：需要（仅本人）

**请求体**：
```json
{
  "maxDailyStudyTime": 90,
  "minDailyStudyTime": 20,
  "minCharactersPerDay": 5,
  "minAccuracy": 75,
  "maxReviewDelayDays": 3
}
```

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "message": "监控阈值已更新"
  }
}
```

---

#### API 8：更新告警设置

**PUT** `/api/v1/parent-monitoring/:parentId/alert-settings`

**描述**：更新告警方式设置（应用到所有孩子）

**鉴权**：需要（仅本人）

**请求体**：
```json
{
  "enableStudyTimeAlert": true,
  "enableAccuracyAlert": true,
  "enableReviewAlert": false,
  "alertMethods": ["push", "wechat"]
}
```

**响应示例（成功）**：
```json
{
  "success": true,
  "data": {
    "message": "告警设置已更新"
  }
}
```

---

## 四、错误码定义（v1.1新增）

| 错误码 | HTTP状态码 | 说明 |
|--------|------------|------|
| `CHILD_NOT_FOUND` | 404 | 孩子不存在或无权访问 |
| `REPORT_NOT_FOUND` | 404 | 学习报告不存在 |
| `INVALID_PERIOD` | 400 | 无效的period参数 |
| `MONITORING_NOT_FOUND` | 404 | 监控记录不存在 |
| `INVALID_THRESHOLD` | 400 | 无效的阈值设置 |

---

## 五、前端对接说明

### 5.1 学习报告页

**页面路径**：`lib/presentation/pages/learning_report/`

**需要的API**：
- API 1：获取学习报告（首页展示）
- API 4：获取识字量趋势（图表）

**注意**：
- `period=daily` 返回今日数据
- `period=weekly` 返回本周数据
- `period=monthly` 返回本月数据

### 5.2 家长监控页

**页面路径**：`lib/presentation/pages/parent_monitoring/`

**需要的API**：
- API 5：获取监控概览（首页列表）
- API 6：获取单个孩子详情（设置页）
- API 7：更新阈值（设置页）
- API 8：更新告警设置（设置页）

---

## 六、后端开发计划

| 任务 | 负责人 | 预计时间 | 状态 |
|------|--------|----------|------|
| LearningReport Model + Schema | 后端 | 1h | ⏳ 待开始 |
| LearningReport Service（统计逻辑） | 后端 | 3h | ⏳ 待开始 |
| LearningReport Controller | 后端 | 2h | ⏳ 待开始 |
| LearningReport Router | 后端 | 1h | ⏳ 待开始 |
| ParentMonitoring Model + Schema | 后端 | 1h | ⏳ 待开始 |
| ParentMonitoring Service（监控逻辑） | 后端 | 3h | ⏳ 待开始 |
| ParentMonitoring Controller | 后端 | 2h | ⏳ 待开始 |
| ParentMonitoring Router | 后端 | 1h | ⏳ 待开始 |
| 集成测试脚本 | 后端 | 2h | ⏳ 待开始 |

**总计**：约16小时，预计5/11-5/12完成。

---

## 七、数据库迁移

### 7.1 创建集合

```javascript
// scripts/create_v11_collections.js
const mongoose = require('./config/db');
const LearningReport = require('../models/LearningReport');
const ParentMonitoring = require('../models/ParentMonitoring');

async function createCollections() {
  await LearningReport.init();  // 创建集合 + 索引
  await ParentMonitoring.init();
  console.log('✅ v1.1 集合创建完成');
}

createCollections();
```

### 7.2 初始化监控记录

```javascript
// 为已有家长-孩子关系创建监控记录
async function initMonitoringRecords() {
  const ParentChild = require('../models/ParentChild');
  const ParentMonitoring = require('../models/ParentMonitoring');
  
  const relations = await ParentChild.find();
  
  for (const rel of relations) {
    await ParentMonitoring.findOneAndUpdate(
      { parentId: rel.parentId, childId: rel.childId },
      { parentId: rel.parentId, childId: rel.childId },
      { upsert: true, new: true }
    );
  }
  
  console.log(`✅ 初始化 ${relations.length} 条监控记录`);
}
```

---

## 八、测试计划

### 8.1 学习报告 API 测试

| 测试场景 | 输入 | 预期输出 |
|----------|------|----------|
| 获取日报 | `period=daily` | 返回今日数据 |
| 获取周报 | `period=weekly` | 返回本周数据 |
| 孩子不存在 | `childId=invalid` | 404 + 错误码 |
| 无权限 | 访问其他家长的孩子 | 403 + 错误码 |

### 8.2 家长监控 API 测试

| 测试场景 | 输入 | 预期输出 |
|----------|------|----------|
| 获取监控概览 | `parentId` | 返回所有孩子监控状态 |
| 更新阈值 | 合法阈值 | 200 + 成功 |
| 更新阈值 | 无效阈值（负数） | 400 + 错误码 |
| 更新告警设置 | 合法设置 | 200 + 成功 |

---

## 九、风险与应对

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| 统计逻辑复杂 | 开发时间超出 | 中 | 先实现基础统计，高级功能Phase 1.2 |
| 数据量增长快 | 查询变慢 | 低 | 加索引，考虑分表 |
| 家长不理解指标 | 功能使用率低 | 中 | 添加指标说明文案 |

---

*文档版本：v1.0（草案）| 编写人：后端负责人 | 日期：2026-05-03*
