/**
 * 全量种子脚本（一键恢复）
 * 用法: node scripts/seed_all.js
 *
 * 按顺序执行 seed.js → seed_L2_books.js → seed_L345_characters.js
 * 每次执行前检查数据是否已存在，跳过已有的数据（幂等安全）
 *
 * 场景：
 * - 数据库全新安装后恢复
 * - 系统重启后一键重建
 * - 开发环境数据重置
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');

const SCRIPTS = [
  { name: 'L1 字库+绘本', file: 'seed.js' },
  { name: 'L2 绘本', file: 'seed_L2_books.js' },
  { name: 'L3/L4/L5 字库', file: 'seed_L345_characters.js' }
];

async function run() {
  console.log('[Seed-All] 🚀 全量种子开始执行...\n');

  // 1. 连接 MongoDB
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('[Seed-All] MongoDB 已连接');

  // 2. 检查当前数据
  const Character = require('../src/models/Character');
  const Book = require('../src/models/Book');
  const currentChars = await Character.countDocuments({});
  const currentBooks = await Book.countDocuments({});

  if (currentChars >= 1250 && currentBooks >= 20) {
    console.log(`[Seed-All] ✅ 数据已完整 (${currentChars}字 + ${currentBooks}本绘本)，无需重新seed\n`);
    await mongoose.disconnect();
    return;
  }

  console.log(`[Seed-All] 当前数据: ${currentChars}字 + ${currentBooks}本绘本，需要补充`);

  // 3. 依次执行
  for (const script of SCRIPTS) {
    console.log(`\n[Seed-All] ▶ 执行 ${script.name} (${script.file})...`);
    try {
      require(`./${script.file.replace('.js', '')}`);
    } catch (err) {
      console.error(`[Seed-All] ❌ ${script.name} 失败:`, err.message);
    }
    // 等待异步操作完成
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  // 4. 验证
  const finalChars = await Character.countDocuments({});
  const finalBooks = await Book.countDocuments({});
  console.log(`\n[Seed-All] 📊 最终结果: ${finalChars}字 (L1:${await Character.countDocuments({level:1})} L2:${await Character.countDocuments({level:2})} L3:${await Character.countDocuments({level:3})} L4:${await Character.countDocuments({level:4})} L5:${await Character.countDocuments({level:5})}) + ${finalBooks}本绘本`);

  const status = finalChars >= 1250 ? '✅ 完整' : '⚠️ 不完整，请手动检查';
  console.log(`[Seed-All] ${status}`);

  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => {
  console.error('[Seed-All] ❌ 致命错误:', err);
  process.exit(1);
});
