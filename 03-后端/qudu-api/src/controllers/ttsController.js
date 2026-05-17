const mongoose = require('mongoose');
const Book = require('../models/Book');
const BookPage = require('../models/BookPage');
const Character = require('../models/Character');
const { success, error } = require('../utils/response');

/**
 * 获取绘本页面朗读音频
 * GET /api/v1/books/:id/tts
 *
 * Query 参数：
 * - page: 页码（可选），不传则返回所有页音频
 *
 * 设计说明：
 * - 优先使用预生成的页面朗读音频（/audio/books/{bookId}_p{page}.mp3）
 * - 如果预生成音频不存在，返回该页文本+逐字音频URL列表，由前端拼接播放
 * - Phase 2 可接入 TTS API（如 Azure/Google TTS）实现实时合成
 */
exports.getBookTTS = async (req, res) => {
  try {
    const { id } = req.params;
    const { page } = req.query;

    // 查找绘本
    const orConditions = [{ bookId: id }];
    if (mongoose.Types.ObjectId.isValid(id)) {
      orConditions.push({ _id: id });
    }
    const book = await Book.findOne({ $or: orConditions }).lean();
    if (!book) {
      return error(res, 40401, '绘本不存在', 404);
    }

    // 获取页面
    let pages;
    if (page) {
      const pageNum = parseInt(page);
      if (isNaN(pageNum) || pageNum < 1) {
        return error(res, 40010, '页码必须为正整数', 400);
      }
      const pageDoc = await BookPage.findOne({
        bookId: book._id,
        pageNumber: pageNum
      }).lean();
      if (!pageDoc) {
        return error(res, 40401, '页面不存在', 404);
      }
      pages = [pageDoc];
    } else {
      pages = await BookPage.find({ bookId: book._id })
        .sort({ pageNumber: 1 })
        .lean();
    }

    // 构建音频响应
    const audioPages = await Promise.all(pages.map(async (p) => {
      // 1. 预生成音频URL（如果存在）
      const preGeneratedUrl = `/audio/books/${book.bookId}_p${p.pageNumber}.mp3`;

      // 2. 逐字音频URL列表（用于前端逐字播放）
      const charAudios = [];
      if (p.wordAnnotations && p.wordAnnotations.length > 0) {
        for (const annotation of p.wordAnnotations) {
          if (annotation.character) {
            charAudios.push({
              character: annotation.character,
              isNewWord: annotation.isNewWord || false,
              audioUrl: `/audio/${annotation.character}.mp3`
            });
          }
        }
      }

      // 3. 页面纯文本（用于前端 TTS 合成）
      const text = p.text || '';

      return {
        pageNumber: p.pageNumber,
        text,
        audio: {
          preGenerated: preGeneratedUrl,
          charByChar: charAudios
        }
      };
    }));

    const responseData = page
      ? audioPages[0]
      : {
          bookId: book._id,
          title: book.title,
          totalPages: pages.length,
          pages: audioPages
        };

    return success(res, responseData);
  } catch (err) {
    console.error('获取绘本TTS失败:', err);
    return error(res, 50001, '获取绘本朗读音频失败', 500);
  }
};

/**
 * 获取汉字发音音频
 * GET /api/v1/tts/character/:char
 *
 * 返回单个汉字的发音音频URL
 */
exports.getCharacterAudio = async (req, res) => {
  try {
    const { char } = req.params;

    if (!char || char.length !== 1) {
      return error(res, 40010, '请传入单个汉字', 400);
    }

    const character = await Character.findOne({
      character: char,
      status: 'active'
    }).lean();

    if (!character) {
      return error(res, 40401, '汉字不存在', 404);
    }

    return success(res, {
      character: character.character,
      pinyin: character.pinyin,
      audioUrl: character.audioUrl || `/audio/${character.character}.mp3`
    });
  } catch (err) {
    console.error('获取汉字音频失败:', err);
    return error(res, 50001, '获取汉字音频失败', 500);
  }
};
