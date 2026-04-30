/**
 * 测评题目生成器
 *
 * 核心功能：
 * 1. generateDistractors - 5级干扰项策略（形近字 > 同绘本新字 > 同主题字 > 音近字 > 随机L1字）
 * 2. generateBookQuestions - 按绘本新字出题，按题型分配
 * 3. generateLevelQuestions - 按级别出题（initial / level_test）
 *
 * 配合 Assessment API v1.1 对齐测字题库设计
 */

const Character = require('../models/Character');
const Book = require('../models/Book');

// ========== 主题映射表（教研提供 v1.1）==========
const THEME_MAP = {
  '身体部位': ['口', '耳', '眼', '手', '头', '心', '足', '牙'],
  '日常问候': ['早', '上', '好', '天', '笑', '再', '见', '请'],
  '自然动物': ['兔', '大', '小', '妈', '白', '飞', '鸟', '林'],
  '校园':     ['一', '二', '三', '去', '学', '校', '见', '对'],
  '自然现象': ['太', '阳', '红', '花', '绿', '草', '风', '雨'],
  '食物':     ['好', '吃', '果', '子', '大', '小', '多', '少'],
  '动物':     ['猫', '狗', '鸡', '鱼', '鸟', '小', '大', '白'],
  '四季':     ['春', '夏', '秋', '冬', '花', '雪', '风', '雨'],
  '家庭':     ['家', '人', '爸', '妈', '我', '你', '他', '爱'],
  '公园':     ['公', '园', '花', '草', '树', '山', '水', '玩']
};

// ========== 形近字映射表（常见L1形近字对）==========
const SIMILAR_SHAPE_MAP = {
  '人': ['入', '八'],
  '入': ['人', '八'],
  '八': ['人', '入'],
  '大': ['太', '天', '犬'],
  '太': ['大', '天'],
  '天': ['大', '太', '夫'],
  '小': ['少', '水'],
  '少': ['小', '水'],
  '手': ['毛'],
  '毛': ['手'],
  '日': ['曰', '白', '目'],
  '白': ['日', '目', '自'],
  '目': ['日', '白', '自'],
  '自': ['白', '目'],
  '田': ['由', '甲', '申'],
  '口': ['日', '曰'],
  '十': ['千', '土'],
  '土': ['士', '十'],
  '千': ['十', '干'],
  '干': ['千', '士'],
  '上': ['下', '土'],
  '下': ['上'],
  '山': ['出'],
  '出': ['山'],
  '木': ['本', '禾', '未'],
  '本': ['木', '未'],
  '禾': ['木'],
  '未': ['木', '本', '末'],
  '末': ['未', '本'],
  '牛': ['午', '生'],
  '午': ['牛'],
  '生': ['牛', '土'],
  '子': ['了', '字'],
  '了': ['子'],
  '月': ['目', '用'],
  '用': ['月', '周'],
  '开': ['井', '并'],
  '并': ['开', '井'],
  '井': ['开', '并'],
  '见': ['贝'],
  '贝': ['见'],
  '己': ['已', '巳'],
  '已': ['己', '巳'],
  '巳': ['己', '已'],
  '人': ['入', '八'],
  '左': ['右', '在'],
  '右': ['左'],
  '对': ['树'],
  '鸟': ['乌'],
  '乌': ['鸟'],
  '兔': ['免'],
  '免': ['兔'],
  '中': ['巾', '串'],
  '巾': ['中'],
  '长': ['张'],
  '方': ['万'],
  '万': ['方'],
  '心': ['必'],
  '必': ['心'],
  '水': ['冰', '小'],
  '火': ['灭'],
  '灭': ['火'],
  '王': ['玉', '主'],
  '玉': ['王'],
  '主': ['王'],
  '石': ['右'],
};

