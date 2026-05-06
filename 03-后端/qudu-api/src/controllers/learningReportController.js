const mongoose = require('mongoose');
const LearningReport = require('../models/LearningReport');
const Child = require('../models/Child');
const User = require('../models/User');
const WordMastery = require('../models/WordMastery');
const Assessment = require('../models/Assessment');
const LearningRecord = require('../models/LearningRecord');
const { success, error, ErrorCodes } = require('../utils/response');

/**
 * API 1：获取学习报告
 * GET /api/v1/learning-report/:childId
 */
async function getLearningReport(req, res) {
  try {
    const { childId } = req.params;
    const { period = 'daily', date, days = 7 } = req.query;
    const userId = req.userId;

    // 验证childId格式
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      return error(res, ErrorCodes.INVALID_CHILD_ID, '孩子ID格式错误', 400);
    }
    
    // 检查权限：用户只能访问自己的孩子的数据
    const child = await Child.findById(childId);
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '孩子不存在或无权访问', 404);
    }
    
    const parent = await User.findById(userId);
    if (!parent || child.userId.toString() !== parent._id.toString()) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问该孩子的数据', 403);
    }

    // 计算报告日期
    const reportDate = date ? new Date(date) : new Date();
    reportDate.setHours(0, 0, 0, 0);

    // 查找现有报告
    let report = await LearningReport.findOne({
      childId,
      date: reportDate,
      period
    });

    // 如果报告不存在，自动生成一个
    if (!report) {
      report = await generateReportInternal(childId, reportDate, period);
    }

    if (!report) {
      return error(res, ErrorCodes.REPORT_NOT_FOUND, '学习报告不存在', 404);
    }
    
    // 获取孩子基本信息
    const childInfo = await Child.findById(childId).select('name avatar gender');
    
    // 计算进度信息
    const totalCharacters = report.totalCharacters || 0;
    const level = Math.floor(totalCharacters / 60) + 1; // 每60字升一级
    const nextLevelCharacters = Math.max(60 - (totalCharacters % 60), 0);
    
    // 构建响应
    const responseData = {
      childId: childId,
      childName: childInfo?.name || '未知',
      period: report.period,
      date: report.date.toISOString().split('T')[0],
      statistics: {
        studyTime: report.studyTime || 0,
        charactersLearned: report.charactersLearned || 0,
        booksRead: report.booksRead || 0,
        assessmentCount: report.assessmentCount || 0,
        averageAccuracy: report.averageAccuracy || 0
      },
      progress: {
        totalCharacters,
        level,
        nextLevelCharacters
      },
      trends: {
        accuracy: report.accuracyTrend || [],
        characters: report.charactersTrend || []
      },
      review: {
        due: report.reviewDue || 0,
        completed: report.reviewCompleted || 0,
        rate: report.reviewRate || 0
      }
    };
    
    return success(res, responseData);
  } catch (err) {
    console.error('获取学习报告失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 2：获取学习报告列表（家长视角）
 * GET /api/v1/learning-report/parent/:parentId
 */
async function getLearningReportList(req, res) {
  try {
    const { parentId } = req.params;
    const { period = 'daily', date } = req.query;
    const userId = req.userId;

    // 权限检查：只能查看自己的
    if (parentId!== userId) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问', 403);
    }
    
    // 获取该家长的所有孩子
    const parent = await User.findById(parentId);
    if (!parent) {
      return error(res, ErrorCodes.USER_NOT_FOUND, '用户不存在', 404);
    }
    
    const children = await Child.find({ parentPhone: parent.phone });
    const reportDate = date ? new Date(date) : new Date();
    reportDate.setHours(0, 0, 0, 0);
    
    const childrenReports = [];
    
    for (const child of children) {
      // 查找或生成报告
      let report = await LearningReport.findOne({
        childId: child._id,
        date: reportDate,
        period
      });
      
      if (!report) {
        report = await generateReportInternal(child._id, reportDate, period);
      }
      
      const alerts = [];
      if (report) {
        // 检查需要复习的字数
        if (report.reviewDue > 0) {
          alerts.push({
            type: 'review_due',
            message: `有${report.reviewDue}个汉字需要复习`
          });
        }
        
        // 检查学习时长不足
        if (report.studyTime < 15) {
          alerts.push({
            type: 'study_time_insufficient',
            message: '今日学习时长不足15分钟'
          });
        }
      }
      
      childrenReports.push({
        childId: child._id,
        childName: child.name,
        avatarUrl: child.avatar || '',
        statistics: report ? {
          studyTime: report.studyTime || 0,
          charactersLearned: report.charactersLearned || 0,
          averageAccuracy: report.averageAccuracy || 0,
          totalCharacters: report.totalCharacters || 0
        } : null,
        alerts
      });
    }
    
    return success(res, {
      date: reportDate.toISOString().split('T')[0],
      period,
      children: childrenReports
    });
  } catch (err) {
    console.error('获取学习报告列表失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 3：生成学习报告（手动触发）
 * POST /api/v1/learning-report/:childId/generate
 */
async function generateLearningReport(req, res) {
  try {
    const { childId } = req.params;
    const { date, period = 'daily' } = req.body;
    const userId = req.userId;
    
    // 权限检查
    const child = await Child.findById(childId);
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '孩子不存在', 404);
    }
    
    const parent = await User.findById(userId);
    if (!parent || child.userId.toString() !== parent._id.toString()) {
      return error(res, ErrorCodes.FORBIDDEN, '无权操作', 403);
    }
    
    // 生成报告
    const reportDate = date ? new Date(date) : new Date();
    reportDate.setHours(0, 0, 0, 0);
    
    const report = await generateReportInternal(childId, reportDate, period);
    
    if (!report) {
      return error(res, ErrorCodes.GENERATE_FAILED, '报告生成失败', 500);
    }
    
    return success(res, {
      reportId: report._id,
      message: '学习报告已生成'
    });
  } catch (err) {
    console.error('生成学习报告失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 4：获取识字量趋势（简化版）
 * GET /api/v1/learning-report/:childId/characters-trend
 */
async function getCharactersTrend(req, res) {
  try {
    const { childId } = req.params;
    const { days = 30 } = req.query;
    const userId = req.userId;

    // 权限检查
    const child = await Child.findById(childId);
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '孩子不存在', 404);
    }
    
    const parent = await User.findById(userId);
    if (!parent || child.userId.toString() !== parent._id.toString()) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问', 403);
    }
    
    // 获取识字量趋势
    const trendDays = parseInt(days);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - trendDays);
    startDate.setHours(0, 0, 0, 0);

    const reports = await LearningReport.find({
      childId,
      date: { $gte: startDate },
      period: 'daily'
    }).sort({ date: 1 });

    const trend = reports.map(r => ({
      date: r.date.toISOString().split('T')[0],
      count: r.totalCharacters || 0
    }));

    // 如果趋势数据不足，补充从WordMastery计算的数据
    if (trend.length === 0) {
      // 从WordMastery聚合识字量
      const masteries = await WordMastery.find({ childId })
        .sort({ lastReviewAt: 1 })
        .select('lastReviewAt status');

      // 按日期汇总
      const dateCountMap = new Map();
      let cumulativeCount = 0;
      for (const m of masteries) {
        if (m.status === 'mastered') {
          cumulativeCount++;
          const dateStr = m.lastReviewAt.toISOString().split('T')[0];
          dateCountMap.set(dateStr, cumulativeCount);
        }
      }

      for (const [date, count] of dateCountMap) {
        trend.push({ date, count });
      }
    }

    const totalCharacters = trend.length > 0 ? trend[trend.length - 1].count : 0;
    
    return success(res, {
      childId,
      totalCharacters,
      trend
    });
  } catch (err) {
    console.error('获取识字量趋势失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * 内部方法：生成报告
 */
async function generateReportInternal(childId, date, period) {
  try {
    // 计算日期范围
    let startDate = new Date(date);
    let endDate = new Date(date);

    if (period === 'weekly') {
      // 本周一
      const day = startDate.getDay();
      const diff = startDate.getDate() - day + (day === 0 ? -6 : 1);
      startDate = new Date(startDate.setDate(diff));
      endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + 6);
    } else if (period === 'monthly') {
      // 本月1号
      startDate = new Date(startDate.getFullYear(), startDate.getMonth(), 1);
      endDate = new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0);
    }

    startDate.setHours(0, 0, 0, 0);
    endDate.setHours(23, 59, 59, 999);

    // 查询学习记录（包含duration和newWords）
    const learningRecords = await LearningRecord.find({
      childId,
      createdAt: { $gte: startDate, $lte: endDate }
    });

    // 查询测评记录
    const assessments = await Assessment.find({
      childId,
      createdAt: { $gte: startDate, $lte: endDate }
    });

    // 查询识字量（真实统计）
    const totalCharacters = await WordMastery.countDocuments({
      childId,
      status: 'mastered'
    });

    // 计算统计数据（真实计算）
    const studyTime = learningRecords.reduce((sum, r) => sum + (r.duration || 0), 0);
    const charactersLearned = learningRecords.reduce((sum, r) => sum + (r.newWords || 0), 0);
    const booksRead = learningRecords.filter(r => r.type === 'book').length;
    const assessmentCount = assessments.length;
    const averageAccuracy = assessments.length > 0
      ? Math.round(assessments.reduce((sum, a) => sum + (a.accuracy || 0), 0) / assessments.length)
      : 0;

    // 计算准确率趋势（最近7天，真实数据）
    const accuracyTrend = [];
    for (let i = 6; i >= 0; i--) {
      const trendDate = new Date();
      trendDate.setDate(trendDate.getDate() - i);
      trendDate.setHours(0, 0, 0, 0);

      const dayAssessments = assessments.filter(a => {
        const aDate = new Date(a.createdAt);
        aDate.setHours(0, 0, 0, 0);
        return aDate.getTime() === trendDate.getTime();
      });

      const avgAcc = dayAssessments.length > 0
        ? Math.round(dayAssessments.reduce((sum, a) => sum + (a.accuracy || 0), 0) / dayAssessments.length)
        : 0;

      accuracyTrend.push({
        date: trendDate,
        accuracy: avgAcc
      });
    }

    // 计算识字量趋势（最近30天，基于WordMastery真实数据）
    const charactersTrend = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // 获取所有已掌握的汉字，按掌握时间排序
    const masteredWords = await WordMastery.find({
      childId,
      status: 'mastered'
    }).sort({ lastReviewAt: 1 });
    
    if (masteredWords.length > 0) {
      // 按日期汇总识字量
      const dateCountMap = new Map();
      let cumulativeCount = 0;
      
      for (const word of masteredWords) {
        if (word.lastReviewAt) {
          const dateStr = word.lastReviewAt.toISOString().split('T')[0];
          cumulativeCount++;
          dateCountMap.set(dateStr, cumulativeCount);
        }
      }
      
      // 填充最近30天的趋势数据
      for (let i = 29; i >= 0; i--) {
        const trendDate = new Date(today);
        trendDate.setDate(trendDate.getDate() - i);
        const dateStr = trendDate.toISOString().split('T')[0];
        
        // 找到该日期或之前最近的识字量
        let count = 0;
        for (const [d, c] of dateCountMap) {
          if (d <= dateStr) {
            count = c;
          } else {
            break;
          }
        }
        
        charactersTrend.push({
          date: trendDate,
          count
        });
      }
    } else {
      // 没有掌握任何汉字，填充0
      for (let i = 29; i >= 0; i--) {
        const trendDate = new Date(today);
        trendDate.setDate(trendDate.getDate() - i);
        charactersTrend.push({
          date: trendDate,
          count: 0
        });
      }
    }

    // 计算复习统计
    const reviewDue = await WordMastery.countDocuments({
      childId,
      nextReviewAt: { $lte: new Date() },
      status: { $in: ['learning', 'review'] }
    });

    const reviewCompleted = await WordMastery.countDocuments({
      childId,
      lastReviewAt: { $gte: startDate, $lte: endDate },
      status: 'mastered'
    });

    const reviewRate = reviewDue + reviewCompleted > 0
      ? Math.round(reviewCompleted / (reviewDue + reviewCompleted) * 100)
      : 100;

    // 创建或更新报告
    const report = await LearningReport.findOneAndUpdate(
      { childId, date, period },
      {
        childId,
        date,
        period,
        studyTime,
        charactersLearned: charactersLearned,
        booksRead,
        assessmentCount,
        averageAccuracy,
        accuracyTrend,
        totalCharacters,
        charactersTrend,
        reviewDue,
        reviewCompleted,
        reviewRate
      },
      { upsert: true, new: true }
    );

    return report;
  } catch (err) {
    console.error('生成报告内部失败:', err);
    return null;
  }
}

module.exports = {
  getLearningReport,
  getLearningReportList,
  generateLearningReport,
  getCharactersTrend
};
