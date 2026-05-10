/**
 * 请求日志中间件
 * 记录每个API请求的方法、路径、响应时间和状态码
 * 通过 winston 写入 logs/combined.log（正常）+ logs/error.log（4xx/5xx）
 */

const logger = require('../utils/logger');

function requestLogger(req, res, next) {
  const start = Date.now();
  const requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  // 挂载 requestId 到 req 上，方便后续日志关联
  req.requestId = requestId;

  // 响应完成后记录日志
  res.on('finish', () => {
    const duration = Date.now() - start;
    const { method, originalUrl } = req;
    const { statusCode } = res;
    const userId = req.userId || 'anonymous';

    const logData = {
      type: 'request',
      method,
      url: originalUrl,
      statusCode,
      duration,
      userId,
      requestId
    };

    // 4xx/5xx 写入 warn/error 级别
    if (statusCode >= 500) {
      logger.error(`[API] ${method} ${originalUrl} → ${statusCode} (${duration}ms)`, logData);
    } else if (statusCode >= 400) {
      logger.warn(`[API] ${method} ${originalUrl} → ${statusCode} (${duration}ms)`, logData);
    } else {
      logger.info(`[API] ${method} ${originalUrl} → ${statusCode} (${duration}ms)`, logData);
    }

    // 慢请求独立告警
    if (duration > 1000) {
      logger.warn(`[API SLOW] ${method} ${originalUrl} 耗时 ${duration}ms`, {
        ...logData,
        type: 'slow_request'
      });
    }
  });

  next();
}

module.exports = requestLogger;
