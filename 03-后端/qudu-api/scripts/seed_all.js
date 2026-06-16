/**
 * 全量种子脚本（一键恢复）
 * 用法: node scripts/seed_all.js
 *
 * 按顺序执行 seed.js → seed_L2_books.js → seed_L345_characters.js
 * 每个种子脚本作为独立进程运行，执行前检查数据完整性
 *
 * 场景：
 * - 数据库全新安装后恢复
 * - 系统重启后一键重建
 * - 开发环境数据重置
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const { execSync } = require('child_process');
const path = require('path');

const SCRIPTS_DIR = __dirname;
const NODE = process.execPath;

const STEPS = [
  { name: 'L1 字库(301字)+绘本(10本)', script: 'seed.js' },
  { name: 'L2 绘本(10本)', script: 'seed_L2_books.js' },
  { name: 'L3(380)+L4(283)+L5(218) 字库', script: 'seed_L345_characters.js' }
];

async function run() {
  console.log('[Seed-All] 🚀 全量种子开始执行...\n');

  // 1. 检查当前数据
  await mongoose.connect(process.env.MONGODB_URI);
  const Character = require('../src/models/Character');
  const Book = require('../src/models/Book');
  const currentChars = await Character.countDocuments({});
  const currentBooks = await Book.countDocuments({});
  await mongoose.disconnect();

  if (currentChars >= 1250 && currentBooks >= 20) {
    console.log(`[Seed-All] ✅ 数据已完整 (${currentChars}字 + ${currentBooks}本)，跳过\n`);
    process.exit(0);
  }

  console.log(`[Seed-All] 当前: ${currentChars}字 + ${currentBooks}本 → 需要补全\n`);

  // 2. 依次执行
  for (const step of STEPS) {
    const scriptPath = path.join(SCRIPTS_DIR, step.script);
    console.log(`[Seed-All] ▶ 执行: ${step.name}`);
    try {
      execSync(`"${NODE}" "${scriptPath}"`, {
        cwd: path.join(SCRIPTS_DIR, '..'),
        stdio: 'inherit',
        timeout: 60000
      });
    } catch (err) {
      console.error(`[Seed-All] ❌ ${step.name} 失败 (exit code: ${err.status})`);
    }
  }

  // 3. 最终验证
  await mongoose.connect(process.env.MONGODB_URI);
  const Character2 = require('../src/models/Character');
  const Book2 = require('../src/models/Book');
  const finalChars = await Character2.countDocuments({});
  const finalBooks = await Book2.countDocuments({});

  const lvls = {};
  for (const l of [1, 2, 3, 4, 5]) {
    lvls[`L${l}`] = await Character2.countDocuments({ level: l });
  }

  console.log(`\n[Seed-All] 📊 结果: ${finalChars}字 (L1:${lvls.L1} L2:${lvls.L2} L3:${lvls.L3} L4:${lvls.L4} L5:${lvls.L5}) + ${finalBooks}本`);
  console.log(`[Seed-All] ${finalChars >= 1250 && finalBooks >= 20 ? '✅ 完整' : '⚠️ 不完整！'}`);

  await mongoose.disconnect();
  process.exit(finalChars >= 1250 && finalBooks >= 20 ? 0 : 1);
}

run().catch(err => {
  console.error('[Seed-All] ❌ 致命错误:', err);
  process.exit(1);
});
