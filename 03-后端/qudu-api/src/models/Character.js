const mongoose = require('mongoose');

const characterSchema = new mongoose.Schema({
  character: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  unicode: {
    type: String,
    required: true
  },
  pinyin: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  tone: {
    type: Number,
    min: 1,
    max: 5,
    required: true
  },
  audioUrl: {
    type: String,
    default: ''
  },
  strokeCount: {
    type: Number,
    min: 1,
    max: 64,
    required: true
  },
  radical: {
    type: String,
    trim: true
  },
  structure: {
    type: String,
    enum: ['独体', '左右', '上下', '左中右', '上中下', '半包围', '全包围', '品字'],
    required: true
  },
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
    index: true
  },
  frequency: {
    type: Number,
    default: 0
  },
  coreLevel: {
    type: String,
    enum: ['core', 'extended'],
    default: 'core',
    index: true
  },
  etymology: {
    type: {
      type: String,
      enum: ['象形', '指事', '会意', '形声', '转注', '假借']
    },
    story: String
  },
  meanings: [{
    wordClass: String,
    meaning: String,
    examples: [{
      word: String,
      sentence: String
    }]
  }],
  imageUrl: {
    type: String,
    default: ''
  },
  animationUrl: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: ['active', 'deprecated'],
    default: 'active'
  }
}, {
  timestamps: true
});

characterSchema.index({ level: 1, grade: 1 });
characterSchema.index({ pinyin: 1 });
characterSchema.index({ strokeCount: 1 });
characterSchema.index({ character: 'text' });

// 统一 toJSON：_id → id
characterSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('Character', characterSchema);
