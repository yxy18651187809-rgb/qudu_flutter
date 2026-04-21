const Child = require('../models/Child');
const { success, created, error, ErrorCodes } = require('../utils/response');
const config = require('../config');

/**
 * 获取儿童列表
 * GET /api/v1/children
 */
async function getChildren(req, res) {
  try {
    const children = await Child.find({ 
      userId: req.userId, 
      status: 'active' 
    }).sort({ createdAt: 1 });
    
    const list = children.map(child => ({
      id: child._id,
      name: child.name,
      avatar: child.avatar,
      gender: child.gender,
      birthDate: child.birthDate ? child.birthDate.toISOString().slice(0, 10) : null,
      grade: child.grade,
      currentLevel: child.currentLevel,
      knownCharacterCount: child.knownCharacterCount,
      streakDays: child.streakDays,
      totalStars: child.totalStars,
      totalReadingMinutes: child.totalReadingMinutes,
      isVip: child.isVip,
      vipExpireAt: child.vipExpireAt
    }));
    
    return success(res, { list });
  } catch (err) {
    console.error('[Child] 获取儿童列表失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '获取儿童列表失败', 500);
  }
}

/**
 * 创建儿童档案
 * POST /api/v1/children
 */
async function createChild(req, res) {
  try {
    const { name, gender, birthDate, grade } = req.body;
    
    // 校验名称
    if (!name || !name.trim()) {
      return error(res, ErrorCodes.NAME_REQUIRED, '昵称不能为空');
    }
    
    // 校验出生日期
    if (!birthDate) {
      return error(res, ErrorCodes.INVALID_BIRTH_DATE, '请选择出生日期');
    }
    const parsedDate = new Date(birthDate);
    if (isNaN(parsedDate.getTime())) {
      return error(res, ErrorCodes.INVALID_BIRTH_DATE, '出生日期格式不正确');
    }
    if (parsedDate > new Date()) {
      return error(res, ErrorCodes.INVALID_BIRTH_DATE, '出生日期不能是未来日期');
    }
    
    // 检查儿童数量限制
    const count = await Child.countDocuments({ 
      userId: req.userId, 
      status: 'active' 
    });
    if (count >= config.limits.maxChildrenPerUser) {
      return error(res, ErrorCodes.MAX_CHILDREN_REACHED, `已达到最大儿童档案数量（${config.limits.maxChildrenPerUser}个）`, 403);
    }
    
    // 创建档案
    const child = await Child.create({
      userId: req.userId,
      name: name.trim(),
      gender: gender || 'unknown',
      birthDate: parsedDate,
      grade: grade !== undefined ? grade : 0
    });
    
    console.log(`[Child] 创建儿童档案: userId=${req.userId}, name=${name}`);
    
    return created(res, {
      id: child._id,
      name: child.name,
      avatar: child.avatar,
      gender: child.gender,
      birthDate: child.birthDate ? child.birthDate.toISOString().slice(0, 10) : null,
      grade: child.grade,
      currentLevel: child.currentLevel,
      knownCharacterCount: child.knownCharacterCount,
      streakDays: child.streakDays,
      totalStars: child.totalStars,
      totalReadingMinutes: child.totalReadingMinutes,
      isVip: child.isVip,
      vipExpireAt: child.vipExpireAt
    });
  } catch (err) {
    console.error('[Child] 创建儿童档案失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '创建儿童档案失败', 500);
  }
}

/**
 * 获取儿童详情
 * GET /api/v1/children/:id
 */
async function getChild(req, res) {
  try {
    const child = await Child.findOne({ 
      _id: req.params.id, 
      status: 'active' 
    });
    
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '儿童档案不存在', 404);
    }
    
    // 权限校验：只能查看自己的儿童
    if (child.userId.toString() !== req.userId) {
      return error(res, ErrorCodes.CHILD_ACCESS_DENIED, '无权访问该儿童档案', 403);
    }
    
    return success(res, {
      id: child._id,
      name: child.name,
      avatar: child.avatar,
      gender: child.gender,
      birthDate: child.birthDate ? child.birthDate.toISOString().slice(0, 10) : null,
      grade: child.grade,
      currentLevel: child.currentLevel,
      knownCharacterCount: child.knownCharacterCount,
      streakDays: child.streakDays,
      totalStars: child.totalStars,
      totalReadingMinutes: child.totalReadingMinutes,
      isVip: child.isVip,
      vipExpireAt: child.vipExpireAt,
      lastLearningAt: child.lastLearningAt,
      createdAt: child.createdAt
    });
  } catch (err) {
    console.error('[Child] 获取儿童详情失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '获取儿童详情失败', 500);
  }
}

/**
 * 更新儿童档案
 * PUT /api/v1/children/:id
 */
async function updateChild(req, res) {
  try {
    const child = await Child.findOne({ 
      _id: req.params.id, 
      status: 'active' 
    });
    
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '儿童档案不存在', 404);
    }
    
    // 权限校验
    if (child.userId.toString() !== req.userId) {
      return error(res, ErrorCodes.CHILD_ACCESS_DENIED, '无权访问该儿童档案', 403);
    }
    
    const { name, avatar, gender, birthDate, grade } = req.body;
    
    if (name !== undefined) child.name = name.trim();
    if (avatar !== undefined) child.avatar = avatar;
    if (gender !== undefined) child.gender = gender;
    if (grade !== undefined) child.grade = grade;
    if (birthDate !== undefined) {
      const parsedDate = new Date(birthDate);
      if (isNaN(parsedDate.getTime())) {
        return error(res, ErrorCodes.INVALID_BIRTH_DATE, '出生日期格式不正确');
      }
      child.birthDate = parsedDate;
    }
    
    await child.save();
    
    return success(res, {
      id: child._id,
      name: child.name,
      avatar: child.avatar,
      gender: child.gender,
      birthDate: child.birthDate ? child.birthDate.toISOString().slice(0, 10) : null,
      grade: child.grade,
      currentLevel: child.currentLevel,
      knownCharacterCount: child.knownCharacterCount,
      streakDays: child.streakDays,
      totalStars: child.totalStars,
      totalReadingMinutes: child.totalReadingMinutes,
      isVip: child.isVip,
      vipExpireAt: child.vipExpireAt
    });
  } catch (err) {
    console.error('[Child] 更新儿童档案失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '更新儿童档案失败', 500);
  }
}

/**
 * 删除儿童档案（软删除）
 * DELETE /api/v1/children/:id
 */
async function deleteChild(req, res) {
  try {
    const child = await Child.findOne({ 
      _id: req.params.id, 
      status: 'active' 
    });
    
    if (!child) {
      return error(res, ErrorCodes.CHILD_NOT_FOUND, '儿童档案不存在', 404);
    }
    
    // 权限校验
    if (child.userId.toString() !== req.userId) {
      return error(res, ErrorCodes.CHILD_ACCESS_DENIED, '无权访问该儿童档案', 403);
    }
    
    // 软删除
    child.status = 'archived';
    await child.save();
    
    console.log(`[Child] 删除儿童档案: userId=${req.userId}, childId=${child._id}`);
    
    return success(res, null, '删除成功');
  } catch (err) {
    console.error('[Child] 删除儿童档案失败:', err);
    return error(res, ErrorCodes.INTERNAL_ERROR, '删除儿童档案失败', 500);
  }
}

module.exports = {
  getChildren,
  createChild,
  getChild,
  updateChild,
  deleteChild
};
