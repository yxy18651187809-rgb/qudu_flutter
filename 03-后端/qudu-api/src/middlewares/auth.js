const { verifyToken } = require('../utils/token');
const { error, ErrorCodes } = require('../utils/response');

/**
 * JWT 认证中间件
 * 验证 Authorization: Bearer <accessToken>
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, ErrorCodes.TOKEN_INVALID, '未提供认证令牌', 401);
  }
  
  const token = authHeader.split(' ')[1];
  
  try {
    const decoded = verifyToken(token);
    
    if (decoded.type !== 'access') {
      return error(res, ErrorCodes.TOKEN_INVALID, '令牌类型错误', 401);
    }
    
    req.userId = decoded.userId;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return error(res, ErrorCodes.TOKEN_EXPIRED, '访问令牌已过期', 401);
    }
    return error(res, ErrorCodes.TOKEN_INVALID, '访问令牌无效', 401);
  }
}

/**
 * 可选认证中间件
 * 有Token则解析，无Token也放行（用于公开接口，如绘本列表）
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = verifyToken(token);
      if (decoded.type === 'access') {
        req.userId = decoded.userId;
      }
    } catch (err) {
      // Token无效，但公开接口允许继续访问
    }
  }
  
  next();
}

module.exports = authMiddleware;
module.exports.optionalAuth = optionalAuth;
