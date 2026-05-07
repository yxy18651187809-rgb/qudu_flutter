const express = require('express');
const router = express.Router();
const ttsController = require('../controllers/ttsController');
const { optionalAuth } = require('../middlewares/auth');

/**
 * @openapi
 * /tts/character/{char}:
 *   get:
 *     tags: [朗读模块]
 *     summary: 获取汉字发音音频
 *     parameters:
 *       - name: char
 *         in: path
 *         required: true
 *         schema: { type: string }
 *         description: 单个汉字
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
 *                     character: { type: string, example: "大" }
 *                     pinyin: { type: string, example: "dà" }
 *                     audioUrl: { type: string, example: "/audio/大.mp3" }
 *                 message: { type: string, example: "success" }
 *       404:
 *         description: 汉字不存在
 */
router.get('/character/:char', optionalAuth, ttsController.getCharacterAudio);

module.exports = router;
