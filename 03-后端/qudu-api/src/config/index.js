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
  }
};
