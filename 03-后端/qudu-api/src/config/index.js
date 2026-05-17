require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/qudu'
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379'
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '2h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
  },
  sms: {
    provider: process.env.SMS_PROVIDER || 'mock',
    mockCode: process.env.SMS_MOCK_CODE || '123456'
  },
  // 微信登录配置
  wechat: {
    appId: process.env.WECHAT_APPID || '',
    appSecret: process.env.WECHAT_SECRET || ''
  },
  // 业务限制
  limits: {
    maxChildrenPerUser: 3,
    smsCodeExpireSeconds: 300,
    smsCodeIntervalSeconds: 60,
    smsCodeDailyLimit: 10
  },
  // 安全配置
  security: {
    // CORS 白名单（生产环境配置）
    corsOrigins: process.env.CORS_ORIGINS 
      ? process.env.CORS_ORIGINS.split(',') 
      : ['http://localhost:3000', 'http://localhost:8080'],
    // 速率限制（每 15 分钟窗口）
    rateLimit: {
      // 默认限制
      default: {
        windowMs: 15 * 60 * 1000,  // 15 分钟
        max: 100  // 最多 100 请求/窗口
      },
      // 认证接口（登录/注册/短信）更严格
      auth: {
        windowMs: 15 * 60 * 1000,
        max: 10,  // 最多 10 次/窗口
        message: '请求过于频繁，请 15 分钟后再试'
      },
      // 短信验证码专项限制
      sms: {
        windowMs: 60 * 1000,  // 1 分钟
        max: 2,  // 最多 2 次/分钟
        message: '短信发送过于频繁'
      }
    }
  }
};
