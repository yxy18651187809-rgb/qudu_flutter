const Character = require('../models/Character');
const { success, error } = require('../utils/response');

/**
 * 获取汉字列表
 * GET /api/v1/characters
 * Query: level, grade, page, pageSize
 */
exports.getCharacters = async (req, res) => {
  try {
    const { level, grade, page = 1, pageSize = 100 } = req.query;
    const filter = {};

    if (level) {
      // 支持两种格式：level=1 或 level=L1（自动提取数字部分）
      const levelNum = typeof level === 'string' && level.startsWith('L') ? level.substring(1) : level;
      const parsed = parseInt(levelNum);
      if (!isNaN(parsed)) filter.level = parsed;
    }
    if (grade) {
      const gradeNum = typeof grade === 'string' && grade.startsWith('G') ? grade.substring(1) : grade;
      const parsed = parseInt(gradeNum);
      if (!isNaN(parsed)) filter.grade = parsed;
    }

    const skip = (parseInt(page) - 1) * parseInt(pageSize);
    const [list, total] = await Promise.all([
      Character.find(filter)
        .select('-__v')
        .sort({ level: 1, strokeCount: 1 })
        .skip(skip)
        .limit(parseInt(pageSize)),
      Character.countDocuments(filter),
    ]);

    return success(res, {
      list,
      pagination: { page: parseInt(page), pageSize: parseInt(pageSize), total, totalPages: Math.ceil(total / parseInt(pageSize)) }
    });
  } catch (err) {
    return error(res, 50001, err.message, 500);
  }
};

/**
 * 获取单个汉字详情
 * GET /api/v1/characters/:id
 */
exports.getCharacter = async (req, res) => {
  try {
    const char = await Character.findById(req.params.id).select('-__v');
    if (!char) return error(res, 40401, '汉字不存在', 404);
    return success(res, char);
  } catch (err) {
    return error(res, 50001, err.message, 500);
  }
};
