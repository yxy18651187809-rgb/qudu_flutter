/**
 * 更新绘本04-08的BookPage.image路径
 * 将插画师交付的真实图片路径写入数据库
 *
 * 用法: node scripts/update_book_images.js
 *
 * 映射规则：
 * - P00 → 封面页（绘本04-06有独立P00，07-08用封面图替代）
 * - P01-P10 → 内页
 * - 路径格式: /uploads/books/book_XX_PXX.png
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const path = require('path');
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
const config = require('../src/config');

async function updateBookImages() {
  try {
    await mongoose.connect(config.mongodb.uri);
    console.log('[UpdateImages] 已连接数据库');

    // 绘本配置：bookId → 内页数量（P00-P10 = 11张）
    const bookConfigs = [
      { bookId: 'L1_book_04', bookNum: '04', title: '一二三上学去' },
      { bookId: 'L1_book_05', bookNum: '05', title: '红红的太阳' },
      { bookId: 'L1_book_06', bookNum: '06', title: '好吃的果子' },
      { bookId: 'L1_book_07', bookNum: '07', title: '家的小动物' },
      { bookId: 'L1_book_08', bookNum: '08', title: '四季歌' },
    ];

    let totalUpdated = 0;

    for (const cfg of bookConfigs) {
      // 1. 更新Book封面
      const coverPath = `/uploads/covers/book_cover_${cfg.bookNum}.png`;
      const book = await Book.findOneAndUpdate(
        { bookId: cfg.bookId },
        { cover: coverPath },
        { new: true }
      );
      if (book) {
        console.log(`[UpdateImages] ✅ 绘本${cfg.bookNum}《${cfg.title}》封面更新: ${coverPath}`);
      } else {
        console.log(`[UpdateImages] ⚠️ 绘本${cfg.bookNum}《${cfg.title}》未找到 (bookId: ${cfg.bookId})`);
        continue;
      }

      // 2. 更新BookPage图片路径
      // 图片已放到 uploads/pages/ 目录，命名格式：XX_P0Y.png（不含book_前缀）
      let pagesUpdated = 0;
      for (let pageNum = 1; pageNum <= 10; pageNum++) {
        const pageImage = `/uploads/pages/${cfg.bookNum}_P${String(pageNum).padStart(2, '0')}.png`;
        const result = await BookPage.updateOne(
          { bookId: book._id, pageNumber: pageNum },
          { image: pageImage }
        );
        if (result.modifiedCount > 0) {
          pagesUpdated++;
        }
      }

      console.log(`[UpdateImages] ✅ 绘本${cfg.bookNum}《${cfg.title}》页面图片更新: ${pagesUpdated}/10`);
      totalUpdated += pagesUpdated;
    }

    console.log(`\n[UpdateImages] ===== 完成 =====`);
    console.log(`总更新页面数: ${totalUpdated}`);
    console.log(`封面更新: ${bookConfigs.length} 本`);

    // 验证：打印绘本04-08的image字段
    console.log(`\n[UpdateImages] ===== 验证 =====`);
    for (const cfg of bookConfigs) {
      const book = await Book.findOne({ bookId: cfg.bookId }).lean();
      if (!book) continue;
      const pages = await BookPage.find({ bookId: book._id })
        .sort({ pageNumber: 1 })
        .select('pageNumber image')
        .lean();
      console.log(`\n绘本${cfg.bookNum}《${cfg.title}》cover=${book.cover}`);
      pages.forEach(p => {
        const hasImage = p.image ? '✅' : '❌';
        console.log(`  Page ${p.pageNumber}: ${hasImage} ${p.image || '(空)'}`);
      });
    }

    await mongoose.disconnect();
    console.log('\n[UpdateImages] 数据库已断开');
  } catch (err) {
    console.error('[UpdateImages] 错误:', err);
    process.exit(1);
  }
}

updateBookImages();
