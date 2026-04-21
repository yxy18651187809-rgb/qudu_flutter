const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');
const { optionalAuth } = require('../middlewares/auth');

/**
 * @openapi
 * /books/themes:
 *   get:
 *     tags: [绘本模块]
 *     summary: 获取主题列表
 *     description: 返回所有可用绘本主题及其数量
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
 *                       theme: { type: string, example: "身体认知" }
 *                       count: { type: integer, example: 1 }
 *                 message: { type: string, example: "success" }
 */
router.get('/themes', bookController.getThemes);

/**
 * @openapi
 * /books/free:
 *   get:
 *     tags: [绘本模块]
 *     summary: 获取免费绘本
 *     parameters:
 *       - name: level
 *         in: query
 *         schema: { type: integer }
 *         description: 级别筛选
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
router.get('/free', bookController.getFreeBooks);

/**
 * @openapi
 * /books/recommended:
 *   get:
 *     tags: [绘本模块]
 *     summary: 智能推荐绘本
 *     description: |
 *       基于儿童级别和新字掌握率推荐绘本：
 *       - 无childId → 返回热门绘本
 *       - 有childId → 覆盖率30%-70%优先，不足补充相邻级别
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: childId
 *         in: query
 *         schema: { type: string }
 *         description: 儿童ID（传入后个性化推荐）
 *       - name: limit
 *         in: query
 *         schema: { type: integer, default: 6 }
 *         description: 返回数量
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
 *                           title: { type: string, example: "我的身体" }
 *                           level: { type: integer, example: 1 }
 *                           newWordCount: { type: integer, example: 15 }
 *                           newWordMasteryRate: { type: number, example: 0.2 }
 *                           isFree: { type: boolean, example: true }
 *                     childLevel: { type: integer, example: 1 }
 *                     reason: { type: string, example: "基于L1级别推荐" }
 *                 message: { type: string, example: "success" }
 */
router.get('/recommended', optionalAuth, bookController.getRecommendedBooks);

/**
 * @openapi
 * /books:
 *   get:
 *     tags: [绘本模块]
 *     summary: 获取绘本列表
 *     description: 支持按级别、主题、免费状态筛选和排序
 *     parameters:
 *       - name: level
 *         in: query
 *         schema: { type: string }
 *         description: 级别筛选，逗号分隔（如 "1,2"）
 *       - name: theme
 *         in: query
 *         schema: { type: string }
 *         description: 主题筛选
 *       - name: isFree
 *         in: query
 *         schema: { type: boolean }
 *         description: 是否免费
 *       - name: sort
 *         in: query
 *         schema: { type: string, default: "sortOrder" }
 *         description: 排序方式（sortOrder/popular/newest/rating）
 *       - name: page
 *         in: query
 *         schema: { type: integer, default: 1 }
 *       - name: pageSize
 *         in: query
 *         schema: { type: integer, default: 20 }
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
 *                           title: { type: string, example: "我的身体" }
 *                           cover: { type: string }
 *                           description: { type: string, example: "认识身体、学会爱护自己" }
 *                           level: { type: integer, example: 1 }
 *                           theme: { type: string, example: "身体认知" }
 *                           tags: { type: array, items: { type: string } }
 *                           newWordCount: { type: integer, example: 15 }
 *                           pageCount: { type: integer, example: 10 }
 *                           estimatedMinutes: { type: integer, example: 5 }
 *                           isFree: { type: boolean, example: true }
 *                           readCount: { type: integer, example: 0 }
 *                           rating: { type: number, example: 5 }
 *                     pagination:
 *                       $ref: '#/components/schemas/Pagination'
 *                 message: { type: string, example: "success" }
 */
router.get('/', bookController.getBooks);

/**
 * @openapi
 * /books/{id}:
 *   get:
 *     tags: [绘本模块]
 *     summary: 获取绘本详情（含页面）
 *     description: 返回绘本完整信息，包含所有页面及生字标注。传childId后额外返回新字掌握进度。
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 绘本ID
 *       - name: childId
 *         in: query
 *         schema: { type: string }
 *         description: 儿童ID（传入后返回新字掌握进度）
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
 *                     id: { type: string }
 *                     title: { type: string, example: "我的身体" }
 *                     level: { type: integer, example: 1 }
 *                     theme: { type: string }
 *                     newWords: { type: array, items: { type: string }, description: 新字ID列表 }
 *                     newWordCount: { type: integer, example: 15 }
 *                     reviewWords: { type: array, items: { type: string }, description: 复习字ID列表 }
 *                     exercises:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           type: { type: string, example: "image_match" }
 *                           question: { type: string }
 *                           instruction: { type: string }
 *                     pages:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id: { type: string }
 *                           pageNumber: { type: integer, example: 1 }
 *                           text: { type: string, example: "我是小明。" }
 *                           pinyin: { type: string, example: "[wǒ shì xiǎo míng]" }
 *                           image: { type: string }
 *                           imageDescription: { type: string }
 *                           wordAnnotations:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 characterId: { type: string }
 *                                 character: { type: string, example: "我" }
 *                                 isNewWord: { type: boolean, example: true }
 *                                 highlightStyle: { type: string, enum: [underline, color, both], example: "both" }
 *                           teachingNote: { type: string }
 *                     newWordProgress:
 *                       type: array
 *                       description: 仅传childId时返回
 *                       items:
 *                         type: object
 *                         properties:
 *                           characterId: { type: string }
 *                           mastered: { type: boolean }
 *                     masteredCount: { type: integer, description: 已掌握新字数 }
 *                 message: { type: string, example: "success" }
 *       404:
 *         description: 绘本不存在
 */
router.get('/:id', optionalAuth, bookController.getBookDetail);

module.exports = router;
