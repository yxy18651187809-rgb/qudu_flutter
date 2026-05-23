const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const config = require('../config');
const authCtrl = require('../controllers/authController');
const authMiddleware = require('../middlewares/auth');

// ===== 短信验证码专项速率限制 =====
const smsRateLimiter = rateLimit({
  windowMs: config.security.rateLimit.sms.windowMs,
  max: config.security.rateLimit.sms.max,
  message: { code: 42903, data: null, message: config.security.rateLimit.sms.message },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // 标准化 IPv6 映射地址
    const ip = (req.ip || '').replace(/^::ffff:/, '');
    return ip + ':' + (req.body?.phone || 'unknown');
  }
});

// ===== 公开接口（无需认证） =====

/**
 * @openapi
 * /auth/sms/send:
 *   post:
 *     tags: [认证模块]
 *     summary: 发送短信验证码
 *     description: 向指定手机号发送6位数字验证码，开发环境固定123456
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [phone]
 *             properties:
 *               phone:
 *                 type: string
 *                 description: 手机号码
 *                 example: "13800138000"
 *     responses:
 *       200:
 *         description: 验证码发送成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     phone: { type: string, example: "138****8000" }
 *                     expiresIn: { type: integer, example: 300, description: 验证码有效期(秒) }
 *                 message: { type: string, example: "success" }
 *       400:
 *         description: 手机号格式错误
 */
router.post('/sms/send', smsRateLimiter, authCtrl.sendSmsCode);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     tags: [认证模块]
 *     summary: 手机号验证码登录
 *     description: 使用手机号+验证码登录，新用户自动注册。首次登录需同意隐私协议。
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [phone, code]
 *             properties:
 *               phone:
 *                 type: string
 *                 description: 手机号码
 *                 example: "13800138000"
 *               code:
 *                 type: string
 *                 description: 短信验证码
 *                 example: "123456"
 *               privacyAccepted:
 *                 type: boolean
 *                 description: 是否同意隐私协议（首次登录必填）
 *                 example: true
 *     responses:
 *       200:
 *         description: 登录成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     accessToken: { type: string, description: 访问令牌(2h有效) }
 *                     refreshToken: { type: string, description: 刷新令牌(30d有效) }
 *                     isNewUser: { type: boolean, example: false }
 *                     user:
 *                       type: object
 *                       properties:
 *                         id: { type: string }
 *                         phone: { type: string, example: "138****8000" }
 *                         nickname: { type: string, example: "测试用户" }
 *                         avatar: { type: string }
 *                 message: { type: string, example: "success" }
 *       401:
 *         description: 验证码错误或已过期
 */
router.post('/login', authCtrl.login);

/**
 * @openapi
 * /auth/refresh:
 *   post:
 *     tags: [认证模块]
 *     summary: 刷新访问令牌
 *     description: 使用refreshToken获取新的accessToken
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: 刷新令牌
 *     responses:
 *       200:
 *         description: 刷新成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     accessToken: { type: string, description: 新的访问令牌 }
 *                     refreshToken: { type: string, description: 新的刷新令牌 }
 *                 message: { type: string, example: "success" }
 *       401:
 *         description: refreshToken无效或已过期
 */
router.post('/refresh', authCtrl.refreshToken);

/**
 * @openapi
 * /auth/wechat-login:
 *   post:
 *     tags: [认证模块]
 *     summary: 微信登录
 *     description: 使用微信授权码登录，新用户自动注册
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code]
 *             properties:
 *               code:
 *                 type: string
 *                 description: 微信授权码
 *                 example: "081Mxk200FJZaK1w6a200FxutbMxk2w"
 *     responses:
 *       200:
 *         description: 登录成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     isNewUser: { type: boolean, example: true }
 *                     needBindPhone: { type: boolean, example: true }
 *                     accessToken: { type: string, description: 访问令牌(2h有效) }
 *                     refreshToken: { type: string, description: 刷新令牌(7d有效) }
 *                     user:
 *                       type: object
 *                       properties:
 *                         id: { type: string }
 *                         nickname: { type: string, example: "微信用户" }
 *                         avatar: { type: string }
 *                 message: { type: string, example: "success" }
 *       401:
 *         description: 微信授权失败
 */
router.post('/wechat-login', authCtrl.wechatLogin);

// ===== 需认证接口 =====

/**
 * @openapi
 * /user/profile:
 *   get:
 *     tags: [用户模块]
 *     summary: 获取用户信息
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     id: { type: string }
 *                     phone: { type: string, example: "138****8000" }
 *                     nickname: { type: string }
 *                     avatar: { type: string }
 *                     children: { type: array, description: 关联的儿童档案列表 }
 *                 message: { type: string, example: "success" }
 *       401:
 *         description: 未认证
 */
router.get('/profile', authMiddleware, authCtrl.getProfile);

/**
 * @openapi
 * /user/profile:
 *   put:
 *     tags: [用户模块]
 *     summary: 更新用户信息
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nickname:
 *                 type: string
 *                 example: "小明妈妈"
 *               avatar:
 *                 type: string
 *                 description: 头像URL
 *     responses:
 *       200:
 *         description: 更新成功
 */
router.put('/profile', authMiddleware, authCtrl.updateProfile);

module.exports = router;
