/**
 * L2绘本书架数据种子脚本（框架版）
 * 用法: node scripts/seed_L2_books.js
 * 
 * 说明：本文件为L2绘本提供seed框架，新字列表待教研员完成后填充
 * 基于：100篇故事教案_总体规划_v1.md（L2起步级，第21-30篇）
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
const Character = require('../src/models/Character');
const config = require('../src/config');

async function seedL2Books() {
  try {
    await mongoose.connect(config.mongodb.uri);
    console.log('[Seed-L2] MongoDB 已连接');
    
    // 查找L2汉字，用于关联（等L2字表导入后使用）
    const l2Chars = await Character.find({ level: 2 }).lean();
    const charMap = {};
    l2Chars.forEach(c => { charMap[c.character] = c._id; });
    
    console.log(`[Seed-L2] 找到 ${l2Chars.length} 个L2汉字`);
    
    // 如果L2汉字还没导入，使用L1汉字作为占位
    const fallbackChars = await Character.find({ level: 1 }).limit(20).lean();
    const fallbackMap = {};
    fallbackChars.forEach(c => { fallbackMap[c.character] = c._id; });
    
    // L2绘本数据（第21-30篇）
    const l2Books = [
      {
        title: '小马的河',
        cover: '/uploads/covers/book_cover_21.png',
        description: '小马过河，学会自己判断',
        level: 2,
        theme: '成长',
        tags: ['成长', '判断', '勇气'],
        protagonist: {
          name: '小马',
          description: '棕色小马驹，勇敢好奇'
        },
        // 新字待教研员完成后填充
        newWords: [],  // 预期18-25字
        newWordCount: 0,  // 待更新
        reviewWords: [],  // 从L1选复习字
        pageCount: 12,
        totalCharacters: 200,
        estimatedMinutes: 8,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'choice', question: '小马最后敢过河了吗？', instruction: '选择：敢/不敢' },
          { type: 'image_match', question: '找出图中的小马', instruction: '认知动物' }
        ],
        isFree: false,
        status: 'draft'  // 草稿状态，等教研员完成内容后改为'published'
      },
      {
        title: '四季的颜色',
        cover: '/uploads/covers/book_cover_22.png',
        description: '春红夏绿秋黄冬白',
        level: 2,
        theme: '自然',
        tags: ['四季', '颜色', '自然'],
        protagonist: {
          name: '小画家',
          description: '喜欢画画的小朋友'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 250,
        estimatedMinutes: 8,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'color_match', question: '春天是什么颜色？', instruction: '选择：红色/绿色/黄色' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '我去上学',
        cover: '/uploads/covers/book_cover_23.png',
        description: '上学路上见闻，方位词',
        level: 2,
        theme: '生活',
        tags: ['上学', '方位', '生活'],
        protagonist: {
          name: '小明',
          description: '一年级小学生'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 300,
        estimatedMinutes: 10,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'direction', question: '学校在家的哪一边？', instruction: '选择：东/西/南/北' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '蚂蚁搬家',
        cover: '/uploads/covers/book_cover_24.png',
        description: '团队合作，天气变化',
        level: 2,
        theme: '自然',
        tags: ['蚂蚁', '团队', '天气'],
        protagonist: {
          name: '小蚂蚁',
          description: '勤劳的蚂蚁工人'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 280,
        estimatedMinutes: 9,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'count', question: '数一数有多少只蚂蚁？', instruction: '计数练习' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '谁最聪明',
        cover: '/uploads/covers/book_cover_25.png',
        description: '不以貌取人',
        level: 2,
        theme: '成长',
        tags: ['智慧', '公平', '成长'],
        protagonist: {
          name: '小动物们',
          description: '森林里的小动物'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 320,
        estimatedMinutes: 10,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'choice', question: '谁最聪明？', instruction: '选择正确答案' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '我的好朋友',
        cover: '/uploads/covers/book_cover_26.png',
        description: '交朋友，分享快乐',
        level: 2,
        theme: '社交',
        tags: ['朋友', '分享', '社交'],
        protagonist: {
          name: '小红',
          description: '善良的小女孩'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 280,
        estimatedMinutes: 9,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'emotion', question: '你的好朋友是谁？', instruction: '引导孩子说出朋友的名字' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '种一棵树',
        cover: '/uploads/covers/book_cover_27.png',
        description: '种树过程，观察成长',
        level: 2,
        theme: '科学',
        tags: ['树', '成长', '科学'],
        protagonist: {
          name: '小园丁',
          description: '喜欢种树的小朋友'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 14,
        totalCharacters: 350,
        estimatedMinutes: 10,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'sequence', question: '种树的顺序是？', instruction: '排序：挖坑→放树苗→填土→浇水' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '春天的故事',
        cover: '/uploads/covers/book_cover_28.png',
        description: '春天万物复苏',
        level: 2,
        theme: '自然',
        tags: ['春天', '复苏', '自然'],
        protagonist: {
          name: '小燕子',
          description: '从南方飞回的燕子'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 300,
        estimatedMinutes: 9,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'image_match', question: '找出春天的景色', instruction: '多选：花/草/树/燕子等' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '妈妈的爱',
        cover: '/uploads/covers/book_cover_29.png',
        description: '母子亲情，感恩',
        level: 2,
        theme: '生活',
        tags: ['妈妈', '爱', '感恩'],
        protagonist: {
          name: '小明',
          description: '感受到妈妈的爱'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 280,
        estimatedMinutes: 9,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'emotion', question: '妈妈爱你吗？你爱妈妈吗？', instruction: '情感引导' }
        ],
        isFree: false,
        status: 'draft'
      },
      {
        title: '小青蛙找家',
        cover: '/uploads/covers/book_cover_30.png',
        description: '两栖动物知识',
        level: 2,
        theme: '自然',
        tags: ['青蛙', '动物', '自然'],
        protagonist: {
          name: '小青蛙',
          description: '迷路的小青蛙'
        },
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 320,
        estimatedMinutes: 10,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [
          { type: 'choice', question: '青蛙的家在哪里？', instruction: '选择：水里/陆地/树上' }
        ],
        isFree: false,
        status: 'draft'
      }
    ];
    
    console.log(`[Seed-L2] 准备导入 ${l2Books.length} 本L2绘本（框架版）`);
    
    // 导入绘本基本信息
    for (const bookData of l2Books) {
      const existing = await Book.findOne({ title: bookData.title });
      if (existing) {
        console.log(`[Seed-L2] 跳过已存在的绘本: ${bookData.title}`);
        continue;
      }
      
      const book = await Book.create(bookData);
      console.log(`[Seed-L2] 已创建绘本: ${bookData.title} (ID: ${book._id})`);
    }
    
    console.log('[Seed-L2] ✅ L2绘本书架数据框架创建完成');
    console.log('[Seed-L2] ⚠️  新字列表待教研员完成后，运行更新脚本填充');
    
  } catch (err) {
    console.error('[Seed-L2] 错误:', err);
  } finally {
    await mongoose.disconnect();
    console.log('[Seed-L2] MongoDB 已断开连接');
  }
}

seedL2Books();
