const mongoose = require('mongoose');

const childSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
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
    min: 0,
    max: 6,
    default: 0
  },
  currentLevel: {
    type: Number,
    min: 1,
    max: 5,
    default: 1
  },
  knownCharacterCount: {
    type: Number,
    default: 0
  },
  knownCharacters: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Character'
  }],
  streakDays: {
    type: Number,
    default: 0
  },
  totalStars: {
    type: Number,
    default: 0
  },
  totalReadingMinutes: {
    type: Number,
    default: 0
  },
  lastLearningAt: Date,
  isVip: {
    type: Boolean,
    default: false
  },
  vipExpireAt: Date,
  status: {
    type: String,
    enum: ['active', 'archived'],
    default: 'active'
  }
}, {
  timestamps: true
});

childSchema.index({ userId: 1, status: 1 });
childSchema.index({ currentLevel: 1 });
childSchema.index({ isVip: 1, vipExpireAt: 1 });

// 虚拟字段：年龄
childSchema.virtual('age').get(function() {
  if (!this.birthDate) return null;
  const today = new Date();
  const birth = new Date(this.birthDate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
});

childSchema.set('toJSON', { virtuals: true });
childSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Child', childSchema);
