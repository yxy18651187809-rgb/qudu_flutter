const express = require('express');
const router = express.Router();
const learningController = require('../controllers/learningController');
const authMiddleware = require('../middlewares/auth');

// 需要登录的接口
router.use(authMiddleware);

/**
 * @openapi
 * /learning/record:
 *   post:
 *     tags: [学习记录]
 *     summary: 记录学习数据
 *     description: |
 *       记录一次学习行为并返回奖励。
 *       奖励规则：
 *       - reading: 2星5币（完整阅读绘本）
 *       - word_study: 每对1字1星最多5星，每字2币
 *       - review: 每对1字1星最多3星，每字1币
 *       - game: 1星2币
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [childId, type]
 *             properties:
 *               childId:
 *                 type: string
 *                 description: 儿童ID
 *               type:
 *                 type: string
 *                 enum: [assessment, reading, word_study, review, game]
 *                 description: 学习类型
 *               subtype:
 *                 type: string
 *                 description: 细分类型（如 book_complete）
 *               bookId:
 *                 type: string
 *                 description: 绘本ID（阅读类型时）
 *               characters:
 *                 type: array
 *                 description: 汉字学习结果
 *                 items:
 *                   type: object
 *                   properties:
 *                     characterId: { type: string }
 *                     character: { type: string, example: "人" }
 *                     result: { type: string, enum: [correct, wrong, skip] }
 *                     responseTime: { type: integer, description: 响应时间(ms) }
 *               duration:
 *                 type: integer
 *                 description: 学习时长(秒)
 *                 example: 300
 *               startTime:
 *                 type: string
 *                 format: date-time
 *               endTime:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       200:
 *         description: 记录成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     recordId: { type: string }
 *                     starsEarned: { type: integer, example: 2 }
 *                     coinsEarned: { type: integer, example: 5 }
 *                     correctCount: { type: integer, example: 1 }
 *                     totalCount: { type: integer, example: 2 }
 *                     accuracy: { type: number, example: 50 }
 *                 message: { type: string, example: "success" }
 */
router.post('/record', learningController.recordLearning);

/**
 * @openapi
 * /learning/history/{childId}:
 *   get:
 *     tags: [学习记录]
 *     summary: 获取学习历史
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 儿童ID
 *       - name: type
 *         in: query
 *         schema: { type: string }
 *         description: 学习类型筛选
 *       - name: page
 *         in: query
 *         schema: { type: integer, default: 1 }
 *       - name: pageSize
 *         in: query
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: 成功
 */
router.get('/history/:childId', learningController.getLearningHistory);

/**
 * @openapi
 * /learning/stats/{childId}:
 *   get:
 *     tags: [学习记录]
 *     summary: 获取学习统计
 *     description: |
 *       返回学习统计概览，包括：
 *       - overview: 总体统计（总记录数、总时长、总星数、连续天数、当前级别）
 *       - today: 今日统计
 *       - mastery: 掌握度分布（new/learning/reviewing/mastered/dueReview）
 *       - weeklyTrend: 近7天趋势
 *       
 *       mastery字段说明：
 *       - new: 未学过的字
 *       - learning: 正在学习（掌握度<40%）
 *       - reviewing: 复习中（掌握度40%-80%）
 *       - mastered: 已掌握（掌握度>80%且间隔≥6天）
 *       - dueReview: 今日待复习
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 儿童ID
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
 *                   type: object
 *                   properties:
 *                     overview:
 *                       type: object
 *                       properties:
 *                         totalRecords: { type: integer, example: 25 }
 *                         totalMinutes: { type: integer, example: 120 }
 *                         totalStars: { type: integer, example: 45 }
 *                         streakDays: { type: integer, example: 3 }
 *                         currentLevel: { type: integer, example: 1 }
 *                     today:
 *                       type: object
 *                       properties:
 *                         records: { type: integer, example: 2 }
 *                         minutes: { type: integer, example: 15 }
 *                         stars: { type: integer, example: 5 }
 *                     mastery:
 *                       type: object
 *                       properties:
 *                         new: { type: integer, example: 200 }
 *                         learning: { type: integer, example: 30 }
 *                         reviewing: { type: integer, example: 15 }
 *                         mastered: { type: integer, example: 5 }
 *                         dueReview: { type: integer, example: 8 }
 *                     weeklyTrend:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           _id: { type: string, example: "2026-04-16" }
 *                           count: { type: integer }
 *                           minutes: { type: integer }
 *                           stars: { type: integer }
 *                 message: { type: string, example: "success" }
 */
router.get('/stats/:childId', learningController.getLearningStats);

module.exports = router;
