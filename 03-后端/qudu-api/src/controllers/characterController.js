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

    if (level) filter.level = parseInt(level);
    if (grade) filter.grade = parseInt(grade);

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
