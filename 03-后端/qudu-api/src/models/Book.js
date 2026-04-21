const mongoose = require('mongoose');

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
    default: ''  // 封面图URL，开发阶段可为空
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
    index: true  // 如：身体认知、自然、家庭、友情等
  },
  tags: [{
    type: String,
    trim: true
  }],

  // ========== 主角信息 ==========
  protagonist: {
    name: String,
    description: String  // 主角描述
  },

  // ========== 新字配置 ==========
  newWords: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }],
  newWordCount: {
    type: Number,
    default: 0
  },

  // ========== 复习字 ==========
  reviewWords: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }],

  // ========== 内容配置 ==========
  pageCount: {
    type: Number,
    required: true,
    min: 1
  },
  totalCharacters: {
    type: Number,
    default: 0  // 总字数
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

  // ========== 练习配置 ==========
  exercises: [{
    type: {
      type: String,
      enum: ['image_match', 'size_compare', 'point_identify', 'count', 'emotion'],
      required: true
    },
    question: String,
    options: [String],
    correctAnswer: String,
    instruction: String  // 给家长的指导语
  }],

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

  // ========== 排序 ==========
  sortOrder: {
    type: Number,
    default: 0  // 同级别内的排序权重
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
bookSchema.index({ level: 1, sortOrder: 1 });
bookSchema.index({ theme: 1, level: 1 });
bookSchema.index({ isFree: 1, status: 1 });
bookSchema.index({ readCount: -1 });
bookSchema.index({ publishedAt: -1 });

// 文本搜索索引
bookSchema.index({ title: 'text', description: 'text' });

// 统一 toJSON：_id → id
bookSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('Book', bookSchema);
