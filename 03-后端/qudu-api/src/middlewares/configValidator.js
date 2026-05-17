const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');

/**
 * 生产环境配置校验
 * 启动时检查关键密钥是否安全，不安全则拒绝启动
 */
function validateProductionConfig(config) {
  const errors = [];
  const warnings = [];

  // ===== 必须检查项 =====

  // 1. JWT_SECRET 不能是默认值
  const defaultSecrets = [
    'dev-secret-change-in-production',
    'qudu-dev-jwt-secret-2026',
    '请在此填入您的JWT密钥',
    'secret',
    'jwt-secret'
  ];
  if (!config.jwt.secret || defaultSecrets.some(s => config.jwt.secret.includes(s))) {
    errors.push('JWT_SECRET 使用了默认值或不安全密钥，生产环境必须配置强随机密钥（32+ 字符）');
  }

  // 2. JWT_SECRET 长度不足
  if (config.jwt.secret && config.jwt.secret.length < 32) {
    errors.push(`JWT_SECRET 长度仅 ${config.jwt.secret.length} 字符，生产环境建议 32+ 字符`);
  }

  // 3. MongoDB URI 不能是 localhost
  if (config.mongodb.uri.includes('localhost') || config.mongodb.uri.includes('127.0.0.1')) {
    errors.push('MONGODB_URI 指向本地地址，生产环境应使用远程数据库并启用 TLS');
  }

  // 4. SMS 不能是 mock 模式
  if (config.sms.provider === 'mock') {
    warnings.push('SMS_PROVIDER 为 mock 模式，用户无法收到真实验证码');
  }

  // 5. 微信配置不能为空
  if (!config.wechat.appId || config.wechat.appId === 'mock' || !config.wechat.appSecret || config.wechat.appSecret === 'mock') {
    warnings.push('微信登录配置为 mock 模式，微信登录功能不可用');
  }

  // 6. CORS 不能仅包含 localhost
  const corsOrigins = config.security.corsOrigins;
  if (corsOrigins.length === 0) {
    errors.push('CORS_ORIGINS 为空，所有跨域请求将被拒绝');
  }
  const hasOnlyLocalhost = corsOrigins.every(o => o.includes('localhost') || o.includes('127.0.0.1'));
  if (hasOnlyLocalhost) {
    warnings.push('CORS_ORIGINS 仅包含本地地址，生产环境应配置正式域名');
  }

  // ===== .env 文件权限检查 =====
  const envPath = path.join(__dirname, '../../.env');
  if (fs.existsSync(envPath)) {
    try {
      const stat = fs.statSync(envPath);
      const mode = stat.mode;
      // 检查是否对"其他用户"可读（权限位 0o004）
      if (mode & 0o004) {
        warnings.push('.env 文件权限过于开放，建议执行: chmod 600 .env');
      }
    } catch {
      // 文件权限检查失败不阻塞启动
    }
  }

  // ===== 输出结果 =====
  if (warnings.length > 0) {
    logger.warn('[ConfigValidator] 配置警告:');
    warnings.forEach(w => logger.warn(`  ⚠ ${w}`));
  }

  if (errors.length > 0) {
    logger.error('[ConfigValidator] 配置错误，拒绝启动:');
    errors.forEach(e => logger.error(`  ✘ ${e}`));
    throw new Error(`生产环境配置校验失败:\n${errors.map(e => `  - ${e}`).join('\n')}`);
  }

  logger.info('[ConfigValidator] 配置校验通过');
}

/**
 * 开发环境配置提醒
 */
function validateDevConfig(config) {
  const reminders = [];

  if (config.jwt.secret === 'dev-secret-change-in-production') {
    reminders.push('JWT_SECRET 使用默认值，生产环境务必修改');
  }

  if (config.sms.provider === 'mock') {
    reminders.push('SMS 使用 mock 模式，验证码固定 123456');
  }

  if (config.mongodb.uri.includes('localhost')) {
    reminders.push('MongoDB 连接本地实例');
  }

  if (reminders.length > 0) {
    logger.info('[ConfigValidator] 开发环境提醒:');
    reminders.forEach(r => logger.info(`  ℹ ${r}`));
  }
}

/**
 * 入口：根据环境执行不同校验
 */
function validateConfig(config) {
  const isProduction = process.env.NODE_ENV === 'production';

  if (isProduction) {
    validateProductionConfig(config);
  } else {
    validateDevConfig(config);
  }
}

module.exports = { validateConfig, validateProductionConfig, validateDevConfig };
