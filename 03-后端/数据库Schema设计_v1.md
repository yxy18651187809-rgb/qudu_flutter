# 字趣阅读 - 数据库Schema设计文档

**版本**：v1.0
**日期**：2026-04-20
**作者**：后端负责人
**状态**：初稿，待评审

---

## 一、数据库选型

| 选项 | 方案 | 理由 |
|------|------|------|
| 主数据库 | MongoDB 6.x | 文档型数据库，Schema灵活，适合内容型应用 |
| ODM | Mongoose 7.x | Node.js生态成熟，类型支持好 |
| 索引策略 | 复合索引 + 分片key | 优化查询性能 |

---

## 二、集合设计总览

```
┌─────────────────────────────────────────────────────────────┐
│                        字趣阅读数据库                         │
├─────────────────────────────────────────────────────────────┤
│ users              # 用户表（家长账号）                        │
│ children           # 儿童档案表                              │
│ characters         # 汉字表                                  │
│ books              # 绘本表                                  │
│ book_pages         # 绘本页面表（拆分为独立集合）               │
│ learning_records   # 学习记录表                              │
│ word_mastery       # 汉字掌握度表                             │
│ review_schedules   # 复习计划表（艾宾浩斯）                   │
│ achievements       # 成就定义表                              │
│ child_achievements # 儿童成就记录表                          │
│ orders             # 订单表                                  │
│ vip_subscriptions  # 会员订阅表                              │
│ daily_tasks        # 每日任务表                              │
│ child_tasks        # 儿童任务进度表                           │
│ app_settings       # 应用配置表（系统参数）                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 三、集合详细设计

### 3.1 users - 用户表（家长账号）

```javascript
const userSchema = new mongoose.Schema({
  // ========== 基础信息 ==========
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true
  },
  password: {
    type: String,
    required: true,
    select: false  // 默认不返回
  },
  nickname: {
    type: String,
    trim: true,
    maxlength: 50
  },
  avatar: {
    type: String,
    default: ''  // OSS URL
  },

  // ========== 第三方登录 ==========
  wechatOpenId: {
    type: String,
    sparse: true,
    index: true
  },
  wechatUnionId: {
    type: String,
    sparse: true
  },

  // ========== 账号状态 ==========
  status: {
    type: String,
    enum: ['active', 'banned'],
    default: 'active'
  },
  lastLoginAt: Date,

  // ========== 隐私合规 ==========
  privacyAccepted: {
    type: Boolean,
    default: false
  },
  privacyAcceptedAt: Date,

  // ========== 时间戳 ==========
}, {
  timestamps: true
});

// 复合索引
userSchema.index({ phone: 1, status: 1 });
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/auth/register | 注册 |
| POST | /api/v1/auth/login | 登录 |
| POST | /api/v1/auth/sms/send | 发送验证码 |
| POST | /api/v1/auth/sms/verify | 验证验证码 |
| POST | /api/v1/auth/wechat/login | 微信登录 |
| GET | /api/v1/user/profile | 获取个人信息 |
| PUT | /api/v1/user/profile | 更新个人信息 |

---

### 3.2 children - 儿童档案表

```javascript
const childSchema = new mongoose.Schema({
  // ========== 关联信息 ==========
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // ========== 基础信息 ==========
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 30
  },
  avatar: {
    type: String,
    default: ''
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'unknown'],
    default: 'unknown'
  },
  birthDate: {
    type: Date,
    required: true
  },
  grade: {
    type: Number,
    min: 0,  // 0=学前班
    max: 6   // 6=六年级
  },

  // ========== 学习进度 ==========
  currentLevel: {
    type: Number,
    min: 1,
    max: 5,
    default: 1
  },
 识字量: {
    type: Number,
    default: 0  // 测评确定的识字量
  },
  knownCharacters: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }],

  // ========== 游戏化 ==========
  streakDays: {
    type: Number,
    default: 0  // 连续学习天数
  },
  totalStars: {
    type: Number,
    default: 0  // 总星星数
  },
  totalReadingMinutes: {
    type: Number,
    default: 0  // 总阅读分钟数
  },
  lastLearningAt: Date,

  // ========== VIP状态 ==========
  isVip: {
    type: Boolean,
    default: false
  },
  vipExpireAt: Date,

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['active', 'archived'],
    default: 'active'
  }

}, {
  timestamps: true
});

// 索引
childSchema.index({ userId: 1, status: 1 });
childSchema.index({ currentLevel: 1 });
childSchema.index({ isVip: 1, vipExpireAt: 1 });
```

