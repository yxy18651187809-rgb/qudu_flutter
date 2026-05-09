/**
 * 为现有 Book 文档添加 bookId 字段
 * 运行: node scripts/add_book_id.js
 */

const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const Book = require('../src/models/Book');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://qudu:qudu_dev_2026@localhost:27017/qudu?authSource=admin';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('[DB] 已连接');

  // 查找所有没有 bookId 的 Book
  const books = await Book.find({ bookId: { $exists: false } }).sort({ level: 1, sortOrder: 1 });
  console.log(`[DB] 找到 ${books.length} 个需要更新的 Book`);

  if (books.length === 0) {
    console.log('[DB] 所有 Book 已有 bookId，无需更新');
    await mongoose.disconnect();
    return;
  }

  // 按级别分组，每组按 sortOrder 排序，生成连续编号
  const levelCounters = {};
  let updated = 0;

  for (const book of books) {
    const level = book.level || 1;
    if (!levelCounters[level]) levelCounters[level] = 0;
    levelCounters[level]++;

    // 格式: L1_book_01, L2_book_01, ...
    const bookId = `L${level}_book_${String(levelCounters[level]).padStart(2, '0')}`;

    try {
      book.bookId = bookId;
      await book.save();
      console.log(`[DB] 已更新: ${book.title} (L${level}) → ${bookId}`);
      updated++;
    } catch (err) {
      console.error(`[DB] 更新失败: ${book.title} → ${bookId}: ${err.message}`);
    }
  }

  console.log(`[DB] 更新完成: ${updated}/${books.length}`);
  await mongoose.disconnect();
}

main().catch(err => {
  console.error('[ERROR]', err);
  process.exit(1);
});
