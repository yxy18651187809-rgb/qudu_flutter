const Assessment = require('../models/Assessment');
const Character = require('../models/Character');
const Child = require('../models/Child');
const WordMastery = require('../models/WordMastery');
const LearningRecord = require('../models/LearningRecord');
const Book = require('../models/Book');
const { success, error } = require('../utils/response');
const {
  calculateNextReview,
  estimateWordCount,
  recommendLevel
} = require('../services/reviewAlgorithm');
const {
  generateBookQuestions,
  generateLevelQuestions,
  ASSESSMENT_CONFIG
} = require('../services/questionGenerator');

/**
 * 开始识字测评
 * POST /api/v1/assessments/start
 *
 * v1.1 更新：
 * - 新增 bookId 可选参数（type=review 时必须传入）
 * - 按测评类型配置题目数量和题型分布
 * - 绘本测评从 Book.newWords 取字出题
 */
exports.startAssessment = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId, type = 'initial', targetLevel, questionCount, bookId } = req.body;

    // 校验儿童归属
    const child = await Child.findOne({ _id: childId, userId, status: 'active' });
    if (!child) {
      return error(res, 40410, '儿童档案不存在', 404);
    }

    // 校验 bookId：type=review 时必须传入
    if (type === 'review' && !bookId) {
      return error(res, 40011, '绘本测评必须传入 bookId', 400);
    }

    // 校验 bookId 有效性
    if (bookId) {
      const bookExists = await Book.findById(bookId);
      if (!bookExists) {
        return error(res, 40412, '绘本不存在', 404);
      }
    }

    // 检查是否有进行中的测评（同类型+同绘本）
    const queryFilter = { childId, status: 'in_progress' };
    if (bookId) queryFilter.bookId = bookId;

    const existingAssessment = await Assessment.findOne(queryFilter);

    if (existingAssessment) {
      // 返回已有的进行中测评
      return success(res, {
        assessmentId: existingAssessment._id,
        type: existingAssessment.type,
        bookId: existingAssessment.bookId,
        status: 'in_progress',
        questions: existingAssessment.questions.map(q => ({
          characterId: q.characterId,
          character: q.character,
          questionType: q.questionType,
          options: q.options
          // 不返回 correctAnswer
        })),
        startedAt: existingAssessment.startedAt
      });
    }

    // 生成测评题目（按类型选择生成策略）
    const level = targetLevel || child.currentLevel || 1;
    const knownCharacterIds = (child.knownCharacters || []).map(id => id.toString());

    let questions;

    if (type === 'review' && bookId) {
      // 绘本测评：从绘本新字出题
      const config = ASSESSMENT_CONFIG.review;
      questions = await generateBookQuestions(bookId, {
        questionCount: questionCount || config.totalQuestions,
        CharacterModel: Character,
        BookModel: Book
      });
    } else {
      // 初始测评 / 级别测评：按级别出题
      questions = await generateLevelQuestions({
        type,
        targetLevel: level,
        questionCount,
        knownCharacters: knownCharacterIds,
        CharacterModel: Character
      });
    }

    if (!questions || questions.length === 0) {
      return error(res, 50002, '题目生成失败，请稍后重试', 500);
    }

    // 创建测评记录
    const assessment = await Assessment.create({
      childId,
      type,
      bookId: bookId || undefined,
      targetLevel: level,
      questionCount: questions.length,
      questions: questions.map(q => ({
        ...q,
        userAnswer: null,
        isCorrect: null,
        responseTime: null
      })),
      status: 'in_progress',
      startedAt: new Date()
    });

    success(res, {
      assessmentId: assessment._id,
      type,
      bookId: bookId || undefined,
      status: 'in_progress',
      questions: questions.map(q => ({
        characterId: q.characterId,
        character: q.character,
        questionType: q.questionType,
        options: q.options
      })),
      startedAt: assessment.startedAt
    });
  } catch (err) {
    console.error('开始测评失败:', err);
    error(res, 50001, '开始测评失败', 500);
  }
};

/**
 * 提交测评答案
 * POST /api/v1/assessments/:id/submit
 */