**计算字段（虚拟字段）**：
```javascript
childSchema.virtual('age').get(function() {
  const today = new Date();
  const birth = this.birthDate;
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
});

childSchema.virtual('knownCharacterCount').get(function() {
  return this.knownCharacters?.length || 0;
});
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/children | 获取儿童列表 |
| POST | /api/v1/children | 创建儿童档案 |
| GET | /api/v1/children/:id | 获取儿童详情 |
| PUT | /api/v1/children/:id | 更新儿童档案 |
| DELETE | /api/v1/children/:id | 删除儿童档案（软删除） |

---

### 3.3 characters - 汉字表

```javascript
const characterSchema = new mongoose.Schema({
  // ========== 汉字核心 ==========
  character: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  unicode: {
    type: String,
    required: true  // 如 "U+4E2D"
  },

  // ========== 拼音与发音 ==========
  pinyin: {
    type: String,
    required: true,
    lowercase: true,
    trim: true  // 如 "zhōng"
  },
  tone: {
    type: Number,
    min: 1,
    max: 5,
    required: true  // 声调 1-4，轻声为5
  },
  audioUrl: {
    type: String,
    default: ''  // TTS生成的音频URL
  },

  // ========== 笔画与结构 ==========
  strokeCount: {
    type: Number,
    min: 1,
    max: 64,
    required: true
  },
  radical: {
    type: String,
    trim: true  // 部首
  },
  structure: {
    type: String,
    enum: ['独体', '左右', '上下', '左中右', '上中下', '半包围', '全包围', '品字'],
    required: true
  },
  strokeOrder: [{
    type: String  // 笔画序列描述
  }],

  // ========== 难度分级 ==========
  level: {
    type: Number,
    min: 1,
    max: 5,
    required: true,
    index: true
  },
  grade: {
    type: Number,
    min: 0,
    max: 6,
    required: true,
    index: true  // 0=学龄前
  },
  frequency: {
    type: Number,
    default: 0  // 使用频率（后续可优化）
  },

  // ========== 释义与例词 ==========
  meanings: [{
    wordClass: String,  // 词性：名词/动词/形容词等
    meaning: String,   // 释义
    examples: [{
      word: String,     // 例词
      sentence: String  // 例句
    }]
  }],

  // ========== 配套资源 ==========
  imageUrl: {
    type: String,
    default: ''  // 汉字配图（象形图）
  },
  animationUrl: {
    type: String,
    default: ''  // 笔顺动画URL
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['active', 'deprecated'],
    default: 'active'
  }

}, {
  timestamps: true
});

// 索引
characterSchema.index({ level: 1, grade: 1 });
characterSchema.index({ pinyin: 1 });
characterSchema.index({ strokeCount: 1 });
characterSchema.index({ character: 'text' });  // 全文搜索
```

**示例文档**：
```javascript
{
  _id: ObjectId("..."),
  character: "日",
  unicode: "U+65E5",
  pinyin: "rì",
  tone: 4,
  audioUrl: "https://cdn.ziqu.com/audio/char_ri.mp3",
  strokeCount: 4,
  radical: "日",
  structure: "独体",
  level: 1,
  grade: 1,
  meanings: [{
    wordClass: "名词",
    meaning: "太阳",
    examples: [
      { word: "日出", sentence: "日出东方" },
      { word: "日日", sentence: "日日是好日" }
    ]
  }],
  imageUrl: "https://cdn.ziqu.com/images/char_ri.png",
  status: "active"
}
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/characters | 获取汉字列表（支持筛选） |
| GET | /api/v1/characters/:id | 获取汉字详情 |
| GET | /api/v1/characters/random | 随机获取N个汉字（用于测评） |

