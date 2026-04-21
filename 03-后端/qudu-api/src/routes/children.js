const express = require('express');
const router = express.Router();
const childCtrl = require('../controllers/childController');
const authMiddleware = require('../middlewares/auth');

// 所有儿童档案接口都需要认证
router.use(authMiddleware);

/**
 * 获取儿童列表
 * GET /api/v1/children
 */
router.get('/', childCtrl.getChildren);

/**
 * 创建儿童档案
 * POST /api/v1/children
 */
router.post('/', childCtrl.createChild);

/**
 * 获取儿童详情
 * GET /api/v1/children/:id
 */
router.get('/:id', childCtrl.getChild);

/**
 * 更新儿童档案
 * PUT /api/v1/children/:id
 */
router.put('/:id', childCtrl.updateChild);

/**
 * 删除儿童档案（软删除）
 * DELETE /api/v1/children/:id
 */
router.delete('/:id', childCtrl.deleteChild);

module.exports = router;
