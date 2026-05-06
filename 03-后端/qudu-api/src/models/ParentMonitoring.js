const mongoose = require('mongoose');

/**
 * 家长监控 Model
 * 用于存储家长的监控设置和孩子监控状态
 */
const ParentMonitoringSchema = new mongoose.Schema({
  parentId: {
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

  // 监控阈值设置
  thresholds: {
    maxDailyStudyTime: {
      type: Number,
      default: 60,
      min: 0
    },
    minDailyStudyTime: {
      type: Number,
      default: 15,
      min: 0
    },
    minCharactersPerDay: {
      type: Number,
      default: 3,
      min: 0
    },
    minAccuracy: {
      type: Number,
      default: 70,
      min: 0,
      max: 100
    },
    maxReviewDelayDays: {
      type: Number,
      default: 2,
      min: 0
    }
  },

  // 当前监控状态（实时更新）
  status: {
    dailyStudyTime: {
      type: Number,
      default: 0,
      min: 0
    },
    dailyCharactersLearned: {
      type: Number,
      default: 0,
      min: 0
    },
    weeklyAccuracy: {
      type: Number,
      min: 0,
      max: 100
    },
    reviewDueCount: {
      type: Number,
      default: 0,
      min: 0
    },
    lastAlertSentAt: {
      type: Date
    }
  },

  // 告警设置
  alertSettings: {
    enableStudyTimeAlert: {
      type: Boolean,
      default: true
    },
    enableAccuracyAlert: {
      type: Boolean,
      default: true
    },
    enableReviewAlert: {
      type: Boolean,
      default: true
    },
    alertMethods: [{
      type: String,
      enum: ['push', 'sms', 'wechat']
    }]
  },

  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// 复合索引：确保同一家长-孩子对只有一条记录
ParentMonitoringSchema.index(
  { parentId: 1, childId: 1 },
  { unique: true }
);

// 统一 toJSON：_id → id
ParentMonitoringSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('ParentMonitoring', ParentMonitoringSchema);
