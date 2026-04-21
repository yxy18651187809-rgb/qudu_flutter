const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true
  },
  password: {
    type: String,
    select: false
  },
  nickname: {
    type: String,
    trim: true,
    maxlength: 50,
    default: ''
  },
  avatar: {
    type: String,
    default: ''
  },
  wechatOpenId: {
    type: String,
    sparse: true,
    index: true
  },
  wechatUnionId: {
    type: String,
    sparse: true
  },
  status: {
    type: String,
    enum: ['active', 'banned'],
    default: 'active'
  },
  lastLoginAt: Date,
  privacyAccepted: {
    type: Boolean,
    default: false
  },
  privacyAcceptedAt: Date
}, {
  timestamps: true
});

userSchema.index({ phone: 1, status: 1 });

// 虚拟字段：脱敏手机号
userSchema.virtual('maskedPhone').get(function() {
  if (!this.phone || this.phone.length !== 11) return this.phone;
  return this.phone.slice(0, 3) + '****' + this.phone.slice(7);
});

userSchema.set('toJSON', { virtuals: true });
userSchema.set('toObject', { virtuals: true });

// 统一 toJSON：_id → id
userSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('User', userSchema);
