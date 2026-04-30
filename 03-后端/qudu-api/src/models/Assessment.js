const mongoose = require('mongoose');

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
  bookId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Book'
    // 可选字段，type=review 时必须传入，标识绘本测评来源
  },
  targetLevel: {
    type: Number,
    min: 1,
    max: 5  // 目标测评级别
  },
  questionCount: {
    type: Number,
    default: 20  // 每次测评20题
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
      enum: ['recognize', 'pinyin_match', 'meaning_select'],
      required: true
    },
    options: [String],      // 题目选项（含正确答案）
    correctAnswer: String,
    userAnswer: String,
    isCorrect: Boolean,
    responseTime: Number    // 响应时间（毫秒）
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
  estimatedWordCount: {
    type: Number,
    default: 0  // 估计识字量
  },
  recommendedLevel: {
    type: Number,
    min: 1,
    max: 5
  },

  // ========== 识字量估算详情 ==========
  levelResults: [{
    level: Number,
    testedCount: Number,
    correctCount: Number,
    accuracy: Number
  }],

  // ========== 奖励 ==========
  starsEarned: {
    type: Number,
    default: 0
  },
  coinsEarned: {
    type: Number,
    default: 0
  },

  // ========== 状态 ==========
  status: {
    type: String,
    enum: ['in_progress', 'completed', 'abandoned'],
    default: 'in_progress'
  },
  startedAt: {
    type: Date,
    required: true
  },
  completedAt: Date,
  duration: {
    type: Number,
    default: 0  // 测评时长（秒）
  }

}, {
  timestamps: true
});

// 索引
assessmentSchema.index({ childId: 1, status: 1 });
assessmentSchema.index({ childId: 1, createdAt: -1 });
assessmentSchema.index({ childId: 1, type: 1, createdAt: -1 });
assessmentSchema.index({ childId: 1, bookId: 1, status: 1 });

// 统一 toJSON：_id → id
assessmentSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('Assessment', assessmentSchema);
