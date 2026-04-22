/**
 * 请求日志中间件
 * 记录每个API请求的方法、路径、响应时间和状态码
 */

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
    
    // 用颜色标记慢请求
    const slowTag = duration > 1000 ? '⚠️ SLOW' : '';
    
    console.log(
      `[API] ${method} ${originalUrl} → ${statusCode} (${duration}ms) user=${userId} ${slowTag}`.trim()
    );
    
    // 超慢请求单独告警
    if (duration > 3000) {
      console.warn(`[API WARN] 极慢请求: ${method} ${originalUrl} 耗时 ${duration}ms, requestId=${requestId}`);
    }
  });
  
  next();
}

module.exports = requestLogger;
