const LearningRecord = require('../models/LearningRecord');
const WordMastery = require('../models/WordMastery');
const Child = require('../models/Child');
const { success, fail, paginate } = require('../utils/response');

/**
 * 记录学习数据
 * POST /api/v1/learning/record
 */
exports.recordLearning = async (req, res) => {
  try {
    const userId = req.userId;
    const {
      childId,
      type,
      subtype,
      bookId,
      characters,
      duration,
      startTime,
      endTime
    } = req.body;

    // 校验儿童归属
    const child = await Child.findOne({ _id: childId, userId, status: 'active' });
    if (!child) {
      return res.status(404).json(fail(404, '儿童档案不存在'));
    }

    // 统计结果
    const charResults = characters || [];
    const correctCount = charResults.filter(c => c.result === 'correct').length;
    const totalCount = charResults.length;
    const accuracy = totalCount > 0
      ? Math.round((correctCount / totalCount) * 100)
      : 0;

    // 计算奖励
    let starsEarned = 0;
    let coinsEarned = 0;

    switch (type) {
      case 'reading':
        starsEarned = 2;  // 完整阅读一本绘本
        coinsEarned = 5;
        break;
      case 'word_study':
        starsEarned = Math.min(5, correctCount);  // 每对1字1星，最多5
        coinsEarned = correctCount * 2;
        break;
      case 'review':
        starsEarned = Math.min(3, correctCount);
        coinsEarned = correctCount;
        break;
      default:
        starsEarned = 1;
        coinsEarned = 2;
    }

    // 创建学习记录
    const record = await LearningRecord.create({
      childId,
      bookId: bookId || undefined,
      type,
      subtype,
      characters: charResults,
      correctCount,
      totalCount,
      accuracy,
      duration: duration || 0,
      startTime: startTime || new Date(),
      endTime: endTime || new Date(),
      starsEarned,
      coinsEarned
    });

    // 更新儿童统计
    child.totalStars = (child.totalStars || 0) + starsEarned;
    child.totalReadingMinutes = (child.totalReadingMinutes || 0) + Math.round((duration || 0) / 60);
    child.lastLearningAt = new Date();
    await child.save();

    // 更新汉字掌握度（如果涉及汉字学习）
    if (charResults.length > 0) {
      const { calculateNextReview } = require('../services/reviewAlgorithm');

      for (const charResult of charResults) {
        if (!charResult.characterId) continue;

        let mastery = await WordMastery.findOne({
          childId: child._id,
          characterId: charResult.characterId
        });

        if (!mastery) {
          mastery = new WordMastery({
            childId: child._id,
            characterId: charResult.characterId,
            source: type
          });
        }

        const result = charResult.result || 'skipped';
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

        await mastery.save();
      }
    }

    res.json(success({
      recordId: record._id,
      starsEarned,
      coinsEarned,
      correctCount,
      totalCount,
      accuracy
    }));
  } catch (err) {
    console.error('记录学习数据失败:', err);
    res.status(500).json(fail(500, '记录学习数据失败'));
  }
};

/**
 * 获取学习历史
 * GET /api/v1/learning/history/:childId
 */
exports.getLearningHistory = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId } = req.params;
    const { type, page = 1, pageSize = 20 } = req.query;

    // 校验归属
    const child = await Child.findOne({ _id: childId, userId });
    if (!child) {
      return res.status(404).json(fail(404, '儿童档案不存在'));
    }

    const filter = { childId };
    if (type) filter.type = type;

    const total = await LearningRecord.countDocuments(filter);
    const records = await LearningRecord.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * pageSize)
      .limit(Number(pageSize))
      .lean();

    res.json(success({
      list: records,
      pagination: paginate(page, pageSize, total)
    }));
  } catch (err) {
    console.error('获取学习历史失败:', err);
    res.status(500).json(fail(500, '获取学习历史失败'));
  }
};

/**
 * 获取学习统计
 * GET /api/v1/learning/stats/:childId
 */
exports.getLearningStats = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId } = req.params;

    // 校验归属
    const child = await Child.findOne({ _id: childId, userId });
    if (!child) {
      return res.status(404).json(fail(404, '儿童档案不存在'));
    }

    // 总体统计
    const totalRecords = await LearningRecord.countDocuments({ childId });
    const totalMinutes = child.totalReadingMinutes || 0;
    const totalStars = child.totalStars || 0;

    // 今日学习
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayRecords = await LearningRecord.find({
      childId,
      createdAt: { $gte: todayStart }
    }).lean();

    const todayMinutes = Math.round(
      todayRecords.reduce((sum, r) => sum + (r.duration || 0), 0) / 60
    );
    const todayStars = todayRecords.reduce((sum, r) => sum + (r.starsEarned || 0), 0);

    // 汉字掌握度统计
    const masteryStats = await WordMastery.aggregate([
      { $match: { childId: child._id } },
      { $group: { _id: '$stage', count: { $sum: 1 } } }
    ]);

    const stageMap = {};
    masteryStats.forEach(s => { stageMap[s._id] = s.count; });

    // 待复习汉字数
    const dueReviewCount = await WordMastery.countDocuments({
      childId: child._id,
      nextReviewAt: { $lte: new Date() },
      stage: { $in: ['learning', 'reviewing'] }
    });

    // 最近7天学习趋势
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const weeklyTrend = await LearningRecord.aggregate([
      { $match: { childId: child._id, createdAt: { $gte: sevenDaysAgo } } },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
          },
          count: { $sum: 1 },
          minutes: { $sum: { $divide: ['$duration', 60] } },
          stars: { $sum: '$starsEarned' }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    res.json(success({
      overview: {
        totalRecords,
        totalMinutes,
        totalStars,
        streakDays: child.streakDays || 0,
        currentLevel: child.currentLevel || 1
      },
      today: {
        records: todayRecords.length,
        minutes: todayMinutes,
        stars: todayStars
      },
      mastery: {
        new: stageMap.new || 0,
        learning: stageMap.learning || 0,
        reviewing: stageMap.reviewing || 0,
        mastered: stageMap.mastered || 0,
        dueReview: dueReviewCount
      },
      weeklyTrend
    }));
  } catch (err) {
    console.error('获取学习统计失败:', err);
    res.status(500).json(fail(500, '获取学习统计失败'));
  }
};
