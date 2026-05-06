/**
 * 统一响应格式工具
 * 
 * 成功: { code: 0, data: ..., message: "success" }
 * 失败: { code: 4xxxx, data: null, message: "错误描述" }
 */

/**
 * 成功响应
 */
function success(res, data = null, message = 'success', statusCode = 200) {
  return res.status(statusCode).json({
    code: 0,
    data,
    message
  });
}

/**
 * 创建成功响应 (201)
 */
function created(res, data = null, message = 'success') {
  return success(res, data, message, 201);
}

/**
 * 错误响应
 */
function error(res, code, message, statusCode = 400) {
  return res.status(statusCode).json({
    code,
    data: null,
    message
  });
}

/**
 * 失败响应（兼容写法）
 */
function fail(statusCode, message) {
  return {
    code: statusCode,
    data: null,
    message
  };
}

/**
 * 分页信息
 */
function paginate(page, pageSize, total) {
  return {
    page: Number(page),
    pageSize: Number(pageSize),
    total,
    totalPages: Math.ceil(total / pageSize)
  };
}

// 预定义错误码
const ErrorCodes = {
  // 参数校验 40001-40099
  INVALID_PHONE: 40001,
  INVALID_SMS_CODE: 40002,
  SMS_CODE_EXPIRED: 40003,
  INVALID_PARAMS: 40010,
  INVALID_BIRTH_DATE: 40011,
  NAME_REQUIRED: 40012,
  INVALID_CHILD_ID: 40013,
  
  // 认证 40101-40199
  TOKEN_EXPIRED: 40101,
  TOKEN_INVALID: 40102,
  REFRESH_TOKEN_EXPIRED: 40103,
  
  // 权限 40301-40399
  FORBIDDEN: 40301,
  MAX_CHILDREN_REACHED: 40310,
  CHILD_ACCESS_DENIED: 40311,
  
  // 资源不存在 40401-40499
  NOT_FOUND: 40401,
  CHILD_NOT_FOUND: 40410,
  USER_NOT_FOUND: 40411,
  REPORT_NOT_FOUND: 40412,
  
  // 限流 42901-42999
  SMS_RATE_LIMIT: 42901,
  
  // 服务端 50001-50099
  INTERNAL_ERROR: 50001,
  SMS_SEND_FAILED: 50010,
  GENERATE_FAILED: 50011
};

module.exports = {
  success,
  created,
  error,
  fail,
  paginate,
  ErrorCodes
};