// ========== 测评类型配置 ==========
const ASSESSMENT_CONFIG = {
  initial: {
    totalQuestions: 20,
    typeDistribution: {
      recognize: 8,       // 40%
      meaning_select: 7,  // 35%
      pinyin_match: 5     // 25%
    }
  },
  review: {
    totalQuestions: 10,   // 绘本新字≤15时用10题
    typeDistribution: {
      recognize: 5,       // 50%
      meaning_select: 3,  // 30%
      pinyin_match: 2     // 20%
    }
  },
  level_test: {
    totalQuestions: 20,
    typeDistribution: {
      recognize: 8,       // 40%
      meaning_select: 7,  // 35%
      pinyin_match: 5     // 25%
    }
  }
};

// ========== 核心函数 ==========

/**
 * 生成干扰项
 * 5级策略 fallback：形近字 > 同绘本新字 > 同主题字 > 音近字 > 随机L1字
 *
 * @param {Object} correctChar - 正确汉字文档（需含 character, pinyin, level 等字段）
 * @param {Object} options
 * @param {Array} options.bookNewWordChars - 同绘本新字列表（汉字字符串数组）
 * @param {string} options.theme - 绘本主题标签
 * @param {Array} options.excludeChars - 排除的汉字列表（含正确答案）
 * @param {number} options.count - 需要的干扰项数量，默认3
 * @param {Object} options.CharacterModel - Character Model
 * @returns {Promise<string[]>} 干扰项列表
 */
async function generateDistractors(correctChar, options = {}) {
  const {
    bookNewWordChars = [],
    theme = '',
    excludeChars = [],
    count = 3,
    CharacterModel = Character
  } = options;

  const correctCharStr = correctChar.character;
  const correctPinyin = correctChar.pinyin || '';
  // 提取拼音去掉声调进行比较
  const correctPinyinBase = stripTone(correctPinyin);
  const correctTone = correctChar.tone || 0;

  const allExclude = new Set([correctCharStr, ...excludeChars]);
  const distractors = [];

  // 策略1: 形近字
  const shapeSimilar = (SIMILAR_SHAPE_MAP[correctCharStr] || [])
    .filter(c => !allExclude.has(c));
  for (const c of shapeSimilar) {
    if (distractors.length >= count) break;
    if (!distractors.includes(c)) {
      distractors.push(c);
    }
  }

  // 策略2: 同绘本新字
  if (distractors.length < count) {
    const bookWords = bookNewWordChars
      .filter(c => !allExclude.has(c) && !distractors.includes(c));
    for (const c of bookWords) {
      if (distractors.length >= count) break;
      distractors.push(c);
    }
  }

  // 策略3: 同主题字
  if (distractors.length < count && theme && THEME_MAP[theme]) {
    const themeWords = THEME_MAP[theme]
      .filter(c => !allExclude.has(c) && !distractors.includes(c));
    for (const c of themeWords) {
      if (distractors.length >= count) break;
      distractors.push(c);
    }
  }

  // 策略4: 音近字（同拼音不同声调，或拼音相似）
  if (distractors.length < count) {
    // 从数据库查同拼音基字的汉字
    const pinyinSimilar = await CharacterModel.find({
      pinyin: { $regex: `^${escapeRegex(correctPinyinBase)}`, $options: 'i' },
      character: { $ne: correctCharStr },
      status: 'active'
    }).limit(10).lean();

    // 优先选不同声调的
    const toneDifferent = pinyinSimilar
      .filter(c => !allExclude.has(c.character) && !distractors.includes(c.character) && c.tone !== correctTone)
      .map(c => c.character);

    for (const c of toneDifferent) {
      if (distractors.length >= count) break;
      distractors.push(c);
    }

    // 如果不够，同声调也可以
    if (distractors.length < count) {
      const sameTone = pinyinSimilar
        .filter(c => !allExclude.has(c.character) && !distractors.includes(c.character))
        .map(c => c.character);
      for (const c of sameTone) {
        if (distractors.length >= count) break;
        distractors.push(c);
      }
    }
  }

  // 策略5: 随机L1字（最终兜底）
  if (distractors.length < count) {
    const randomChars = await CharacterModel.find({
      level: correctChar.level || 1,
      character: { $ne: correctCharStr },
      status: 'active',
      character: { $nin: [...allExclude, ...distractors] }
    }).limit(20).lean();

    const shuffled = shuffleArray(randomChars);
    for (const c of shuffled) {
      if (distractors.length >= count) break;
      if (!distractors.includes(c.character) && !allExclude.has(c.character)) {
        distractors.push(c.character);
      }
    }
  }

  return distractors.slice(0, count);
}

