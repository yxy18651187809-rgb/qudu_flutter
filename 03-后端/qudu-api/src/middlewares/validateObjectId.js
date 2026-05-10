const mongoose = require('mongoose');

/**
 * 校验路由参数是否为有效的 MongoDB ObjectId
 * 防止 /start 等路径被 /:id 误匹配
 */
function validateObjectId(paramName = 'id') {
  return (req, res, next) => {
    const value = req.params[paramName];
    if (!mongoose.Types.ObjectId.isValid(value)) {
      res.status(400).json({
        code: 40010,
        data: null,
        message: `无效的ID格式: "${value}"`
      });
      return; // 不调用 next()，结束中间件链
    }
    next();
  };
}

module.exports = { validateObjectId };