---

### 3.4 books - 绘本表

```javascript
const bookSchema = new mongoose.Schema({
  // ========== 基础信息 ==========
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  cover: {
    type: String,
    required: true  // OSS URL
  },
  description: {
    type: String,
    maxlength: 500
  },

  // ========== 分类 ==========
  level: {
    type: Number,
    min: 1,
    max: 5,
    required: true,
    index: true
  },
  theme: {
    type: String,
    required: true,
    index: true  // 如：动物、自然、家庭、友情等
  },
  tags: [{
    type: String,
    trim: true
  }],

  // ========== 新字配置 ==========
  newCharacters: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }],
  newCharacterCount: {
    type: Number,
    required: true,
    min: 0,
    max: 15
  },

  // ========== 内容配置 ==========
  pageCount: {
    type: Number,
    required: true,
    min: 1
  },
  estimatedMinutes: {
    type: Number,
    default: 5  // 预计阅读时长（分钟）
  },

  // ========== 难度参数 ==========
  vocabularyComplexity: {
    type: Number,
    min: 1,
    max: 5,
    default: 1  // 词汇复杂度
  },
  sentenceLength: {
    type: Number,
    min: 1,
    max: 5,
    default: 1  // 句子长度
  },

  // ========== 付费配置 ==========
  isFree: {
    type: Boolean,
    default: false
  },
  price: {
    type: Number,
    default: 0  // 价格（分），0表示免费
  },

  // ========== 统计数据 ==========
  readCount: {
    type: Number,
    default: 0
  },
  favoriteCount: {
    type: Number,
    default: 0
  },
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 5
  },
  ratingCount: {
    type: Number,
    default: 0
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['draft', 'pending_review', 'approved', 'online', 'offline'],
    default: 'draft'
  },
  publishedAt: Date

}, {
  timestamps: true
});

// 索引
bookSchema.index({ level: 1, status: 1 });
bookSchema.index({ theme: 1, level: 1 });
bookSchema.index({ isFree: 1, status: 1 });
bookSchema.index({ newCharacterCount: 1 });
bookSchema.index({ readCount: -1 });
bookSchema.index({ publishedAt: -1 });

// 文本搜索索引
bookSchema.index({ title: 'text', description: 'text' });
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/books | 获取绘本列表 |
| GET | /api/v1/books/:id | 获取绘本详情（含页面） |
| GET | /api/v1/books/recommended | 智能推荐 |
| GET | /api/v1/books/free | 获取免费绘本 |
| GET | /api/v1/books/themes | 获取主题列表 |

---

### 3.5 book_pages - 绘本页面表

```javascript
const bookPageSchema = new mongoose.Schema({
  bookId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Book',
    required: true,
    index: true
  },
  pageNumber: {
    type: Number,
    required: true,
    min: 1
  },

  // ========== 内容 ==========
  image: {
    type: String,
    required: true  // 插图OSS URL
  },
  text: {
    type: String,
    required: true  // 页面文字
  },

  // ========== 生字标注 ==========
  wordAnnotations: [{
    characterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Character'
    },
    character: String,
    position: {
      start: Number,  // 字符起始位置
      end: Number      // 字符结束位置
    },
    highlightStyle: {
      type: String,
      enum: ['underline', 'color', 'both'],
      default: 'underline'
    }
  }],

  // ========== 音频 ==========
  audioUrl: {
    type: String,
    default: ''  // 整页朗读音频
  },

  // ========== 交互配置 ==========
  interactiveElements: [{
    type: {
      type: String,
      enum: ['tap_sound', 'tap_image', 'animation', 'quiz']
    },
    triggerArea: {
      x: Number,
      y: Number,
      width: Number,
      height: Number
    },
    action: {
      type: String,  // 'play_sound' | 'show_animation' | 'next_page'
      params: mongoose.Schema.Types.Mixed
    }
  }]

}, {
  timestamps: true
});

