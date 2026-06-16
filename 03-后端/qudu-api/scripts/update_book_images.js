/**
 * 更新所有级别的绘本BookPage.image路径
 * 支持L1（10本×10页）和L2（6本×10页）
 * 
 * 用法: node scripts/update_book_images.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
const config = require('../src/config');

async function updateBookImages() {
  try {
    await mongoose.connect(config.mongodb.uri);
    console.log('[UpdateImages] 已连接数据库');

    // L1配置：10本，每本10页（P01-P10）
    const L1Configs = [
      { bookId: 'L1_book_01', bookNum: '01', title: '我的身体', pages: 10 },
      { bookId: 'L1_book_02', bookNum: '02', title: '早上好', pages: 10 },
      { bookId: 'L1_book_03', bookNum: '03', title: '小兔子找妈妈', pages: 10 },
      { bookId: 'L1_book_04', bookNum: '04', title: '一二三上学去', pages: 10 },
      { bookId: 'L1_book_05', bookNum: '05', title: '红红的太阳', pages: 10 },
      { bookId: 'L1_book_06', bookNum: '06', title: '好吃的果子', pages: 10 },
      { bookId: 'L1_book_07', bookNum: '07', title: '家的小动物', pages: 10 },
      { bookId: 'L1_book_08', bookNum: '08', title: '四季歌', pages: 10 },
      { bookId: 'L1_book_09', bookNum: '09', title: '小明的家', pages: 10 },
      { bookId: 'L1_book_10', bookNum: '10', title: '去公园玩', pages: 10 },
    ];

    // L2配置：6本online，每本10页（P01-P10）
    const L2Configs = [
      { bookId: 'L2_book_01', bookNum: '01', title: '我的好朋友', pages: 10 },
      { bookId: 'L2_book_02', bookNum: '02', title: '春游去', pages: 10 },
      { bookId: 'L2_book_03', bookNum: '03', title: '端午节', pages: 10 },
      { bookId: 'L2_book_04', bookNum: '04', title: '小树长大了', pages: 10 },
      { bookId: 'L2_book_05', bookNum: '05', title: '小雨滴', pages: 10 },
      { bookId: 'L2_book_06', bookNum: '06', title: '小雪花', pages: 10 },
    ];

    const allConfigs = [...L1Configs, ...L2Configs];
    let totalUpdated = 0;
    let totalBooks = 0;

    for (const cfg of allConfigs) {
      // 1. 更新Book封面
      const coverPath = `/uploads/covers/book_cover_${cfg.bookNum}.png`;
      const book = await Book.findOneAndUpdate(
        { bookId: cfg.bookId },
        { cover: coverPath },
        { new: true }
      );
      if (book) {
        console.log(`[UpdateImages] ✅ ${cfg.bookId}《${cfg.title}》封面更新: ${coverPath}`);
        totalBooks++;
      } else {
        console.log(`[UpdateImages] ⚠️ ${cfg.bookId}《${cfg.title}》未找到`);
        continue;
      }

      // 2. 更新BookPage图片路径
      // 图片已放到 uploads/pages/ 目录，命名格式：XX_P0Y.png（不含book_前缀）
      let pagesUpdated = 0;
      for (let pageNum = 1; pageNum <= cfg.pages; pageNum++) {
        const pageImage = `/uploads/pages/${cfg.bookNum}_P${String(pageNum).padStart(2, '0')}.png`;
        const result = await BookPage.updateOne(
          { bookId: book._id, pageNumber: pageNum },
          { image: pageImage }
        );
        if (result.modifiedCount > 0) {
          pagesUpdated++;
        }
      }

      console.log(`[UpdateImages] ✅ ${cfg.bookId}《${cfg.title}》页面图片更新: ${pagesUpdated}/${cfg.pages}`);
      totalUpdated += pagesUpdated;
    }

    console.log(`\n[UpdateImages] ===== 完成 =====`);
    console.log(`总更新页面数: ${totalUpdated}`);
    console.log(`封面更新: ${totalBooks} 本`);

    // 验证：打印L2的image字段
    console.log(`\n[UpdateImages] ===== 验证 L2 =====`);
    for (const cfg of L2Configs) {
      const book = await Book.findOne({ bookId: cfg.bookId }).lean();
      if (!book) continue;
      const pages = await BookPage.find({ bookId: book._id })
        .sort({ pageNumber: 1 })
        .select('pageNumber image')
        .lean();
      console.log(`\n${cfg.bookId}《${cfg.title}》cover=${book.cover}`);
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
