const mongoose = require('mongoose');

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
    default: ''  // 插图URL，开发阶段可为空
  },
  imageDescription: {
    type: String,
    default: ''  // 插画描述（给插画师参考）
  },
  text: {
    type: String,
    required: true  // 页面文字
  },
  pinyin: {
    type: String,
    default: ''  // 拼音标注
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
    },
    isNewWord: {
      type: Boolean,
      default: true  // 是否为本绘本新字（vs 复习字）
    }
  }],

  // ========== 音频 ==========
  audioUrl: {
    type: String,
    default: ''  // 整页朗读音频
  },

  // ========== 教育要点 ==========
  teachingNote: {
    type: String,
    default: ''  // 给家长/老师的教学提示
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

// 统一 toJSON：_id → id
bookPageSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('BookPage', bookPageSchema);