// 唯一索引：同一绘本的页码唯一
bookPageSchema.index({ bookId: 1, pageNumber: 1 }, { unique: true });
```

**示例文档**：
```javascript
{
  _id: ObjectId("..."),
  bookId: ObjectId("..."),
  pageNumber: 1,
  image: "https://cdn.ziqu.com/books/001/page1.jpg",
  text: "小鸡出壳了！",
  wordAnnotations: [
    {
      characterId: ObjectId("..."),
      character: "鸡",
      position: { start: 1, end: 2 },
      highlightStyle: "underline"
    }
  ],
  audioUrl: "https://cdn.ziqu.com/books/001/page1.mp3",
  interactiveElements: []
}
```

---

### 3.6 learning_records - 学习记录表

```javascript
const learningRecordSchema = new mongoose.Schema({
  // ========== 关联信息 ==========
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },
  bookId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Book',
    sparse: true,
    index: true
  },

  // ========== 学习类型 ==========
  type: {
    type: String,
    required: true,
    enum: ['assessment', 'reading', 'word_study', 'review', 'game'],
    index: true
  },
  subtype: {
    type: String  // 细分类型：如 assessment.word / reading.page
  },

  // ========== 学习内容 ==========
  characters: [{
    characterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Character'
    },
    character: String,
    result: {
      type: String,
      enum: ['correct', 'wrong', 'skipped']
    },
    responseTime: Number  // 响应时间（毫秒）
  }],

  // ========== 结果统计 ==========
  correctCount: {
    type: Number,
    default: 0
  },
  totalCount: {
    type: Number,
    default: 0
  },
  accuracy: {
    type: Number,
    min: 0,
    max: 100,
    default: 0  // 正确率百分比
  },

  // ========== 时间统计 ==========
  duration: {
    type: Number,
    default: 0  // 学习时长（秒）
  },
  startTime: {
    type: Date,
    required: true
  },
  endTime: Date,

  // ========== 奖励 ==========
  starsEarned: {
    type: Number,
    default: 0
  },
  coinsEarned: {
    type: Number,
    default: 0
  }

}, {
  timestamps: true
});

// 索引
learningRecordSchema.index({ childId: 1, type: 1, createdAt: -1 });
learningRecordSchema.index({ childId: 1, createdAt: -1 });
learningRecordSchema.index({ bookId: 1, createdAt: -1 });

// 时间序列优化（按日聚合）
learningRecordSchema.index({ childId: 1, type: 1, 'createdAt': 1 });
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/learning/record | 记录学习数据 |
| GET | /api/v1/learning/history | 学习历史 |
| GET | /api/v1/learning/stats | 学习统计 |

---

### 3.7 word_mastery - 汉字掌握度表

```javascript
const wordMasterySchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },
  characterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character',
    required: true,
    index: true
  },

  // ========== 掌握度评分（0-100） ==========
  masteryScore: {
    type: Number,
    min: 0,
    max: 100,
    default: 0
  },

  // ========== 学习历史 ==========
  totalAttempts: {
    type: Number,
    default: 0  // 总练习次数
  },
  correctAttempts: {
    type: Number,
    default: 0  // 正确次数
  },
  lastAttemptAt: Date,
  lastResult: {
    type: String,
    enum: ['correct', 'wrong', 'skipped']
  },

  // ========== 艾宾浩斯遗忘曲线 ==========
  reviewHistory: [{
    date: Date,
    result: String,       // 'correct' | 'wrong'
    interval: Number,     // 复习间隔（天）
    nextReviewAt: Date    // 下次复习时间
  }],
  currentInterval: {
    type: Number,
    default: 1  // 当前间隔天数
  },
  easeFactor: {
    type: Number,
    default: 2.5  // 难度因子
  },
  nextReviewAt: Date,     // 下次复习时间

  // ========== 学习阶段 ==========
  stage: {
    type: String,
    enum: ['new', 'learning', 'reviewing', 'mastered'],
    default: 'new'
  }

}, {
  timestamps: true
});

// 唯一索引
wordMasterySchema.index({ childId: 1, characterId: 1 }, { unique: true });

// 索引
wordMasterySchema.index({ childId: 1, stage: 1 });
wordMasterySchema.index({ childId: 1, nextReviewAt: 1 });
wordMasterySchema.index({ childId: 1, masteryScore: 1 });
```

