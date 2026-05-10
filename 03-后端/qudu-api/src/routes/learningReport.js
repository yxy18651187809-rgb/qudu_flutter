const express = require('express');
const router = express.Router();
const reportCtrl = require('../controllers/learningReportController');
const authMiddleware = require('../middlewares/auth');
const { validateObjectId } = require('../middlewares/validateObjectId');

/**
 * @openapi
 * /learning-report/parent/{parentId}:
 *   get:
 *     tags: [学习报告]
 *     summary: 获取学习报告列表（家长视角）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: parentId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 家长ID
 *       - name: period
 *         in: query
 *         required: false
 *         schema: { type: string, enum: [daily, weekly], default: daily }
 *         description: 报告周期
 *       - name: date
 *         in: query
 *         schema: { type: string, format: date }
 *         description: 报告日期，默认今天
 *     responses:
 *       200: { description: 成功 }
 *       403: { description: 无权访问 }
 */
router.get('/parent/:parentId', authMiddleware, reportCtrl.getLearningReportList);

/**
 * @openapi
 * /learning-report/{childId}:
 *   get:
 *     tags: [学习报告]
 *     summary: 获取学习报告
 *     description: 获取指定孩子的学习报告（支持日/周/月维度）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 孩子ID
 *       - name: period
 *         in: query
 *         required: false
 *         schema: { type: string, enum: [daily, weekly, monthly], default: daily }
 *       - name: date
 *         in: query
 *         schema: { type: string, format: date }
 *         description: 报告日期（YYYY-MM-DD），默认今天
 *       - name: days
 *         in: query
 *         schema: { type: integer, default: 7 }
 *         description: 趋势数据天数
 *     responses:
 *       200: { description: 成功 }
 *       404: { description: 孩子不存在或无权访问 }
 */
router.get('/:childId', authMiddleware, validateObjectId('childId'), reportCtrl.getLearningReport);

/**
 * @openapi
 * /learning-report/{childId}/generate:
 *   post:
 *     tags: [学习报告]
 *     summary: 生成学习报告（手动触发）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 孩子ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date: { type: string, format: date }
 *               period: { type: string, enum: [daily, weekly, monthly], default: daily }
 *     responses:
 *       200: { description: 生成成功 }
 *       403: { description: 无权操作 }
 */
router.post('/:childId/generate', authMiddleware, validateObjectId('childId'), reportCtrl.generateLearningReport);

/**
 * @openapi
 * /learning-report/{childId}/characters-trend:
 *   get:
 *     tags: [学习报告]
 *     summary: 获取识字量趋势（简化版）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *       - name: days
 *         in: query
 *         schema: { type: integer, default: 30 }
 *     responses:
 *       200: { description: 成功 }
 *       403: { description: 无权访问 }
 */
router.get('/:childId/characters-trend', authMiddleware, validateObjectId('childId'), reportCtrl.getCharactersTrend);

module.exports = router;
