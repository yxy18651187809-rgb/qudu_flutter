const mongoose = require('mongoose');
const ParentMonitoring = require('../models/ParentMonitoring');
const Child = require('../models/Child');
const User = require('../models/User');
const WordMastery = require('../models/WordMastery');
const LearningRecord = require('../models/LearningRecord');
const Assessment = require('../models/Assessment');
const { success, error, ErrorCodes } = require('../utils/response');

/**
 * API 5：获取监控概览
 * GET /api/v1/parent-monitoring/:parentId
 */
async function getMonitoringOverview(req, res) {
  try {
    const { parentId } = req.params;
    const userId = req.userId;
    
    // 权限检查：只能查看自己的
    if (parentId !== userId) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问', 403);
    }
    
    // 获取家长信息
    const parent = await User.findById(parentId);
    if (!parent) {
      return error(res, ErrorCodes.USER_NOT_FOUND, '用户不存在', 404);
    }
    
    // 获取所有孩子（通过userId关联）
    const children = await Child.find({ userId: parent._id });
    const childrenOverview = [];
    
    for (const child of children) {
      // 查找或创建监控记录
      let monitoring = await ParentMonitoring.findOne({
        parentId,
        childId: child._id
      });
      
      if (!monitoring) {
        monitoring = await ParentMonitoring.create({
          parentId,
          childId: child._id
        });
      }
      
      // 获取今日数据
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const todayRecords = await LearningRecord.find({
        childId: child._id,
        createdAt: { $gte: today }
      });
      
      const todayStudyTime = todayRecords.reduce((sum, r) => sum + (r.duration || 0), 0);
      const todayCharacters = todayRecords.reduce((sum, r) => sum + (r.newWords || 0), 0);
      
      const todayAssessments = await Assessment.find({
        childId: child._id,
        createdAt: { $gte: today }
      });
      const todayAccuracy = todayAssessments.length > 0
        ? Math.round(todayAssessments.reduce((sum, a) => sum + (a.accuracy || 0), 0) / todayAssessments.length)
        : 0;
      
      const reviewDue = await WordMastery.countDocuments({
        childId: child._id,
        nextReviewAt: { $lte: new Date() },
        status: { $in: ['learning', 'review'] }
      });
      
      // 检查告警
      const alerts = [];
      if (todayStudyTime < monitoring.thresholds.minDailyStudyTime) {
        alerts.push({
          type: 'study_time_insufficient',
          message: `今日学习时长不足${monitoring.thresholds.minDailyStudyTime}分钟`,
          severity: 'warning'
        });
      }
      if (todayCharacters < monitoring.thresholds.minCharactersPerDay) {
        alerts.push({
          type: 'characters_insufficient',
          message: `今日识字数不足${monitoring.thresholds.minCharactersPerDay}个`,
          severity: 'warning'
        });
      }
      if (todayAccuracy > 0 && todayAccuracy < monitoring.thresholds.minAccuracy) {
        alerts.push({
          type: 'accuracy_low',
          message: `今日测评准确率${todayAccuracy}%，低于${monitoring.thresholds.minAccuracy}%`,
          severity: 'warning'
        });
      }
      if (reviewDue > 0 && monitoring.alertSettings.enableReviewAlert) {
        alerts.push({
          type: 'review_due',
          message: `有${reviewDue}个汉字需要复习`,
          severity: 'info'
        });
      }
      
      childrenOverview.push({
        childId: child._id,
        childName: child.name,
        avatarUrl: child.avatar || '',
        today: {
          studyTime: todayStudyTime,
          maxStudyTime: monitoring.thresholds.maxDailyStudyTime,
          charactersLearned: todayCharacters,
          minCharacters: monitoring.thresholds.minCharactersPerDay,
          accuracy: todayAccuracy,
          minAccuracy: monitoring.thresholds.minAccuracy
        },
        alerts
      });
    }
    
    return success(res, {
      parentId,
      children: childrenOverview
    });
  } catch (err) {
    console.error('获取监控概览失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 6：获取单个孩子的监控详情
 * GET /api/v1/parent-monitoring/:parentId/child/:childId
 */
async function getChildMonitoringDetail(req, res) {
  try {
    const { parentId, childId } = req.params;
    const userId = req.userId;

    // 权限检查
    if (parentId !== userId) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问', 403);
    }
    
    // 验证childId
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      return error(res, ErrorCodes.INVALID_CHILD_ID, '孩子ID格式错误', 400);
    }
    
    // 检查孩子是否存在且属于该家长
    const child = await Child.findById(childId);
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '孩子不存在', 404);
    }

    const parent = await User.findById(parentId);
    if (!parent || child.userId.toString() !== parent._id.toString()) {
      return error(res, ErrorCodes.FORBIDDEN, '无权访问该孩子的数据', 403);
    }
    
    // 查找或创建监控记录
    let monitoring = await ParentMonitoring.findOne({
      parentId,
      childId
    });

    if (!monitoring) {
      monitoring = await ParentMonitoring.create({
        parentId,
        childId
      });
    }

    // 获取今日数据
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayRecords = await LearningRecord.find({
      childId,
      createdAt: { $gte: today }
    });

    const todayStudyTime = todayRecords.reduce((sum, r) => sum + (r.duration || 0), 0);
    const todayCharacters = todayRecords.reduce((sum, r) => sum + (r.newWords || 0), 0);

    const todayAssessments = await Assessment.find({
      childId,
      createdAt: { $gte: today }
    });
    const todayAccuracy = todayAssessments.length > 0
      ? Math.round(todayAssessments.reduce((sum, a) => sum + (a.accuracy || 0), 0) / todayAssessments.length)
      : 0;

    const reviewDue = await WordMastery.countDocuments({
      childId,
      nextReviewAt: { $lte: new Date() },
      status: { $in: ['learning', 'review'] }
    });

    // 获取本周数据
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay() + 1); // 本周一
    weekStart.setHours(0, 0, 0, 0);

    const weekRecords = await LearningRecord.find({
      childId,
      createdAt: { $gte: weekStart }
    });

    const weeklyStudyTime = weekRecords.reduce((sum, r) => sum + (r.duration || 0), 0) / 7; // 日均
    const weeklyCharacters = weekRecords.reduce((sum, r) => sum + (r.newWords || 0), 0) / 7; // 日均

    const weeklyAssessments = await Assessment.find({
      childId,
      createdAt: { $gte: weekStart }
    });
    const weeklyAccuracy = weeklyAssessments.length > 0
      ? Math.round(weeklyAssessments.reduce((sum, a) => sum + (a.accuracy || 0), 0) / weeklyAssessments.length)
      : 0;

    const weeklyReviewCompletion = 75; // 简化：固定值，实际应从WordMastery计算

    return success(res, {
      childId,
      childName: child.name,
      thresholds: monitoring.thresholds,
      today: {
        studyTime: todayStudyTime,
        charactersLearned: todayCharacters,
        accuracy: todayAccuracy,
        reviewDue
      },
      weekly: {
        averageStudyTime: Math.round(weeklyStudyTime),
        averageCharacters: Math.round(weeklyCharacters * 10) / 10,
        averageAccuracy: weeklyAccuracy,
        reviewCompletionRate: weeklyReviewCompletion
      },
      alertSettings: monitoring.alertSettings
    });
  } catch (err) {
    console.error('获取监控详情失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 7：更新监控阈值
 * PUT /api/v1/parent-monitoring/:parentId/child/:childId/thresholds
 */
async function updateThresholds(req, res) {
  try {
    const { parentId, childId } = req.params;
    const userId = req.userId;
    const {
      maxDailyStudyTime,
      minDailyStudyTime,
      minCharactersPerDay,
      minAccuracy,
      maxReviewDelayDays
    } = req.body;

    // 权限检查
    if (parentId !== userId) {
      return error(res, ErrorCodes.FORBIDDEN, '无权操作', 403);
    }
    
    // 验证childId
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      return error(res, ErrorCodes.INVALID_CHILD_ID, '孩子ID格式错误', 400);
    }
    
    // 检查孩子是否存在且属于该家长
    const child = await Child.findById(childId);
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '孩子不存在', 404);
    }
    
    const parent = await User.findById(parentId);
    if (!parent || child.userId.toString() !== parent._id.toString()) {
      return error(res, ErrorCodes.FORBIDDEN, '无权操作', 403);
    }

    // 查找或创建监控记录
    let monitoring = await ParentMonitoring.findOne({
      parentId,
      childId
    });

    if (!monitoring) {
      monitoring = await ParentMonitoring.create({
        parentId,
        childId
      });
    }

    // 更新阈值
    if (maxDailyStudyTime !== undefined) {
      if (maxDailyStudyTime < 0 || maxDailyStudyTime > 480) {
        return error(res, ErrorCodes.INVALID_PARAMS, '每日最长学习时长必须在0-480分钟之间', 400);
      }
      monitoring.thresholds.maxDailyStudyTime = maxDailyStudyTime;
    }
    
    if (minDailyStudyTime !== undefined) {
      if (minDailyStudyTime < 0 || minDailyStudyTime > 120) {
        return error(res, ErrorCodes.INVALID_PARAMS, '每日最短学习时长必须在0-120分钟之间', 400);
      }
      monitoring.thresholds.minDailyStudyTime = minDailyStudyTime;
    }
    
    if (minCharactersPerDay !== undefined) {
      if (minCharactersPerDay < 0 || minCharactersPerDay > 50) {
        return error(res, ErrorCodes.INVALID_PARAMS, '每日最少识字数必须在0-50之间', 400);
      }
      monitoring.thresholds.minCharactersPerDay = minCharactersPerDay;
    }
    
    if (minAccuracy !== undefined) {
      if (minAccuracy < 0 || minAccuracy > 100) {
        return error(res, ErrorCodes.INVALID_PARAMS, '最低准确率必须在0-100之间', 400);
      }
      monitoring.thresholds.minAccuracy = minAccuracy;
    }
    
    if (maxReviewDelayDays !== undefined) {
      if (maxReviewDelayDays < 0 || maxReviewDelayDays > 30) {
        return error(res, ErrorCodes.INVALID_PARAMS, '最长复习延迟天数必须在0-30之间', 400);
      }
      monitoring.thresholds.maxReviewDelayDays = maxReviewDelayDays;
    }
    
    await monitoring.save();
    
    return success(res, {
      message: '监控阈值已更新'
    });
  } catch (err) {
    console.error('更新监控阈值失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

/**
 * API 8：更新告警设置
 * PUT /api/v1/parent-monitoring/:parentId/alert-settings
 */
async function updateAlertSettings(req, res) {
  try {
    const { parentId } = req.params;
    const userId = req.userId;
    const {
      enableStudyTimeAlert,
      enableAccuracyAlert,
      enableReviewAlert,
      alertMethods
    } = req.body;

    // 权限检查
    if (parentId !== userId) {
      return error(res, ErrorCodes.FORBIDDEN, '无权操作', 403);
    }
    
    // 查找该家长的所有监控记录
    const monitorings = await ParentMonitoring.find({ parentId });
    
    if (monitorings.length === 0) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '监控记录不存在', 404);
    }
    
    // 更新所有孩子的告警设置（统一设置）
    for (const monitoring of monitorings) {
      if (enableStudyTimeAlert !== undefined) {
        monitoring.alertSettings.enableStudyTimeAlert = enableStudyTimeAlert;
      }
      if (enableAccuracyAlert !== undefined) {
        monitoring.alertSettings.enableAccuracyAlert = enableAccuracyAlert;
      }
      if (enableReviewAlert !== undefined) {
        monitoring.alertSettings.enableReviewAlert = enableReviewAlert;
      }
      if (alertMethods !== undefined) {
        // 验证alertMethods
        const validMethods = ['push', 'sms', 'wechat'];
        for (const method of alertMethods) {
          if (!validMethods.includes(method)) {
            return error(res, ErrorCodes.INVALID_PARAMS, `无效的告警方式: ${method}`, 400);
          }
        }
        monitoring.alertSettings.alertMethods = alertMethods;
      }
      
      await monitoring.save();
    }
    
    return success(res, {
      message: '告警设置已更新'
    });
  } catch (err) {
    console.error('更新告警设置失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '服务器内部错误', 500);
  }
}

module.exports = {
  getMonitoringOverview,
  getChildMonitoringDetail,
  updateThresholds,
  updateAlertSettings
};