**艾宾浩斯算法**（SM-2变体）：
```javascript
// 复习间隔计算
function calculateNextReview(mastery, result) {
  let { currentInterval, easeFactor } = mastery;

  if (result === 'correct') {
    if (currentInterval === 1) {
      currentInterval = 1;
    } else if (currentInterval === 2) {
      currentInterval = 6;
    } else {
      currentInterval = Math.round(currentInterval * easeFactor);
    }
    easeFactor = Math.max(1.3, easeFactor + 0.1);
  } else {
    currentInterval = 1;
    easeFactor = Math.max(1.3, easeFactor - 0.2);
  }

  return {
    nextInterval: currentInterval,
    easeFactor,
    nextReviewAt: addDays(new Date(), currentInterval)
  };
}
```

---

### 3.8 review_schedules - 复习计划表

```javascript
const reviewScheduleSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },

  // ========== 复习内容 ==========
  characters: [{
    characterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Character'
    },
    priority: Number  // 优先级
  }],

  // ========== 计划时间 ==========
  scheduledDate: {
    type: Date,
    required: true,
    index: true
  },
  completed: {
    type: Boolean,
    default: false
  },
  completedAt: Date,
  completedCount: {
    type: Number,
    default: 0
  },

  // ========== 生成规则 ==========
  source: {
    type: String,
    enum: ['auto_schedule', 'manual', 'assessment'],
    default: 'auto_schedule'
  }

}, {
  timestamps: true
});

// 索引
reviewScheduleSchema.index({ childId: 1, scheduledDate: 1 });
reviewScheduleSchema.index({ scheduledDate: 1, completed: 1 });
```

---

### 3.9 achievements - 成就定义表

```javascript
const achievementSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  description: {
    type: String
  },
  icon: {
    type: String
  },

  // ========== 触发条件 ==========
  trigger: {
    type: {
      type: String,
      required: true,
      enum: ['word_count', 'book_count', 'streak_days', 'assessment_score', 'custom']
    },
    config: mongoose.Schema.Types.Mixed  // 触发条件配置
  },

  // ========== 奖励 ==========
  reward: {
    stars: { type: Number, default: 0 },
    coins: { type: Number, default: 0 }
  },

  // ========== 显示配置 ==========
  level: {
    type: String,
    enum: ['bronze', 'silver', 'gold', 'platinum', 'diamond']
  },
  sortOrder: {
    type: Number,
    default: 0
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['active', 'hidden', 'deprecated'],
    default: 'active'
  }
}, {
  timestamps: true
});
```

**预设成就**：
```javascript
// 示例数据
[
  { code: 'FIRST_WORD', name: '一字之师', trigger: { type: 'word_count', count: 1 } },
  { code: 'WORDS_10', name: '十字小将', trigger: { type: 'word_count', count: 10 } },
  { code: 'WORDS_50', name: '五十字达人', trigger: { type: 'word_count', count: 50 } },
  { code: 'WORDS_100', name: '百字小博士', trigger: { type: 'word_count', count: 100 } },
  { code: 'WORDS_500', name: '五百字大师', trigger: { type: 'word_count', count: 500 } },
  { code: 'BOOK_1', name: '初出茅庐', trigger: { type: 'book_count', count: 1 } },
  { code: 'BOOK_10', name: '阅读新星', trigger: { type: 'book_count', count: 10 } },
  { code: 'BOOK_50', name: '阅读达人', trigger: { type: 'book_count', count: 50 } },
  { code: 'STREAK_3', name: '三天打鱼', trigger: { type: 'streak_days', days: 3 } },
  { code: 'STREAK_7', name: '一周坚持', trigger: { type: 'streak_days', days: 7 } },
  { code: 'STREAK_30', name: '一月坚持', trigger: { type: 'streak_days', days: 30 } },
  { code: 'ASSESSMENT_PERFECT', name: '满分测评', trigger: { type: 'assessment_score', score: 100 } }
]
```

