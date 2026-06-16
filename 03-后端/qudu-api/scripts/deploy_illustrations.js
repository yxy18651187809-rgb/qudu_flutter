/**
 * L3/L4/L5 插画批量部署脚本
 * 
 * 将 04-设计/ 目录下的 PNG 插画复制到 uploads/ 目录，
 * 并在数据库中创建 Book + BookPage 记录，设置 image 字段。
 * 
 * 用法:
 *   node scripts/deploy_illustrations.js          # 仅复制文件（不操作数据库）
 *   node scripts/deploy_illustrations.js --db     # 复制文件 + 创建/更新数据库记录
 *   node scripts/deploy_illustrations.js --db --level L3  # 仅处理L3
 *   node scripts/deploy_illustrations.js --verify  # 仅验证（不复制不写DB）
 * 
 * 命名映射:
 *   设计目录: L3-045_守株待兔_P00.png
 *   uploads封面: covers/L3-045_cover.png
 *   uploads内页: pages/L3-045_P01.png
 *   数据库: Book.bookId = "L3_book_045", BookPage.image = "/uploads/pages/L3-045_P01.png"
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
const config = require('../src/config');

// ============== 配置 ==============

const DESIGN_DIR = path.join(__dirname, '../../../04-设计');
const UPLOADS_DIR = path.join(__dirname, '../uploads');
const COVERS_DIR = path.join(UPLOADS_DIR, 'covers');
const PAGES_DIR = path.join(UPLOADS_DIR, 'pages');

// 故事配置: level → story[]
const STORY_CONFIG = {
  L3: {
    startNum: 45, endNum: 64, level: 3,
    pagesPerStory: 14, // P00~P13 (P00封面 + P01~P13内容)
    stories: [
      { num: 45, title: '守株待兔' }, { num: 46, title: '小水滴的旅行' },
      { num: 47, title: '我的班级' }, { num: 48, title: '小种子的梦' },
      { num: 49, title: '鸟巢的秘密' }, { num: 50, title: '司马光砸缸' },
      { num: 51, title: '小小动物园' }, { num: 52, title: '我家的小菜园' },
      { num: 53, title: '第一次做饭' }, { num: 54, title: '森林音乐会' },
      { num: 55, title: '小蝌蚪找妈妈' }, { num: 56, title: '雪孩子' },
      { num: 57, title: '乌鸦喝水' }, { num: 58, title: '蚂蚁和蝈蝈' },
      { num: 59, title: '狼来了' }, { num: 60, title: '坐井观天' },
      { num: 61, title: '狐假虎威' }, { num: 62, title: '精卫填海' },
      { num: 63, title: '女娲补天' }, { num: 64, title: '神奇的花' },
    ]
  },
  L4: {
    startNum: 65, endNum: 84, level: 4,
    pagesPerStory: 15, // P00~P14 (P00封面 + P01~P14内容) — 标准格式
    stories: [
      { num: 65, title: '孔融让梨' }, { num: 66, title: '海底世界' },
      { num: 67, title: '运动会的一天' }, { num: 68, title: '小发明家' },
      { num: 69, title: '山里的老树' }, { num: 70, title: '盲人摸象' },
      { num: 71, title: '我的家乡' }, { num: 72, title: '食物的旅行' },
      { num: 73, title: '图书馆的故事' }, { num: 74, title: '小英雄雨来' },
      { num: 75, title: '太阳系探险' }, { num: 76, title: '友谊的桥' },
      { num: 77, title: '变色龙的秘密' }, { num: 78, title: '第一次登台' },
      { num: 79, title: '美丽的汉字' }, { num: 80, title: '画龙点睛' },
      { num: 81, title: '火山为什么会喷发' }, { num: 82, title: '邻居' },
      { num: 83, title: '鱼和鱼竿' }, { num: 84, title: '丝绸之路' },
    ]
  },
  L5: {
    startNum: 85, endNum: 104, level: 5,
    pagesPerStory: 14, // P00~P13 (P00封面 + P01~P13内容)
    stories: [
      { num: 85, title: '论语故事' }, { num: 86, title: '宇宙的奥秘' },
      { num: 87, title: '假如我是你' }, { num: 88, title: '千字文故事' },
      { num: 89, title: '人工智能来了' }, { num: 90, title: '唐诗里的春天' },
      { num: 91, title: '什么是公平' }, { num: 92, title: '郑和下西洋' },
      { num: 93, title: '微观世界' }, { num: 94, title: '我的第一次辩论' },
      { num: 95, title: '三国故事' }, { num: 96, title: '气候变暖' },
      { num: 97, title: '不同的家庭' }, { num: 98, title: '本草的故事' },
      { num: 99, title: '编程的乐趣' }, { num: 100, title: '长征路上' },
      { num: 101, title: '看不见的力量' }, { num: 102, title: '我的未来城市' },
      { num: 103, title: '山海经选读' }, { num: 104, title: '成长的意义' },
    ]
  }
};

// ============== 工具函数 ==============

function getStoryPrefix(level, num) {
  return `${level}-${String(num).padStart(3, '0')}`;
}

function getDesignFilePath(level, num, title, pageCode) {
  const prefix = getStoryPrefix(level, num);
  return path.join(DESIGN_DIR, `${prefix}_${title}_${pageCode}.png`);
}

function getCoverDestPath(level, num) {
  const prefix = getStoryPrefix(level, num);
  return path.join(COVERS_DIR, `${prefix}_cover.png`);
}

function getPageDestPath(level, num, pageCode) {
  const prefix = getStoryPrefix(level, num);
  return path.join(PAGES_DIR, `${prefix}_${pageCode}.png`);
}

function getCoverDbPath(level, num) {
  const prefix = getStoryPrefix(level, num);
  return `/uploads/covers/${prefix}_cover.png`;
}

function getPageDbPath(level, num, pageCode) {
  const prefix = getStoryPrefix(level, num);
  return `/uploads/pages/${prefix}_${pageCode}.png`;
}

// ============== 文件复制 ==============

async function copyFiles(levelKey, filterLevel) {
  if (filterLevel && filterLevel !== levelKey) return { copied: 0, skipped: 0, missing: 0 };

  const cfg = STORY_CONFIG[levelKey];
  let copied = 0, skipped = 0, missing = 0;

  console.log(`\n[Deploy] ===== ${levelKey} 插画文件复制 =====`);

  // 确保目录存在
  fs.mkdirSync(COVERS_DIR, { recursive: true });
  fs.mkdirSync(PAGES_DIR, { recursive: true });

  for (const story of cfg.stories) {
    const { num, title } = story;
    const prefix = getStoryPrefix(levelKey, num);

    // 自动检测实际页数（从设计目录扫描）
    const designFiles = fs.readdirSync(DESIGN_DIR)
      .filter(f => f.startsWith(`${prefix}_`) && f.endsWith('.png'))
      .sort();

    if (designFiles.length === 0) {
      console.log(`[Deploy] ⚠️ ${prefix}《${title}》无设计文件`);
      missing++;
      continue;
    }

    for (const designFile of designFiles) {
      const srcPath = path.join(DESIGN_DIR, designFile);
      // 从文件名提取页码: L3-045_守株待兔_P01.png → P01
      const pageMatch = designFile.match(/_(P\d+)\.png$/);
      if (!pageMatch) {
        console.log(`[Deploy] ⚠️ 无法解析页码: ${designFile}`);
        continue;
      }
      const pageCode = pageMatch[1];

      // P00 → 封面, P01+ → 内页
      let destPath, dbPath;
      if (pageCode === 'P00') {
        destPath = getCoverDestPath(levelKey, num);
        dbPath = getCoverDbPath(levelKey, num);
      } else {
        destPath = getPageDestPath(levelKey, num);
        dbPath = getPageDbPath(levelKey, num);
      }

      if (fs.existsSync(destPath)) {
        skipped++;
      } else {
        fs.copyFileSync(srcPath, destPath);
        copied++;
      }
    }

    console.log(`[Deploy] ✅ ${prefix}《${title}》${designFiles.length}张 (${copied}新+${skipped}已有)`);
  }

  return { copied, skipped, missing };
}

// ============== 数据库操作 ==============

async function updateDatabase(levelKey, filterLevel) {
  if (filterLevel && filterLevel !== levelKey) return;

  const cfg = STORY_CONFIG[levelKey];
  console.log(`\n[Deploy] ===== ${levelKey} 数据库记录创建/更新 =====`);

  for (const story of cfg.stories) {
    const { num, title } = story;
    const prefix = getStoryPrefix(levelKey, num);
    const bookId = `${levelKey}_book_${String(num).padStart(3, '0')}`;

    // 自动检测实际页数
    const designFiles = fs.readdirSync(DESIGN_DIR)
      .filter(f => f.startsWith(`${prefix}_`) && f.endsWith('.png'))
      .sort();

    if (designFiles.length === 0) {
      console.log(`[Deploy] ⚠️ ${prefix} 无设计文件，跳过DB创建`);
      continue;
    }

    // 提取内容页数量（排除P00封面）
    const contentPages = designFiles.filter(f => !f.includes('_P00.'));
    const totalPages = contentPages.length;

    // 1. 创建/更新 Book
    const coverDbPath = getCoverDbPath(levelKey, num);
    let book = await Book.findOne({ bookId });
    if (book) {
      book.cover = coverDbPath;
      book.pageCount = totalPages;
      await book.save();
      console.log(`[Deploy] 📖 ${bookId}《${title}》Book已更新 (cover=${coverDbPath}, pages=${totalPages})`);
    } else {
      book = await Book.create({
        bookId,
        title,
        level: cfg.level,
        theme: '综合',
        cover: coverDbPath,
        description: `${levelKey}级别绘本《${title}》`,
        pageCount: totalPages,
        status: 'online',
      });
      console.log(`[Deploy] 📖 ${bookId}《${title}》Book已创建 (cover=${coverDbPath}, pages=${totalPages})`);
    }

    // 2. 创建/更新 BookPage
    let pagesCreated = 0, pagesUpdated = 0;
    for (const designFile of contentPages) {
      const pageMatch = designFile.match(/_(P\d+)\.png$/);
      if (!pageMatch) continue;
      const pageCode = pageMatch[1];
      const pageNumber = parseInt(pageCode.substring(1)); // P01 → 1
      const imageDbPath = getPageDbPath(levelKey, num, pageCode);

      const existing = await BookPage.findOne({ bookId: book._id, pageNumber });
      if (existing) {
        if (!existing.image) {
          existing.image = imageDbPath;
          await existing.save();
          pagesUpdated++;
        }
      } else {
        await BookPage.create({
          bookId: book._id,
          pageNumber,
          text: `第${pageNumber}页`,
          image: imageDbPath,
        });
        pagesCreated++;
      }
    }

    console.log(`[Deploy]   📄 BookPage: ${pagesCreated}新建 + ${pagesUpdated}更新`);
  }
}

// ============== 验证 ==============

async function verify(levelKey, filterLevel) {
  if (filterLevel && filterLevel !== levelKey) return;

  const cfg = STORY_CONFIG[levelKey];
  console.log(`\n[Deploy] ===== ${levelKey} 验证 =====`);

  let totalExpected = 0, totalFound = 0, totalMissing = 0;

  for (const story of cfg.stories) {
    const { num, title } = story;
    const prefix = getStoryPrefix(levelKey, num);

    // 扫描设计目录
    const designFiles = fs.readdirSync(DESIGN_DIR)
      .filter(f => f.startsWith(`${prefix}_`) && f.endsWith('.png'));

    // 检查 uploads
    let found = 0, missing_files = [];
    for (const df of designFiles) {
      totalExpected++;
      const pageMatch = df.match(/_(P\d+)\.png$/);
      if (!pageMatch) continue;
      const pageCode = pageMatch[1];

      let destPath;
      if (pageCode === 'P00') {
        destPath = getCoverDestPath(levelKey, num);
      } else {
        destPath = getPageDestPath(levelKey, num);
      }

      if (fs.existsSync(destPath)) {
        found++;
        totalFound++;
      } else {
        missing_files.push(pageCode);
        totalMissing++;
      }
    }

    const status = found === designFiles.length ? '✅' : missing_files.length > 0 ? '⚠️' : '❌';
    console.log(`  ${status} ${prefix}《${title}》 ${found}/${designFiles.length} ${missing_files.length > 0 ? '缺: ' + missing_files.join(',') : ''}`);
  }

  console.log(`\n[Deploy] ${levelKey} 总计: ${totalFound}/${totalExpected} 已部署, ${totalMissing} 缺失`);
  return { totalExpected, totalFound, totalMissing };
}

// ============== 主函数 ==============

async function main() {
  const args = process.argv.slice(2);
  const doDB = args.includes('--db');
  const doVerify = args.includes('--verify');
  const levelFilter = args.find(a => a.startsWith('--level='))?.split('=')[1]
    || (args.includes('--level') ? args[args.indexOf('--level') + 1] : null);

  console.log('[Deploy] ===== L3/L4/L5 插画部署工具 =====');
  console.log(`[Deploy] 模式: ${doVerify ? '验证' : '部署'}${doDB ? '+数据库' : '仅文件'}${levelFilter ? ` (${levelFilter} only)` : ' (全量)'}`);
  console.log(`[Deploy] 设计目录: ${DESIGN_DIR}`);
  console.log(`[Deploy] 目标目录: ${UPLOADS_DIR}`);

  // 验证设计目录
  if (!fs.existsSync(DESIGN_DIR)) {
    console.error(`[Deploy] ❌ 设计目录不存在: ${DESIGN_DIR}`);
    process.exit(1);
  }

  const levels = levelFilter ? [levelFilter] : ['L3', 'L4', 'L5'];

  if (doVerify) {
    // 仅验证模式
    if (doDB) {
      await mongoose.connect(config.mongodb.uri);
      console.log('[Deploy] 数据库已连接');
    }
    for (const lv of levels) {
      await verify(lv, null);
    }
    if (doDB) await mongoose.disconnect();
    return;
  }

  // 部署模式
  let totalCopied = 0, totalSkipped = 0, totalMissing = 0;
  for (const lv of levels) {
    const result = await copyFiles(lv, null);
    totalCopied += result.copied;
    totalSkipped += result.skipped;
    totalMissing += result.missing;
  }

  console.log(`\n[Deploy] ===== 文件复制完成 =====`);
  console.log(`总复制: ${totalCopied}, 已存在跳过: ${totalSkipped}, 缺失源文件: ${totalMissing}`);

  // 数据库操作
  if (doDB) {
    await mongoose.connect(config.mongodb.uri);
    console.log('[Deploy] 数据库已连接');

    for (const lv of levels) {
      await updateDatabase(lv, null);
    }

    await mongoose.disconnect();
    console.log('[Deploy] 数据库已断开');
  }

  // 验证
  console.log(`\n[Deploy] ===== 验证 =====`);
  for (const lv of levels) {
    await verify(lv, null);
  }

  console.log(`\n[Deploy] ===== 全部完成 =====`);
}

main().catch(err => {
  console.error('[Deploy] 错误:', err);
  process.exit(1);
});
