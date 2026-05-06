const mongoose = require('mongoose');

/**
 * 学习报告 Model
 * 用于存储和查询孩子的学习报告（日/周/月维度）
 */
const LearningReportSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Child',
    required: true,
    index: true
  },
  date: {
    type: Date,
    required: true,
    index: true
  },
  period: {
    type: String,
    enum: ['daily', 'weekly', 'monthly'],
    required: true,
    index: true
  },

  // 学习统计
  studyTime: {
    type: Number,
    default: 0,
    min: 0
  },
  charactersLearned: {
    type: Number,
    default: 0,
    min: 0
  },
  booksRead: {
    type: Number,
    default: 0,
    min: 0
  },
  assessmentCount: {
    type: Number,
    default: 0,
    min: 0
  },

  // 准确率统计
  averageAccuracy: {
    type: Number,
    min: 0,
    max: 100
  },
  accuracyTrend: [{
    date: { type: Date, required: true },
    accuracy: { type: Number, min: 0, max: 100, required: true }
  }],

  // 识字量统计
  totalCharacters: {
    type: Number,
    default: 0,
    min: 0
  },
  charactersTrend: [{
    date: { type: Date, required: true },
    count: { type: Number, min: 0, required: true }
  }],

  // 复习统计
  reviewDue: {
    type: Number,
    default: 0,
    min: 0
  },
  reviewCompleted: {
    type: Number,
    default: 0,
    min: 0
  },
  reviewRate: {
    type: Number,
    min: 0,
    max: 100
  },

  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// 复合索引：确保同一孩子同一日期同一period只有一条记录
LearningReportSchema.index(
  { childId: 1, date: 1, period: 1 },
  { unique: true }
);

// 统一 toJSON：_id → id
LearningReportSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('LearningReport', LearningReportSchema);