exports.submitAssessment = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const { answers, duration } = req.body;
    // answers: [{ characterId, userAnswer, responseTime }]

    const assessment = await Assessment.findById(id);
    if (!assessment) {
      return error(res, 40401, '测评不存在', 404);
    }

    // 校验归属
    const child = await Child.findOne({
      _id: assessment.childId,
      userId,
      status: 'active'
    });
    if (!child) {
      return error(res, 40301, '无权操作此测评', 403);
    }

    if (assessment.status !== 'in_progress') {
      return error(res, 40010, '测评已结束', 400);
    }

    // 批量更新答案
    let correctCount = 0;
    const answerMap = new Map(
      (answers || []).map(a => [a.characterId.toString(), a])
    );

    for (const question of assessment.questions) {
      const answer = answerMap.get(question.characterId.toString());
      if (answer) {
        question.userAnswer = answer.userAnswer;
        question.isCorrect = answer.userAnswer === question.correctAnswer;
        question.responseTime = answer.responseTime || 0;
        if (question.isCorrect) correctCount++;
      } else {
        question.isCorrect = false;
        question.userAnswer = null;
      }
    }

    // 计算测评结果
    const totalCount = assessment.questions.length;
    const accuracy = totalCount > 0
      ? Math.round((correctCount / totalCount) * 100)
      : 0;

    // 按级别统计结果
    const levelResultsMap = {};
    for (const q of assessment.questions) {
      // 从characterId查级别（简化：用assessment.targetLevel）
      const level = assessment.targetLevel;
      if (!levelResultsMap[level]) {
        levelResultsMap[level] = { level, testedCount: 0, correctCount: 0, accuracy: 0 };
      }
      levelResultsMap[level].testedCount++;
      if (q.isCorrect) levelResultsMap[level].correctCount++;
    }
    const levelResults = Object.values(levelResultsMap).map(lr => ({
      ...lr,
      accuracy: lr.testedCount > 0
        ? Math.round((lr.correctCount / lr.testedCount) * 100)
        : 0
    }));

    // 估算识字量
    const estWordCount = estimateWordCount(levelResults);

    // 推荐级别
    const recLevel = recommendLevel(estWordCount);

    // 计算奖励
    const starsEarned = Math.min(10, correctCount);
    const coinsEarned = Math.min(30, correctCount * 3);

    // 更新测评记录
    assessment.correctCount = correctCount;
    assessment.totalCount = totalCount;
    assessment.accuracy = accuracy;
    assessment.totalScore = correctCount * 5;
    assessment.estimatedWordCount = estWordCount;
    assessment.recommendedLevel = recLevel;
    assessment.levelResults = levelResults;
    assessment.starsEarned = starsEarned;
    assessment.coinsEarned = coinsEarned;
    assessment.status = 'completed';
    assessment.completedAt = new Date();
    assessment.duration = duration || 0;

    await assessment.save();

    // 更新儿童档案
    child.currentLevel = recLevel;
    child.totalStars = (child.totalStars || 0) + starsEarned;
    await child.save();

    // 更新汉字掌握度（遗忘曲线）
    for (const q of assessment.questions) {
      const result = q.isCorrect ? 'correct' : 'wrong';

      let mastery = await WordMastery.findOne({
        childId: child._id,
        characterId: q.characterId
      });

      if (!mastery) {
        mastery = new WordMastery({
          childId: child._id,
          characterId: q.characterId,
          source: 'assessment'
        });
      }

      const reviewResult = calculateNextReview(mastery, result);

      mastery.masteryScore = reviewResult.masteryScore;
      mastery.currentInterval = reviewResult.nextInterval;
      mastery.easeFactor = reviewResult.easeFactor;
      mastery.nextReviewAt = reviewResult.nextReviewAt;
      mastery.stage = reviewResult.stage;
      mastery.totalAttempts = (mastery.totalAttempts || 0) + 1;
      if (result === 'correct') mastery.correctAttempts = (mastery.correctAttempts || 0) + 1;
      mastery.lastAttemptAt = new Date();
      mastery.lastResult = result;
      mastery.reviewHistory.push({
        date: new Date(),
        result,
        interval: reviewResult.nextInterval,
        nextReviewAt: reviewResult.nextReviewAt
      });

      await mastery.save();
    }

    // 创建学习记录
    await LearningRecord.create({
      childId: child._id,
      assessmentId: assessment._id,
      type: 'assessment',
      subtype: `${assessment.type}`,
      characters: assessment.questions.map(q => ({
        characterId: q.characterId,
        character: q.character,
        result: q.isCorrect ? 'correct' : 'wrong',
        responseTime: q.responseTime
      })),
      correctCount,
      totalCount,
      accuracy,
      duration: duration || 0,
      startTime: assessment.startedAt,
      endTime: assessment.completedAt,
      starsEarned,
      coinsEarned
    });

    success(res, {
      assessmentId: assessment._id,
      status: 'completed',
      correctCount,
      totalCount,
      accuracy,
      estimatedWordCount: estWordCount,
      recommendedLevel: recLevel,
      levelResults,
      starsEarned,
      coinsEarned,
      duration: duration || 0
    });
  } catch (err) {
    console.error('提交测评失败:', err);
    error(res, 50001, '提交测评失败', 500);
  }
};

/**
 * 获取测评结果
 * GET /api/v1/assessments/:id
 */
exports.getAssessmentResult = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const assessment = await Assessment.findById(id)
      .populate('questions.characterId', 'character pinyin level')
      .lean();

    if (!assessment) {
      return error(res, 40401, '测评不存在', 404);
    }

    // 校验归属
    const child = await Child.findOne({
      _id: assessment.childId,
      userId
    });
    if (!child) {
      return error(res, 40301, '无权查看此测评', 403);
    }

    success(res, assessment);
  } catch (err) {
    console.error('获取测评结果失败:', err);
    error(res, 50001, '获取测评结果失败', 500);
  }
};

/**
 * 获取儿童测评历史
 * GET /api/v1/assessments/history/:childId
 */
exports.getAssessmentHistory = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId } = req.params;
    const { page = 1, pageSize = 10 } = req.query;

    // 校验归属
    const child = await Child.findOne({ _id: childId, userId });
    if (!child) {
      return error(res, 40410, '儿童档案不存在', 404);
    }

    const total = await Assessment.countDocuments({ childId });
    const assessments = await Assessment.find({ childId })
      .select('type status correctCount totalCount accuracy estimatedWordCount recommendedLevel startedAt completedAt duration')
      .sort({ createdAt: -1 })
      .skip((page - 1) * pageSize)
      .limit(Number(pageSize))
      .lean();

    success(res, {
      list: assessments,
      pagination: {
        page: Number(page),
        pageSize: Number(pageSize),
        total,
        totalPages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('获取测评历史失败:', err);
    error(res, 50001, '获取测评历史失败', 500);
  }
};
