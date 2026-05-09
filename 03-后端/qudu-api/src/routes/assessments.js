const express = require('express');
const router = express.Router();
const assessmentController = require('../controllers/assessmentController');
const authMiddleware = require('../middlewares/auth');

// 需要登录的接口
router.use(authMiddleware);

/**
 * @openapi
 * /assessments/start:
 *   post:
 *     tags: [识字测评]
 *     summary: 开始测评
 *     description: |
 *       创建一次识字测评，返回题目列表。
 *       - 如有进行中测评，直接返回已有测评
 *       - questionType三种：recognize(看字选拼音)、pinyin_match(看拼音选字)、meaning_select(选意思)
 *       - 响应不含correctAnswer，防作弊
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [childId]
 *             properties:
 *               childId:
 *                 type: string
 *                 description: 儿童ID
 *                 example: "6800..."
 *               type:
 *                 type: string
 *                 enum: [initial, review, level_test]
 *                 default: initial
 *                 description: 测评类型
 *               targetLevel:
 *                 type: integer
 *                 description: 目标级别（默认取儿童当前级别）
 *                 example: 1
 *               questionCount:
 *                 type: integer
 *                 default: 20
 *                 description: 题目数量
 *     responses:
 *       200:
 *         description: 测评创建成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     assessmentId: { type: string }
 *                     type: { type: string, example: "initial" }
 *                     status: { type: string, example: "in_progress" }
 *                     questions:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           characterId: { type: string }
 *                           character: { type: string, example: "人" }
 *                           questionType: { type: string, enum: [recognize, pinyin_match, meaning_select] }
 *                           options: { type: array, items: { type: string }, example: ["rén", "bā", "dà", "xiǎo"] }
 *                     startedAt: { type: string, format: date-time }
 *                 message: { type: string, example: "success" }
 */
router.post('/start', assessmentController.startAssessment);

/**
 * @openapi
 * /assessments/{id}/submit:
 *   post:
 *     tags: [识字测评]
 *     summary: 提交测评答案
 *     description: |
 *       提交测评答案并自动计算结果。
 *       - 自动更新儿童级别、汉字掌握度（遗忘曲线）、学习记录
 *       - 识字量估算基于各级别正确率加权计算
 *       - 奖励：每题正确1星（最多10星），每题3币（最多30币）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 测评ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [answers]
 *             properties:
 *               answers:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required: [characterId, userAnswer]
 *                   properties:
 *                     characterId: { type: string, description: 汉字ID }
 *                     userAnswer: { type: string, description: 用户答案 }
 *                     responseTime: { type: integer, description: 响应时间(ms) }
 *               duration:
 *                 type: integer
 *                 description: 测评总时长(秒)
 *                 example: 180
 *     responses:
 *       200:
 *         description: 提交成功
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 code: { type: integer, example: 0 }
 *                 data:
 *                   type: object
 *                   properties:
 *                     assessmentId: { type: string }
 *                     status: { type: string, example: "completed" }
 *                     correctCount: { type: integer, example: 15 }
 *                     totalCount: { type: integer, example: 20 }
 *                     accuracy: { type: number, example: 75 }
 *                     estimatedWordCount: { type: integer, example: 120, description: 估算识字量 }
 *                     recommendedLevel: { type: integer, example: 1, description: 推荐级别 }
 *                     levelResults:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           level: { type: integer }
 *                           testedCount: { type: integer }
 *                           correctCount: { type: integer }
 *                           accuracy: { type: number }
 *                     starsEarned: { type: integer, example: 10 }
 *                     coinsEarned: { type: integer, example: 30 }
 *                     duration: { type: integer, example: 180 }
 *                 message: { type: string, example: "success" }
 */
router.post('/:id/submit', assessmentController.submitAssessment);

/**
 * @openapi
 * /assessments/{id}:
 *   get:
 *     tags: [识字测评]
 *     summary: 获取测评结果
 *     description: 返回完整测评记录（含题目详情和正确答案）
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 测评ID
 *     responses:
 *       200:
 *         description: 成功
 *       404:
 *         description: 测评不存在
 */

// 明确处理 /start GET 请求（避免被 /:id 路由匹配）
router.get('/start', (req, res) => {
  res.status(405).json({ code: 40501, data: null, message: '请使用POST方法开始测评' });
});

router.get('/:id', assessmentController.getAssessmentResult);

/**
 * @openapi
 * /assessments/history/{childId}:
 *   get:
 *     tags: [识字测评]
 *     summary: 获取测评历史
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 儿童ID
 *       - name: page
 *         in: query
 *         schema: { type: integer, default: 1 }
 *       - name: pageSize
 *         in: query
 *         schema: { type: integer, default: 10 }
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
 *                     list:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id: { type: string }
 *                           type: { type: string, example: "initial" }
 *                           status: { type: string, example: "completed" }
 *                           correctCount: { type: integer, example: 15 }
 *                           totalCount: { type: integer, example: 20 }
 *                           accuracy: { type: number, example: 75 }
 *                           estimatedWordCount: { type: integer, example: 120 }
 *                           recommendedLevel: { type: integer, example: 1 }
 *                           startedAt: { type: string, format: date-time }
 *                           completedAt: { type: string, format: date-time }
 *                           duration: { type: integer, example: 180 }
 *                     pagination:
 *                       $ref: '#/components/schemas/Pagination'
 *                 message: { type: string, example: "success" }
 */
router.get('/history/:childId', assessmentController.getAssessmentHistory);

module.exports = router;
