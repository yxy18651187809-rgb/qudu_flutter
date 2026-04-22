// 绘本书架 Repository
// 对应后端 API：GET /books（列表）、GET /books/:id（详情）、GET /books/:id/content（章节内容）
// 当前阶段：本地 Mock 数据 + 等后端 API 就绪后接入真实接口
import '../models/book_model.dart';

/// 绘本 Repository — 提供本地缓存 + API 双模式
class BooksRepository {
  /// 获取绘本列表（按级别筛选）
  /// TODO: 后端 API 就绪后替换为真实接口
  Future<List<BookModel>> getBooks({String? level, String? childId}) async {
    // 阶段一：返回 Mock 数据
    await Future.delayed(const Duration(milliseconds: 300));

    var books = _mockBooks;

    // 按级别筛选
    if (level != null && level.isNotEmpty) {
      books = books.where((b) => b.level == level).toList();
    }

    return books;
  }

  /// 获取单个绘本详情
  Future<BookModel?> getBookDetail(String bookId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockBooks.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// 获取推荐绘本（3本）
  /// 策略：优先推荐新字覆盖率 30%-70% 的绘本
  Future<List<BookModel>> getRecommendedBooks({String? childId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock: 返回前3本绘本作为推荐
    return _mockBooks.take(3).toList();
  }

  // ===========================================================================
  // Mock 数据 — 阶段一占位，等后端 seed 数据接入后替换
  // ===========================================================================
  static final List<BookModel> _mockBooks = [
    BookModel(
      id: 'book_001',
      title: '我的身体',
      cover: 'assets/images/books/book_cover_01.png',
      level: 'L1',
      newWords: ['我', '的', '头', '眼', '耳', '口', '手', '足', '心', '身'],
      totalPages: 10,
      readCount: 0,
      isCompleted: false,
    ),
    BookModel(
      id: 'book_002',
      title: '早上好',
      cover: 'assets/images/books/book_cover_02.png',
      level: 'L1',
      newWords: ['早', '上', '好', '太', '阳', '月', '亮', '星', '天', '起'],
      totalPages: 10,
      readCount: 2,
      isCompleted: false,
    ),
    BookModel(
      id: 'book_003',
      title: '小兔子找妈妈',
      cover: 'assets/images/books/book_cover_03.png',
      level: 'L1',
      newWords: ['小', '兔', '子', '找', '妈', '爸', '家', '走', '跑', '跳'],
      totalPages: 10,
      readCount: 0,
      isCompleted: false,
    ),
    BookModel(
      id: 'book_004',
      title: '一二三上学去',
      cover: 'assets/images/books/book_cover_04.png',
      level: 'L1',
      newWords: ['一', '二', '三', '上', '学', '去', '来', '回', '大', '小'],
      totalPages: 10,
      readCount: 0,
      isCompleted: false,
    ),
    BookModel(
      id: 'book_005',
      title: '红红的太阳',
      cover: 'assets/images/books/book_cover_05.png',
      level: 'L1',
      newWords: ['红', '火', '水', '风', '雨', '雪', '花', '草', '树', '叶'],
      totalPages: 10,
      readCount: 0,
      isCompleted: false,
    ),
    BookModel(
      id: 'book_006',
      title: '趣趣找春天',
      cover: 'assets/images/books/book_cover_06.png',
      level: 'L1',
      newWords: ['春', '夏', '秋', '冬', '季', '节', '候', '气', '温', '暖'],
      totalPages: 10,
      readCount: 0,
      isCompleted: false,
    ),
  ];
}