/**
 * 按绘本新字生成题目
 * 从 Book.newWords 取字，按题型分配
 *
 * @param {string} bookId - 绘本ID
 * @param {Object} options
 * @param {number} options.questionCount - 题目数量，默认10
 * @param {Object} options.CharacterModel - Character Model
 * @param {Object} options.BookModel - Book Model
 * @returns {Promise<Array>} 题目列表
 */
async function generateBookQuestions(bookId, options = {}) {
  const {
    questionCount = 10,
    CharacterModel = Character,
    BookModel = Book
  } = options;

  // 1. 获取绘本数据
  const book = await BookModel.findById(bookId).lean();
  if (!book) {
    throw new Error('绘本不存在');
  }

  // 2. 获取绘本新字
  const newWordIds = book.newWords || [];
  if (newWordIds.length === 0) {
    throw new Error('绘本没有新字配置');
  }

  const characters = await CharacterModel.find({
    _id: { $in: newWordIds },
    status: 'active'
  }).lean();

  if (characters.length === 0) {
    throw new Error('绘本新字查询为空');
  }

  // 3. 按题型分配
  const config = ASSESSMENT_CONFIG.review;
  const actualCount = Math.min(questionCount, characters.length);
  const distribution = adjustDistribution(config.typeDistribution, actualCount);

  const questions = [];
  const usedCharacters = new Set();
  const bookNewWordChars = characters.map(c => c.character);

  // 构建汉字→文档映射，用于 buildQuestion 中的拼音/释义转换
  const charMap = {};
  characters.forEach(c => { charMap[c.character] = c; });

  // 按题型逐批出题，确保每字至少出现1次
  for (const [qType, count] of Object.entries(distribution)) {
    for (let i = 0; i < count; i++) {
      // 优先选择未用过的字，确保覆盖
      let charPool = characters.filter(c => !usedCharacters.has(c._id.toString()));
      if (charPool.length === 0) {
        // 所有字都用过了，重置允许复用
        charPool = characters;
      }

      const selectedChar = charPool[i % charPool.length] || charPool[Math.floor(Math.random() * charPool.length)];
      usedCharacters.add(selectedChar._id.toString());

      const distractors = await generateDistractors(selectedChar, {
        bookNewWordChars,
        theme: book.theme || '',
        excludeChars: [],
        count: 3,
        CharacterModel
      });

      // 将干扰项汉字对应的文档也加入 charMap
      for (const d of distractors) {
        if (!charMap[d]) {
          const dDoc = await CharacterModel.findOne({ character: d, status: 'active' }).lean();
          if (dDoc) charMap[d] = dDoc;
        }
      }

      const question = buildQuestion(selectedChar, qType, distractors, charMap);
      questions.push(question);
    }
  }

  return shuffleArray(questions);
}

/**
 * 按级别生成题目（initial / level_test 场景）
 *
 * @param {Object} options
 * @param {string} options.type - 测评类型: 'initial' | 'level_test'
 * @param {number} options.targetLevel - 目标级别
 * @param {number} options.questionCount - 题目数量（覆盖默认配置）
 * @param {Array} options.knownCharacters - 已知汉字ID列表
 * @param {Object} options.CharacterModel - Character Model
 * @returns {Promise<Array>} 题目列表
 */
