const Book = require('../models/Book');
const BookPage = require('../models/BookPage');
const Character = require('../models/Character');
const Child = require('../models/Child');
const { success, fail, paginate } = require('../utils/response');

/**
 * 获取绘本列表
 * GET /api/v1/books
 * Query: level, theme, status, isFree, page, pageSize, sort
 */
exports.getBooks = async (req, res) => {
  try {
    const {
      level,
      theme,
      status = 'online',
      isFree,
      page = 1,
      pageSize = 20,
      sort = 'sortOrder'
    } = req.query;

    const filter = {};

    // 状态过滤（默认只返回已上线的）
    if (status) filter.status = status;

    // 级别过滤
    if (level) {
      const levels = level.split(',').map(Number);
      filter.level = levels.length === 1 ? levels[0] : { $in: levels };
    }

    // 主题过滤
    if (theme) filter.theme = theme;

    // 免费过滤
    if (isFree !== undefined) filter.isFree = isFree === 'true';

    // 排序
    let sortOption = { sortOrder: 1 };
    if (sort === 'popular') sortOption = { readCount: -1 };
    else if (sort === 'newest') sortOption = { publishedAt: -1 };
    else if (sort === 'rating') sortOption = { rating: -1 };

    const total = await Book.countDocuments(filter);
    const books = await Book.find(filter)
      .select('-exercises')  // 列表不返回练习题
      .sort(sortOption)
      .skip((page - 1) * pageSize)
      .limit(Number(pageSize))
      .lean();

    success(res, {
      list: books,
      pagination: paginate(page, pageSize, total)
    });
  } catch (err) {
    console.error('获取绘本列表失败:', err);
    error(res, 50001, '获取绘本列表失败', 500);
  }
};

/**
 * 获取绘本详情（含页面内容）
 * GET /api/v1/books/:id
 * Query: childId (可选，用于返回学习进度)
 */
exports.getBookDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const { childId } = req.query;

    const book = await Book.findById(id).lean();
    if (!book) {
      return error(res, 40401, '绘本不存在', 404);
    }

    // 获取绘本页面
    const pages = await BookPage.find({ bookId: id })
      .sort({ pageNumber: 1 })
      .lean();

    book.pages = pages;

    // 如果传了childId，返回该儿童对绘本新字的掌握情况
    if (childId) {
      const child = await Child.findById(childId).lean();
      if (child) {
        const knownSet = new Set(
          (child.knownCharacters || []).map(id => id.toString())
        );
        book.newWordProgress = (book.newWords || []).map(charId => ({
          characterId: charId,
          mastered: knownSet.has(charId.toString())
        }));
        book.masteredCount = book.newWordProgress.filter(w => w.mastered).length;
      }
    }

    success(res, book);
  } catch (err) {
    console.error('获取绘本详情失败:', err);
    error(res, 50001, '获取绘本详情失败', 500);
  }
};

/**
 * 智能推荐绘本
 * GET /api/v1/books/recommended
 * Query: childId, limit
 * 
 * 推荐逻辑：
 * 1. 优先推荐当前级别未读的绘本
 * 2. 推荐包含待复习字的绘本
 * 3. 推荐热门绘本
 */
exports.getRecommendedBooks = async (req, res) => {
  try {
    const { childId, limit = 6 } = req.query;

    if (!childId) {
      // 未传childId，返回热门绘本
      const hotBooks = await Book.find({ status: 'online' })
        .sort({ readCount: -1 })
        .limit(Number(limit))
        .select('-exercises')
        .lean();

      return success(res, {
        list: hotBooks,
        reason: '热门推荐'
      });
    }

    const child = await Child.findById(childId).lean();
    if (!child) {
      return error(res, 40410, '儿童档案不存在', 404);
    }

    const currentLevel = child.currentLevel || 1;
    const knownSet = new Set(
      (child.knownCharacters || []).map(id => id.toString())
    );

    // 策略1：当前级别未读绘本（优先）
    const levelBooks = await Book.find({
      level: currentLevel,
      status: 'online'
    })
      .sort({ sortOrder: 1 })
      .select('-exercises')
      .lean();

    // 计算每本绘本的新字覆盖率
    const booksWithProgress = levelBooks.map(book => {
      const newWordIds = (book.newWords || []).map(id => id.toString());
      const masteredCount = newWordIds.filter(id => knownSet.has(id)).length;
      const masteryRate = newWordIds.length > 0
        ? masteredCount / newWordIds.length
        : 0;

      return {
        ...book,
        newWordMasteryRate: masteryRate,
        masteredNewWords: masteredCount,
        totalNewWords: newWordIds.length
      };
    });

    // 优先推荐覆盖率30%-70%的（有挑战但不会太难）
    const moderate = booksWithProgress
      .filter(b => b.newWordMasteryRate >= 0.3 && b.newWordMasteryRate <= 0.7)
      .sort((a, b) => b.newWordMasteryRate - a.newWordMasteryRate);

    // 其次推荐覆盖率<30%的（全新挑战）
    const challenging = booksWithProgress
      .filter(b => b.newWordMasteryRate < 0.3)
      .sort((a, b) => a.newWordMasteryRate - b.newWordMasteryRate);

    // 最后推荐覆盖率>70%的（复习巩固）
    const review = booksWithProgress
      .filter(b => b.newWordMasteryRate > 0.7)
      .sort((a, b) => a.newWordMasteryRate - b.newWordMasteryRate);

    // 合并推荐列表
    let recommended = [...moderate, ...challenging, ...review];

    // 如果当前级别推荐不足，补充相邻级别
    if (recommended.length < limit) {
      const adjacentBooks = await Book.find({
        level: { $in: [currentLevel - 1, currentLevel + 1].filter(l => l >= 1 && l <= 5) },
        status: 'online',
        _id: { $nin: recommended.map(b => b._id) }
      })
        .sort({ level: 1, sortOrder: 1 })
        .select('-exercises')
        .lean();

      recommended = [...recommended, ...adjacentBooks];
    }

    // 截取指定数量
    recommended = recommended.slice(0, Number(limit));

    success(res, {
      list: recommended,
      childLevel: currentLevel,
      reason: `基于L${currentLevel}级别推荐`
    });
  } catch (err) {
    console.error('获取推荐绘本失败:', err);
    error(res, 50001, '获取推荐绘本失败', 500);
  }
};

/**
 * 获取免费绘本列表
 * GET /api/v1/books/free
 */
exports.getFreeBooks = async (req, res) => {
  try {
    const { level, page = 1, pageSize = 20 } = req.query;

    const filter = { isFree: true, status: 'online' };
    if (level) filter.level = Number(level);

    const total = await Book.countDocuments(filter);
    const books = await Book.find(filter)
      .select('-exercises')
      .sort({ sortOrder: 1 })
      .skip((page - 1) * pageSize)
      .limit(Number(pageSize))
      .lean();

    success(res, {
      list: books,
      pagination: paginate(page, pageSize, total)
    });
  } catch (err) {
    console.error('获取免费绘本失败:', err);
    error(res, 50001, '获取免费绘本失败', 500);
  }
};

/**
 * 获取绘本主题列表
 * GET /api/v1/books/themes
 */
exports.getThemes = async (req, res) => {
  try {
    const themes = await Book.aggregate([
      { $match: { status: 'online' } },
      { $group: { _id: '$theme', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $project: { theme: '$_id', count: 1, _id: 0 } }
    ]);

    success(res, themes);
  } catch (err) {
    console.error('获取主题列表失败:', err);
    error(res, 50001, '获取主题列表失败', 500);
  }
};
