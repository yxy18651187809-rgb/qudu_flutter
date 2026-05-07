/**
 * 艾宾浩斯遗忘曲线算法（SM-2变体）
 * 
 * 用于计算汉字复习间隔和掌握度
 * 核心参数：
 * - easeFactor: 难度因子，初始2.5，范围[1.3, 3.0]
 * - currentInterval: 当前复习间隔（天）
 * - masteryScore: 掌握度评分[0, 100]
 * 
 * 注意：题目生成逻辑已迁移到 questionGenerator.js
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

  return totalEstimated;
}

/**
 * 根据识字量推荐级别
 * @param {number} wordCount - 估计识字量
 * @returns {number} 推荐级别(1-5)
 */
function recommendLevel(wordCount) {
  if (wordCount <= 300) return 1;
  if (wordCount <= 600) return 2;
  if (wordCount <= 1000) return 3;
  if (wordCount <= 1500) return 4;
  return 5;
}

/**
 * 工具函数：添加天数
 */
function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

module.exports = {
  calculateNextReview,
  calculateStage,
  estimateWordCount,
  recommendLevel,
  addDays
};
