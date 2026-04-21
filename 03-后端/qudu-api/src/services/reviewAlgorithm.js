/**
 * 艾宾浩斯遗忘曲线算法（SM-2变体）
 * 
 * 用于计算汉字复习间隔和掌握度
 * 核心参数：
 * - easeFactor: 难度因子，初始2.5，范围[1.3, 3.0]
 * - currentInterval: 当前复习间隔（天）
 * - masteryScore: 掌握度评分[0, 100]
 */

/**
 * 计算下次复习时间和间隔
 * @param {Object} mastery - 当前掌握度记录
 * @param {string} result - 本次结果: 'correct' | 'wrong' | 'skipped'
 * @returns {Object} { nextInterval, easeFactor, nextReviewAt, masteryScore, stage }
 */
function calculateNextReview(mastery, result) {
  let { currentInterval = 1, easeFactor = 2.5, masteryScore = 0 } = mastery;

  if (result === 'correct') {
    // 正确：间隔递增
    if (currentInterval === 1) {
      currentInterval = 1;  // 第1次正确 → 1天后复习
    } else if (currentInterval <= 2) {
      currentInterval = 3;  // 第2次正确 → 3天后复习
    } else if (currentInterval <= 5) {
      currentInterval = 6;  // 3-5天 → 6天后
    } else {
      currentInterval = Math.round(currentInterval * easeFactor);
    }
    // 增加难度因子
    easeFactor = Math.min(3.0, easeFactor + 0.1);
    // 增加掌握度
    masteryScore = Math.min(100, masteryScore + 15);

  } else if (result === 'wrong') {
    // 错误：重置间隔
    currentInterval = 1;
    // 降低难度因子
    easeFactor = Math.max(1.3, easeFactor - 0.2);
    // 降低掌握度
    masteryScore = Math.max(0, masteryScore - 20);

  } else {
    // 跳过：保持当前间隔，轻微降低掌握度
    masteryScore = Math.max(0, masteryScore - 5);
  }

  // 计算下次复习时间
  const nextReviewAt = addDays(new Date(), currentInterval);

  // 计算学习阶段
  const stage = calculateStage(masteryScore, currentInterval);

  return {
    nextInterval: currentInterval,
    easeFactor,
    nextReviewAt,
    masteryScore,
    stage
  };
}

/**
 * 计算学习阶段
 */
function calculateStage(masteryScore, currentInterval) {
  if (masteryScore >= 80 && currentInterval >= 6) return 'mastered';
  if (masteryScore >= 40) return 'reviewing';
  if (masteryScore > 0) return 'learning';
  return 'new';
}

/**
 * 估算识字量
 * 基于各级别测评正确率，用加权估算法
 * 
 * @param {Array} levelResults - 各级别测评结果 [{ level, testedCount, correctCount, accuracy }]
 * @returns {number} 估计识字量
 */
function estimateWordCount(levelResults) {
  // 各级别汉字总量（参考识字体系大纲）
  const levelTotalWords = {
    1: 300,
    2: 600,
    3: 1000,
    4: 1500,
    5: 2000
  };

  let totalEstimated = 0;

  for (const result of levelResults) {
    const totalInLevel = levelTotalWords[result.level] || 0;
    const estimatedInLevel = Math.round(totalInLevel * (result.accuracy / 100));
    totalEstimated += estimatedInLevel;
  }

  // 如果没有测评数据，默认返回0
  return totalEstimated;
}

/**
 * 根据识字量推荐级别
 * @param {number} wordCount - 估计识字量
 * @returns {number} 推荐级别(1-5)
 */
function recommendLevel(wordCount) {
  if (wordCount <= 50) return 1;
  if (wordCount <= 300) return 1;
  if (wordCount <= 600) return 2;
  if (wordCount <= 1000) return 3;
  if (wordCount <= 1500) return 4;
  return 5;
}

/**
 * 生成测评题目
 * 
 * @param {Object} options
 * @param {number} options.targetLevel - 目标级别
 * @param {number} options.questionCount - 题目数量
 * @param {Array} options.knownCharacters - 已知汉字ID列表
 * @param {Object} CharacterModel - Character Model
 * @returns {Array} 题目列表
 */
async function generateAssessmentQuestions(options, CharacterModel) {
  const { targetLevel = 1, questionCount = 20, knownCharacters = [] } = options;

  const questions = [];
  const usedCharacters = new Set();

  // 从目标级别及相邻级别抽题
  const levels = [targetLevel];
  if (targetLevel > 1) levels.push(targetLevel - 1);
  if (targetLevel < 5) levels.push(targetLevel + 1);

  for (let i = 0; i < questionCount; i++) {
    // 每个级别按比例分配题目
    const levelIndex = i % levels.length;
    const level = levels[levelIndex];

    // 随机选一个汉字（排除已用的）
    const character = await CharacterModel.findOne({
      level,
      status: 'active',
      _id: { $nin: [...usedCharacters] }
    }).skip(Math.floor(Math.random() * 10)).lean();

    if (!character) continue;

    usedCharacters.add(character._id.toString());

    // 生成不同类型的题目
    const questionTypes = ['recognize', 'pinyin_match', 'meaning_select'];
    const questionType = questionTypes[i % questionTypes.length];

    const question = generateQuestion(character, questionType, CharacterModel);
    questions.push(question);
  }

  return questions;
}

/**
 * 生成单道测评题目
 */
function generateQuestion(character, questionType, CharacterModel) {
  const question = {
    characterId: character._id,
    character: character.character,
    questionType,
    options: [],
    correctAnswer: ''
  };

  switch (questionType) {
    case 'recognize':
      // 看字选拼音
      question.correctAnswer = character.pinyin;
      question.options = [character.pinyin];
      // 补充3个干扰选项（这里简化处理，实际应从同级别汉字中选）
      question.options = shuffleArray([character.pinyin, 'bā', 'dà', 'xiǎo']);
      break;

    case 'pinyin_match':
      // 看拼音选字
      question.correctAnswer = character.character;
      question.options = shuffleArray([character.character, '大', '小', '人']);
      break;

    case 'meaning_select':
      // 选意思
      const meaning = character.meanings?.[0]?.meaning || character.character;
      question.correctAnswer = meaning;
      question.options = shuffleArray([meaning, '大', '小', '好']);
      break;
  }

  return question;
}

/**
 * 工具函数：添加天数
 */
function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

/**
 * 工具函数：随机打乱数组
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
  calculateNextReview,
  calculateStage,
  estimateWordCount,
  recommendLevel,
  generateAssessmentQuestions,
  generateQuestion,
  addDays,
  shuffleArray
};
