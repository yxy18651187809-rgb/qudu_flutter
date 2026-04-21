const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * 生成 accessToken
 */
function generateAccessToken(userId) {
  return jwt.sign(
    { userId, type: 'access' },
    config.jwt.secret,
    { expiresIn: config.jwt.accessExpiresIn }
  );
}

/**
 * 生成 refreshToken
 */
function generateRefreshToken(userId) {
  return jwt.sign(
    { userId, type: 'refresh' },
    config.jwt.secret,
    { expiresIn: config.jwt.refreshExpiresIn }
  );
}

/**
 * 生成双 Token
 */
function generateTokenPair(userId) {
  return {
    accessToken: generateAccessToken(userId),
    refreshToken: generateRefreshToken(userId)
  };
}

/**
 * 验证 Token
 */
function verifyToken(token) {
  return jwt.verify(token, config.jwt.secret);
}

/**
 * 解析 Token 过期时间（秒）
 */
function getAccessTokenExpiresIn() {
  const expiresIn = config.jwt.accessExpiresIn;
  // 简单解析：支持 "2h", "7d" 等格式
  const match = expiresIn.match(/^(\d+)([hdm])$/);
  if (!match) return 7200;
  const [, num, unit] = match;
  const multipliers = { h: 3600, d: 86400, m: 60 };
  return parseInt(num) * (multipliers[unit] || 3600);
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  generateTokenPair,
  verifyToken,
  getAccessTokenExpiresIn
};
