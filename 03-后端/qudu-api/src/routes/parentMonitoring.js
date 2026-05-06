const express = require('express');
const router = express.Router();
const monitoringCtrl = require('../controllers/parentMonitoringController');
const authMiddleware = require('../middlewares/auth');

/**
 * @openapi
 * /parent-monitoring/{parentId}:
 *   get:
 *     tags: [家长监控]
 *     summary: 获取监控概览
 *     description: 获取某家长所有孩子的监控概览
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: parentId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 家长ID
 *     responses:
 *       200:
 *         description: 成功
 *       403:
 *         description: 无权访问
 */
router.get('/:parentId', authMiddleware, monitoringCtrl.getMonitoringOverview);

/**
 * @openapi
 * /parent-monitoring/{parentId}/child/{childId}:
 *   get:
 *     tags: [家长监控]
 *     summary: 获取单个孩子的监控详情
 *     description: 获取单个孩子的详细监控数据
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: parentId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 家长ID
 *       - name: childId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 孩子ID
 *     responses:
 *       200:
 *         description: 成功
 *       403:
 *         description: 无权访问
 */
router.get('/:parentId/child/:childId', authMiddleware, monitoringCtrl.getChildMonitoringDetail);

/**
 * @openapi
 * /parent-monitoring/{parentId}/child/{childId}/thresholds:
 *   put:
 *     tags: [家长监控]
 *     summary: 更新监控阈值
 *     description: 更新指定孩子的监控阈值设置
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: parentId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 家长ID
 *       - name: childId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 孩子ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               maxDailyStudyTime:
 *                 type: integer
 *                 description: 每日最长学习时长（分钟）
 *                 example: 60
 *               minDailyStudyTime:
 *                 type: integer
 *                 description: 每日最短学习时长（分钟）
 *                 example: 15
 *               minCharactersPerDay:
 *                 type: integer
 *                 description: 每日最少识字数
 *                 example: 3
 *               minAccuracy:
 *                 type: integer
 *                 description: 最低测评准确率（0-100）
 *                 example: 70
 *               maxReviewDelayDays:
 *                 type: integer
 *                 description: 最长复习延迟天数
 *                 example: 2
 *     responses:
 *       200:
 *         description: 更新成功
 *       400:
 *         description: 无效的阈值设置
 *       403:
 *         description: 无权操作
 */
router.put('/:parentId/child/:childId/thresholds', authMiddleware, monitoringCtrl.updateThresholds);

/**
 * @openapi
 * /parent-monitoring/{parentId}/alert-settings:
 *   put:
 *     tags: [家长监控]
 *     summary: 更新告警设置
 *     description: 更新告警方式设置（应用到所有孩子）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: parentId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *         description: 家长ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               enableStudyTimeAlert:
 *                 type: boolean
 *                 description: 是否启用学习时长告警
 *                 example: true
 *               enableAccuracyAlert:
 *                 type: boolean
 *                 description: 是否启用准确率告警
 *                 example: true
 *               enableReviewAlert:
 *                 type: boolean
 *                 description: 是否启用复习告警
 *                 example: true
 *               alertMethods:
 *                 type: array
 *                 items:
 *                   type: string
 *                   enum: [push, sms, wechat]
 *                 description: 告警方式
 *                 example: ["push", "wechat"]
 *     responses:
 *       200:
 *         description: 更新成功
 *       400:
 *         description: 无效的告警设置
 *       403:
 *         description: 无权操作
 */
router.put('/:parentId/alert-settings', authMiddleware, monitoringCtrl.updateAlertSettings);

module.exports = router;
