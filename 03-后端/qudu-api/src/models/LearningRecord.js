const mongoose = require('mongoose');

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
  assessmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Assessment',
    sparse: true
  },

  // ========== 学习类型 ==========
  type: {
    type: String,
    required: true,
    enum: ['assessment', 'reading', 'word_study', 'review', 'game'],
    index: true
  },
  subtype: {
    type: String  // 细分类型：如 assessment.initial / reading.page
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

// 统一 toJSON：_id → id
learningRecordSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('LearningRecord', learningRecordSchema);
