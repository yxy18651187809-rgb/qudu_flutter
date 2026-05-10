/**
 * Winston 日志工具
 *
 * 三级日志输出：
 * - error: 仅写入 logs/error.log
 * - combined: 写入 logs/combined.log（含所有级别）
 * - console: 开发环境输出到控制台（彩色）
 *
 * 环境变量：
 * - LOG_LEVEL: 日志级别（error|warn|info|debug），默认 info
 * - NODE_ENV: 环境标识（production 时控制台不输出颜色）
 */

const winston = require('winston');
const path = require('path');
const fs = require('fs');

// 确保日志目录存在
const logDir = path.join(__dirname, '..', '..', 'logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const logLevel = process.env.LOG_LEVEL || 'info';
const isProduction = process.env.NODE_ENV === 'production';

// 日志格式
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    return `${timestamp} ${level}: ${message}${metaStr}`;
  })
);

const fileFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.json()
);

// 创建 logger 实例
const logger = winston.createLogger({
  level: logLevel,
  transports: [
    // 错误日志单独文件
    new winston.transports.File({
      filename: path.join(logDir, 'error.log'),
      level: 'error',
      format: fileFormat,
      maxsize: 5 * 1024 * 1024, // 5MB
      maxFiles: 5
    }),
    // 全量日志
    new winston.transports.File({
      filename: path.join(logDir, 'combined.log'),
      format: fileFormat,
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 10
    })
  ]
});

// 非生产环境额外输出到控制台
if (!isProduction) {
  logger.add(new winston.transports.Console({
    format: consoleFormat
  }));
}

// 生产环境也输出到控制台（但不带颜色，便于日志收集）
if (isProduction) {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
      winston.format.printf(({ timestamp, level, message, ...meta }) => {
        const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
        return `${timestamp} ${level.toUpperCase()}: ${message}${metaStr}`;
      })
    )
  }));
}

/**
 * 创建带请求上下文的子 logger
 * @param {Object} req - Express request 对象
 * @returns {winston.Logger}
 */
logger.childWithRequest = function (req) {
  return this.child({
    requestId: req.requestId || 'unknown',
    method: req.method,
    url: req.originalUrl,
    ip: req.ip
  });
};

module.exports = logger;