---

### 3.10 child_achievements - 儿童成就记录表

```javascript
const childAchievementSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },
  achievementId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Achievement',
    required: true
  },
  achievementCode: {
    type: String,
    required: true
  },

  // ========== 获得信息 ==========
  earnedAt: {
    type: Date,
    required: true,
    default: Date.now
  },
  notified: {
    type: Boolean,
    default: false  // 是否已通知前端
  }

}, {
  timestamps: true
});

// 唯一索引
childAchievementSchema.index({ childId: 1, achievementId: 1 }, { unique: true });

// 索引
childAchievementSchema.index({ childId: 1, earnedAt: -1 });
```

---

### 3.11 orders - 订单表

```javascript
const orderSchema = new mongoose.Schema({
  // ========== 订单标识 ==========
  orderNo: {
    type: String,
    required: true,
    unique: true,
    index: true
  },

  // ========== 用户信息 ==========
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },

  // ========== 商品信息 ==========
  productType: {
    type: String,
    required: true,
    enum: ['vip', 'book', 'package'],
    index: true
  },
  productId: {
    type: mongoose.Schema.Types.Mixed  // 可为ObjectId或自定义ID
  },
  productName: {
    type: String,
    required: true
  },

  // ========== 金额 ==========
  amount: {
    type: Number,
    required: true  // 金额（分）
  },
  discount: {
    type: Number,
    default: 0
  },
  finalAmount: {
    type: Number,
    required: true
  },

  // ========== 支付 ==========
  payChannel: {
    type: String,
    enum: ['wechat', 'alipay'],
    required: true
  },
  payStatus: {
    type: String,
    enum: ['pending', 'paid', 'cancelled', 'refunded'],
    default: 'pending',
    index: true
  },
  paidAt: Date,

  // ========== 回调 ==========
  paymentNo: String,        // 支付渠道订单号
  callbackRaw: mongoose.Schema.Types.Mixed,  // 回调原始数据

  // ========== 超时 ==========
  expireAt: {
    type: Date,
    required: true
  }

}, {
  timestamps: true
});

// 索引
orderSchema.index({ userId: 1, payStatus: 1 });
orderSchema.index({ childId: 1, createdAt: -1 });
orderSchema.index({ payStatus: 1, expireAt: 1 });
```

**API接口**：
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/payment/create | 创建订单 |
| GET | /api/v1/payment/orders | 订单列表 |
| GET | /api/v1/payment/orders/:id | 订单详情 |
| POST | /api/v1/payment/notify | 支付回调 |

---

### 3.12 vip_subscriptions - 会员订阅表

```javascript
const vipSubscriptionSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },

  // ========== 订阅信息 ==========
  level: {
    type: String,
    enum: ['monthly', 'yearly', 'lifetime'],
    required: true
  },
  startAt: {
    type: Date,
    required: true
  },
  endAt: {
    type: Date,
    required: true
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['active', 'expired', 'cancelled'],
    default: 'active'
  },

  // ========== 来源 ==========
  source: {
    type: String,
    enum: ['purchase', 'gift', 'trial', 'refund'],
    default: 'purchase'
  },
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  },

  // ========== 自动续费 ==========
  autoRenew: {
    type: Boolean,
    default: false
  },
  renewFailedCount: {
    type: Number,
    default: 0
  }

}, {
  timestamps: true
});

// 索引
vipSubscriptionSchema.index({ childId: 1, status: 1 });
vipSubscriptionSchema.index({ status: 1, endAt: 1 });
vipSubscriptionSchema.index({ childId: 1, endAt: 1 });
```

