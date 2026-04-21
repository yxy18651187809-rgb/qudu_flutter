const mongoose = require('mongoose');

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
    default: 0
  },
  correctAttempts: {
    type: Number,
    default: 0
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
    default: 2.5  // 难度因子（SM-2）
  },
  nextReviewAt: Date,

  // ========== 学习阶段 ==========
  stage: {
    type: String,
    enum: ['new', 'learning', 'reviewing', 'mastered'],
    default: 'new'
  },

  // ========== 来源 ==========
  source: {
    type: String,
    enum: ['assessment', 'reading', 'word_study', 'review'],
    default: 'assessment'
  }

}, {
  timestamps: true
});

// 唯一索引
wordMasterySchema.index({ childId: 1, characterId: 1 }, { unique: true });

// 查询索引
wordMasterySchema.index({ childId: 1, stage: 1 });
wordMasterySchema.index({ childId: 1, nextReviewAt: 1 });
wordMasterySchema.index({ childId: 1, masteryScore: 1 });

// 统一 toJSON：_id → id
wordMasterySchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('WordMastery', wordMasterySchema);
