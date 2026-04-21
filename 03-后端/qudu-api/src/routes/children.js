const express = require('express');
const router = express.Router();
const childCtrl = require('../controllers/childController');
const authMiddleware = require('../middlewares/auth');

// 所有儿童档案接口都需要认证
router.use(authMiddleware);

/**
 * @openapi
 * /children:
 *   get:
 *     tags: [儿童档案]
 *     summary: 获取儿童列表
 *     description: 获取当前用户下所有未删除的儿童档案
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id: { type: string }
 *                       name: { type: string, example: "小明" }
 *                       birthDate: { type: string, format: date }
 *                       gender: { type: string, enum: [male, female] }
 *                       avatar: { type: string }
 *                       level: { type: integer, example: 1 }
 *                       totalStars: { type: integer, example: 45 }
 *                       totalCoins: { type: integer, example: 120 }
 *                       streakDays: { type: integer, example: 3 }
 *                 message: { type: string, example: "success" }
 */
router.get('/', childCtrl.getChildren);

/**
 * @openapi
 * /children:
 *   post:
 *     tags: [儿童档案]
 *     summary: 创建儿童档案
 *     description: 为当前用户创建一个儿童档案，最多5个
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, birthDate, gender]
 *             properties:
 *               name:
 *                 type: string
 *                 example: "小明"
 *               birthDate:
 *                 type: string
 *                 format: date
 *                 example: "2019-06-15"
 *               gender:
 *                 type: string
 *                 enum: [male, female]
 *                 example: "male"
 *               avatar:
 *                 type: string
 *                 description: 头像URL（可选）
 *     responses:
 *       201:
 *         description: 创建成功
 *       400:
 *         description: 参数错误或已达上限
 */
router.post('/', childCtrl.createChild);

/**
 * @openapi
 * /children/{id}:
 *   get:
 *     tags: [儿童档案]
 *     summary: 获取儿童详情
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 儿童ID
 *     responses:
 *       200:
 *         description: 成功
 *       404:
 *         description: 儿童档案不存在
 */
router.get('/:id', childCtrl.getChild);

/**
 * @openapi
 * /children/{id}:
 *   put:
 *     tags: [儿童档案]
 *     summary: 更新儿童档案
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string, example: "小明" }
 *               birthDate: { type: string, format: date }
 *               gender: { type: string, enum: [male, female] }
 *               avatar: { type: string }
 *     responses:
 *       200:
 *         description: 更新成功
 */
router.put('/:id', childCtrl.updateChild);

/**
 * @openapi
 * /children/{id}:
 *   delete:
 *     tags: [儿童档案]
 *     summary: 删除儿童档案（软删除）
 *     description: 标记为已删除，数据仍保留
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: 删除成功
 */
router.delete('/:id', childCtrl.deleteChild);

module.exports = router;
