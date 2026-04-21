const express = require('express');
const router = express.Router();
const authCtrl = require('../controllers/authController');
const authMiddleware = require('../middlewares/auth');

// ===== 公开接口（无需认证） =====

/**
 * 发送验证码
 * POST /api/v1/auth/sms/send
 */
router.post('/sms/send', authCtrl.sendSmsCode);

/**
 * 登录（手机号+验证码）
 * POST /api/v1/auth/login
 */
router.post('/login', authCtrl.login);

/**
 * 刷新 Token
 * POST /api/v1/auth/refresh
 */
router.post('/refresh', authCtrl.refreshToken);

// ===== 需认证接口 =====

/**
 * 获取用户信息
 * GET /api/v1/user/profile
 */
router.get('/profile', authMiddleware, authCtrl.getProfile);

/**
 * 更新用户信息
 * PUT /api/v1/user/profile
 */
router.put('/profile', authMiddleware, authCtrl.updateProfile);

module.exports = router;
