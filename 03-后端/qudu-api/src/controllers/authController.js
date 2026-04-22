const User = require('../models/User');
const Child = require('../models/Child');
const { generateTokenPair, verifyToken, getAccessTokenExpiresIn } = require('../utils/token');
const { success, created, error, ErrorCodes } = require('../utils/response');
const config = require('../config');

// ===== 验证码存储（MVP 用内存，生产环境用 Redis） =====
const smsCodeStore = new Map();

/**
 * 发送验证码
 * POST /api/v1/auth/sms/send
 */
async function sendSmsCode(req, res) {
  try {
    const { phone } = req.body;
    
    // 校验手机号
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return error(res, ErrorCodes.INVALID_PHONE, '手机号格式不正确');
    }
    
    // 限流：60秒内只能发1次
    const rateKey = `rate_${phone}`;
    const rateInfo = smsCodeStore.get(rateKey);
    if (rateInfo && Date.now() - rateInfo.timestamp < config.limits.smsCodeIntervalSeconds * 1000) {
      const waitSeconds = Math.ceil((config.limits.smsCodeIntervalSeconds * 1000 - (Date.now() - rateInfo.timestamp)) / 1000);
      return error(res, ErrorCodes.SMS_RATE_LIMIT, `发送过于频繁，请${waitSeconds}秒后重试`, 429);
    }
    
    // 限流：每日最多10次
    const dailyKey = `daily_${phone}_${new Date().toISOString().slice(0, 10)}`;
    const dailyCount = smsCodeStore.get(dailyKey) || 0;
    if (dailyCount >= config.limits.smsCodeDailyLimit) {
      return error(res, ErrorCodes.SMS_RATE_LIMIT, '今日发送次数已达上限', 429);
    }
    
    // 生成验证码
    const code = config.sms.provider === 'mock' 
      ? config.sms.mockCode 
      : String(Math.floor(100000 + Math.random() * 900000));
    
    // 存储验证码（统一为字符串）
    smsCodeStore.set(phone, {
      code: String(code),
      timestamp: Date.now(),
      attempts: 0
    });
    smsCodeStore.set(rateKey, { timestamp: Date.now() });
    smsCodeStore.set(dailyKey, dailyCount + 1);
    
    // MVP：直接返回验证码（生产环境通过短信服务发送）
    console.log(`[SMS] 验证码发送: ${phone} -> ${code}`);
    
    return success(res, {
      expireIn: config.limits.smsCodeExpireSeconds,
      // MVP 阶段返回验证码，生产环境删除此字段
      ...(config.sms.provider === 'mock' && { _debugCode: code })
    });
  } catch (err) {
    console.error('[Auth] 发送验证码失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '发送验证码失败', 500);
  }
}

/**
 * 登录（手机号+验证码）
 * POST /api/v1/auth/login
 */