async function generateLevelQuestions(options = {}) {
  const {
    type = 'initial',
    targetLevel = 1,
    questionCount,
    knownCharacters = [],
    CharacterModel = Character
  } = options;

  const config = ASSESSMENT_CONFIG[type] || ASSESSMENT_CONFIG.initial;
  const totalCount = questionCount || config.totalQuestions;
  const distribution = adjustDistribution(config.typeDistribution, totalCount);

  // 从目标级别及相邻级别抽汉字
  const levels = [targetLevel];
  if (targetLevel > 1) levels.push(targetLevel - 1);
  if (targetLevel < 5) levels.push(targetLevel + 1);

  const excludeIds = knownCharacters.map(id => {
    try { return new (require('mongoose').Types.ObjectId)(id); } catch { return id; }
  });

  const characters = await CharacterModel.find({
    level: { $in: levels },
    status: 'active',
    _id: { $nin: excludeIds }
  }).lean();

  if (characters.length === 0) {
    throw new Error('没有可用的汉字出题');
  }

  const questions = [];
  const usedCharacters = new Set();

  // 构建汉字→文档映射，用于 buildQuestion 中的拼音/释义转换
  const charMap = {};
  characters.forEach(c => { charMap[c.character] = c; });

  for (const [qType, count] of Object.entries(distribution)) {
    for (let i = 0; i < count; i++) {
      let charPool = characters.filter(c => !usedCharacters.has(c._id.toString()));
      if (charPool.length === 0) {
        // 允许复用
        usedCharacters.clear();
        charPool = characters;
      }

      const selectedChar = charPool[Math.floor(Math.random() * charPool.length)];
      usedCharacters.add(selectedChar._id.toString());

      const distractors = await generateDistractors(selectedChar, {
        bookNewWordChars: [],
        theme: '',
        excludeChars: [],
        count: 3,
        CharacterModel
      });

      // 将干扰项汉字对应的文档也加入 charMap
      for (const d of distractors) {
        if (!charMap[d]) {
          const dDoc = await CharacterModel.findOne({ character: d, status: 'active' }).lean();
          if (dDoc) charMap[d] = dDoc;
        }
      }

      const question = buildQuestion(selectedChar, qType, distractors, charMap);
      questions.push(question);
    }
  }

  return shuffleArray(questions);
}

// ========== 辅助函数 ==========

/**
 * 构建单道题目
 *
 * 题型说明：
 * - recognize: 看字选拼音（正确答案是拼音，选项是拼音列表）
 * - pinyin_match: 看拼音选字（正确答案是汉字，选项是汉字列表）
 * - meaning_select: 看字选意思（正确答案是释义，选项是释义列表）
 *
 * 干扰项(distractors)始终是汉字字符串，buildQuestion 内部按题型转换：
 * - recognize → 将干扰汉字转为拼音
 * - meaning_select → 将干扰汉字转为释义
 * - pinyin_match → 直接使用汉字
 *
 * @param {Object} charDoc - 汉字文档
 * @param {string} questionType - 题型
 * @param {string[]} distractors - 干扰项（汉字字符串）
 * @param {Object} charMap - 汉字→文档映射（用于查拼音和释义）
 * @returns {Object} 题目对象
 */