---

### 3.13 daily_tasks - 每日任务表

```javascript
const dailyTaskSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  description: String,

  // ========== 触发条件 ==========
  trigger: {
    type: {
      type: String,
      enum: ['reading', 'word_count', 'time_minutes', 'assessment']
    },
    threshold: Number
  },

  // ========== 奖励 ==========
  rewards: {
    stars: { type: Number, default: 0 },
    coins: { type: Number, default: 0 }
  },

  // ========== 限制 ==========
  dailyLimit: {
    type: Number,
    default: 1  // 每日可完成次数
  },

  level: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'easy'
  }
}, {
  timestamps: true
});
```

**预设每日任务**：
```javascript
[
  { code: 'DAILY_READ_1', name: '阅读一本绘本', trigger: { type: 'book_count', threshold: 1 }, rewards: { stars: 2, coins: 5 } },
  { code: 'DAILY_READ_3', name: '阅读三本绘本', trigger: { type: 'book_count', threshold: 3 }, rewards: { stars: 5, coins: 15 } },
  { code: 'DAILY_LEARN_5', name: '学习5个新字', trigger: { type: 'word_count', threshold: 5 }, rewards: { stars: 3, coins: 10 } },
  { code: 'DAILY_REVIEW_10', name: '复习10个字', trigger: { type: 'word_count', threshold: 10, subtype: 'review' }, rewards: { stars: 2, coins: 5 } },
  { code: 'DAILY_TIME_10', name: '学习10分钟', trigger: { type: 'time_minutes', threshold: 10 }, rewards: { stars: 3, coins: 8 } }
]
```

---

### 3.14 child_tasks - 儿童任务进度表

```javascript
const childTaskSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },
  taskCode: {
    type: String,
    required: true
  },
  taskDate: {
    type: Date,
    required: true  // 任务所属日期
  },

  // ========== 进度 ==========
  progress: {
    type: Number,
    default: 0,
    min: 0
  },
  target: {
    type: Number,
    required: true
  },
  completed: {
    type: Boolean,
    default: false,
    index: true
  },
  completedAt: Date,

  // ========== 奖励 ==========
  rewardsClaimed: {
    stars: { type: Number, default: 0 },
    coins: { type: Number, default: 0 }
  }

}, {
  timestamps: true
});

// 唯一索引
childTaskSchema.index({ childId: 1, taskCode: 1, taskDate: 1 }, { unique: true });

// 索引
childTaskSchema.index({ childId: 1, taskDate: 1 });
childTaskSchema.index({ taskDate: 1, completed: 1 });
```

---

### 3.15 assessments - 识字测评表

```javascript
const assessmentSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },

  // ========== 测评配置 ==========
  type: {
    type: String,
    enum: ['initial', 'review', 'level_test'],
    default: 'initial'
  },
  questionCount: {
    type: Number,
    default: 50
  },

  // ========== 题目与答案 ==========
  questions: [{
    characterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Character'
    },
    character: String,
    questionType: {
      type: String,
      enum: ['recognize', 'pinyin', 'meaning']
    },
    options: [String],      // 题目选项（含正确答案）
    correctAnswer: String,
    userAnswer: String,
    isCorrect: Boolean,
    responseTime: Number
  }],

  // ========== 测评结果 ==========
  totalScore: {
    type: Number,
    default: 0
  },
  correctCount: {
    type: Number,
    default: 0
  },
  estimatedWordCount: {
    type: Number,
    default: 0  // 估计识字量
  },
  recommendedLevel: {
    type: Number,
    min: 1,
    max: 5
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['in_progress', 'completed'],
    default: 'in_progress'
  },
  startedAt: {
    type: Date,
    required: true
  },
  completedAt: Date

}, {
  timestamps: true
});

// 索引
assessmentSchema.index({ childId: 1, status: 1 });
assessmentSchema.index({ childId: 1, createdAt: -1 });
```

---

## 四、数据库关系图