async function login(req, res) {
  try {
    const { phone, code: smsCode } = req.body;
    
    // 校验手机号
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return error(res, ErrorCodes.INVALID_PHONE, '手机号格式不正确');
    }
    
    // 校验验证码
    const storedCode = smsCodeStore.get(phone);
    if (!storedCode) {
      return error(res, ErrorCodes.INVALID_SMS_CODE, '请先获取验证码');
    }
    
    // 验证码过期检查
    if (Date.now() - storedCode.timestamp > config.limits.smsCodeExpireSeconds * 1000) {
      smsCodeStore.delete(phone);
      return error(res, ErrorCodes.SMS_CODE_EXPIRED, '验证码已过期，请重新获取');
    }
    
    // 验证码错误检查（统一为字符串比较，防止类型不一致）
    if (String(storedCode.code) !== String(smsCode)) {
      storedCode.attempts += 1;
      if (storedCode.attempts >= 5) {
        smsCodeStore.delete(phone);
        return error(res, ErrorCodes.INVALID_SMS_CODE, '验证码错误次数过多，请重新获取');
      }
      return error(res, ErrorCodes.INVALID_SMS_CODE, '验证码错误');
    }
    
    // 验证通过，清除验证码
    smsCodeStore.delete(phone);
    
    // 查找或创建用户
    let user = await User.findOne({ phone });
    let isNewUser = false;
    
    if (!user) {
      // 自动注册
      user = await User.create({ phone });
      isNewUser = true;
      console.log(`[Auth] 新用户注册: ${phone}`);
    }
    
    // 更新最后登录时间
    user.lastLoginAt = new Date();
    await user.save();
    
    // 生成 Token
    const tokens = generateTokenPair(user._id.toString());
    
    // 获取用户儿童数量
    const childrenCount = await Child.countDocuments({ 
      userId: user._id, 
      status: 'active' 
    });
    
    return success(res, {
      isNewUser,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: getAccessTokenExpiresIn(),
      user: {
        id: user._id,
        phone: user.maskedPhone,
        nickname: user.nickname,
        avatar: user.avatar,
        hasChildren: childrenCount > 0,
        childrenCount
      }
    });
  } catch (err) {
    console.error('[Auth] 登录失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '登录失败', 500);
  }
}

/**
 * 刷新 Token
 * POST /api/v1/auth/refresh
 */
async function refreshToken(req, res) {
  try {
    const { refreshToken: token } = req.body;
    
    if (!token) {
      return error(res, ErrorCodes.TOKEN_INVALID, '缺少 refreshToken', 400);
    }
    
    const decoded = verifyToken(token);
    
    if (decoded.type !== 'refresh') {
      return error(res, ErrorCodes.TOKEN_INVALID, '令牌类型错误', 401);
    }
    
    // 验证用户是否存在
    const user = await User.findById(decoded.userId);
    if (!user || user.status !== 'active') {
      return error(res, ErrorCodes.REFRESH_TOKEN_EXPIRED, '用户不存在或已禁用', 401);
    }
    
    // 生成新 Token 对
    const tokens = generateTokenPair(user._id.toString());
    
    return success(res, {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: getAccessTokenExpiresIn()
    });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return error(res, ErrorCodes.REFRESH_TOKEN_EXPIRED, 'refreshToken已过期，请重新登录', 401);
    }
    return error(res, ErrorCodes.TOKEN_INVALID, 'refreshToken无效', 401);
  }
}

/**
 * 获取用户信息
 * GET /api/v1/user/profile
 */
async function getProfile(req, res) {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return error(res, ErrorCodes.USER_NOT_FOUND, '用户不存在', 404);
    }
    
    const childrenCount = await Child.countDocuments({ 
      userId: user._id, 
      status: 'active' 
    });
    
    return success(res, {
      id: user._id,
      phone: user.maskedPhone,
      nickname: user.nickname,
      avatar: user.avatar,
      privacyAccepted: user.privacyAccepted,
      hasChildren: childrenCount > 0,
      childrenCount,
      createdAt: user.createdAt
    });
  } catch (err) {
    console.error('[User] 获取用户信息失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '获取用户信息失败', 500);
  }
}

/**
 * 更新用户信息
 * PUT /api/v1/user/profile
 */
async function updateProfile(req, res) {
  try {
    const { nickname, avatar } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return error(res, ErrorCodes.USER_NOT_FOUND, '用户不存在', 404);
    }
    
    if (nickname !== undefined) user.nickname = nickname;
    if (avatar !== undefined) user.avatar = avatar;
    
    await user.save();
    
    return success(res, {
      id: user._id,
      phone: user.maskedPhone,
      nickname: user.nickname,
      avatar: user.avatar,
      privacyAccepted: user.privacyAccepted,
      createdAt: user.createdAt
    });
  } catch (err) {
    console.error('[User] 更新用户信息失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '更新用户信息失败', 500);
  }
}

module.exports = {
  sendSmsCode,
  login,
  refreshToken,
  getProfile,
  updateProfile
};