function buildQuestion(charDoc, questionType, distractors, charMap = {}) {
  const question = {
    characterId: charDoc._id,
    character: charDoc.character,
    questionType,
    options: [],
    correctAnswer: '',
    audioUrl: `/audio/${charDoc.character}.mp3`  // 前端直接使用的音频URL
  };

  switch (questionType) {
    case 'recognize':
      // 看字选拼音：正确答案是拼音，选项是拼音列表
      question.correctAnswer = charDoc.pinyin;
      // 将干扰汉字转换为拼音
      const pinyinOptions = distractors.map(d => {
        const dDoc = charMap[d];
        if (dDoc && dDoc.pinyin) return dDoc.pinyin;
        // 如果 charMap 中没有该干扰项，说明是数据库查不到的异常值
        // 跳过，后续补位
        return null;
      }).filter(p => p !== null);
      // 如果干扰项不足3个拼音，用通用拼音补位
      const fallbackPinyins = ['dà', 'xiǎo', 'rén', 'shàng', 'xià', 'tiān', 'shuǐ', 'huǒ', 'shān', 'mù'];
      const usedPinyins = new Set([charDoc.pinyin, ...pinyinOptions]);
      for (const fp of fallbackPinyins) {
        if (pinyinOptions.length >= 3) break;
        if (!usedPinyins.has(fp)) {
          pinyinOptions.push(fp);
          usedPinyins.add(fp);
        }
      }
      question.options = shuffleArray([charDoc.pinyin, ...pinyinOptions.slice(0, 3)]);
      break;

    case 'pinyin_match':
      // 看拼音选字：正确答案是汉字，选项是汉字列表
      question.correctAnswer = charDoc.character;
      question.options = shuffleArray([charDoc.character, ...distractors]);
      break;

    case 'meaning_select':
      // 看字选意思：正确答案是释义，选项是释义列表
      const meaning = charDoc.meanings?.[0]?.meaning || charDoc.character;
      question.correctAnswer = meaning;
      // 将干扰汉字转换为释义
      const meaningOptions = distractors.map(d => {
        const dDoc = charMap[d];
        if (dDoc && dDoc.meanings?.[0]?.meaning) return dDoc.meanings[0].meaning;
        return null;
      }).filter(m => m !== null);
      // 如果干扰项不足3个释义，用通用释义补位
      const fallbackMeanings = ['数字一', '大', '小', '人', '天空', '水', '山', '花朵', '太阳', '动物'];
      const usedMeanings = new Set([meaning, ...meaningOptions]);
      for (const fm of fallbackMeanings) {
        if (meaningOptions.length >= 3) break;
        if (!usedMeanings.has(fm)) {
          meaningOptions.push(fm);
          usedMeanings.add(fm);
        }
      }
      question.options = shuffleArray([meaning, ...meaningOptions.slice(0, 3)]);
      break;
  }

  return question;
}

/**
 * 调整题型分布，使总数匹配实际题目数
 *
 * @param {Object} distribution - 原始分布 { recognize: N, meaning_select: N, pinyin_match: N }
 * @param {number} totalCount - 实际题目总数
 * @returns {Object} 调整后的分布
 */
function adjustDistribution(distribution, totalCount) {
  const totalInDist = Object.values(distribution).reduce((sum, v) => sum + v, 0);
  if (totalInDist === totalCount) return { ...distribution };

  // 按比例缩放
  const result = {};
  let assigned = 0;
  const keys = Object.keys(distribution);

  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (i === keys.length - 1) {
      // 最后一个类型取剩余数量
      result[key] = totalCount - assigned;
    } else {
      result[key] = Math.round(distribution[key] / totalInDist * totalCount);
      assigned += result[key];
    }
  }

  return result;
}

/**
 * 去掉拼音声调符号
 * 例：'nǐ' → 'ni', 'hǎo' → 'hao'
 */
function stripTone(pinyin) {
  if (!pinyin) return '';
  const toneMap = {
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    'ǖ': 'v', 'ǘ': 'v', 'ǚ': 'v', 'ǜ': 'v',
  };
  return pinyin.split('').map(c => toneMap[c] || c).join('');
}

/**
 * 转义正则特殊字符
 */
function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * 随机打乱数组
 */
function shuffleArray(array) {
  const arr = [...array];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

module.exports = {
  generateDistractors,
  generateBookQuestions,
  generateLevelQuestions,
  buildQuestion,
  adjustDistribution,
  ASSESSMENT_CONFIG,
  THEME_MAP,
  SIMILAR_SHAPE_MAP,
  stripTone,
  shuffleArray
};