```
┌──────────────────────────────────────────────────────────────────┐
│                          数据关系图                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────┐          ┌─────────────┐                            │
│  │  User   │───1:N───▶│   Child     │                            │
│  └─────────┘          └──────┬──────┘                            │
│                              │                                    │
│         ┌────────────────────┼────────────────────┐               │
│         │                    │                    │               │
│         ▼                    ▼                    ▼               │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐       │
│  │   Order     │    │ LearningRecord  │    │VipSubscription│     │
│  └─────────────┘    └────────┬────────┘    └─────────────┘       │
│                               │                                     │
│         ┌─────────────────────┼─────────────────────┐             │
│         │                     │                     │             │
│         ▼                     ▼                     ▼             │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐       │
│  │    Book     │◀───│  BookPage       │    │ WordMastery │       │
│  └──────┬──────┘    └─────────────────┘    └──────┬──────┘       │
│         │                                          │               │
│         │              ┌─────────────────┐         │               │
│         └─────────────▶│  Character      │◀────────┘               │
│                        └─────────────────┘                         │
│                                                                   │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐       │
│  │ Achievement │───▶│ChildAchievement │◀───│    Child     │       │
│  └─────────────┘    └─────────────────┘    └──────┬──────┘       │
│                                                   │               │
│         ┌─────────────────────┐                  │               │
│         │                     │                  ▼               │
│         ▼                     ▼          ┌─────────────┐         │
│  ┌─────────────┐    ┌─────────────────┐│  DailyTask   │         │
│  │  Assessment │    │ ReviewSchedule  ││              │         │
│  └─────────────┘    └─────────────────┘└──────────────┘         │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 五、数据库设计原则

### 5.1 索引设计

| 集合 | 必选索引 | 说明 |
|------|---------|------|
| users | phone, wechatOpenId | 登录查询 |
| children | userId, currentLevel, isVip | 儿童列表、学习推荐 |
| characters | level, grade, character | 汉字查询、分级获取 |
| books | level, theme, status | 绘本筛选 |
| learning_records | childId, createdAt | 学习历史 |
| word_mastery | childId+characterId | 唯一性、快速查询 |
| orders | orderNo, userId, payStatus | 订单查询、状态轮询 |

### 5.2 范式与反范式

**适当反范式**：
- `children.knownCharacters` 存储已认识汉字ID列表，避免关联查询
- `books.newCharacters` 预存生字ID，便于推荐算法
- `learning_records.characters` 内嵌学习详情，减少查询次数

### 5.3 数据校验

```javascript
// 统一的中文错误消息
const errorMessages = {
  phone: '请输入正确的手机号',
  password: '密码至少6位',
  name: '姓名不能为空',
  birthDate: '请选择正确的出生日期'
};

// 使用Mongoose验证器
childSchema.path('phone').validate({
  validator: function(v) {
    return /^1[3-9]\d{9}$/.test(v);
  },
  message: errorMessages.phone
});
```

---

## 六、安全与性能考虑

### 6.1 敏感数据保护
- 用户密码使用bcrypt加密（cost factor: 12）
- JWT Token设置合理过期时间（Access: 2小时，Refresh: 7天）
- 订单金额存储使用整数（分），避免浮点精度问题

### 6.2 写入优化
- 批量操作使用`bulkWrite`
- 预定义Schema减少运行时类型转换
- 使用`lean()`查询获取原生JS对象

### 6.3 读取优化
- 热门绘本数据使用Redis缓存
- 分页查询限制最大条数（max: 100）
- 避免深度嵌套的populate

---

## 七、待评审问题

| # | 问题 | 建议方案 |
|---|------|---------|
| 1 | 是否需要支持多设备登录？ | MVP暂不支持 |
| 2 | 汉字音频是否实时TTS生成？ | 初期预生成，CDN分发 |
| 3 | 学习记录是否需要实时同步？ | 定期批量上报 |
| 4 | 是否需要支持数据导出（COPPA合规）？ | V1.0阶段实现 |

---

*文档版本：v1.0*
*待评审后更新为正式版本*
