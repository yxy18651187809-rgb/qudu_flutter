/**
 * L1音频资源Seed脚本
 * 功能：将 uploads/audio/ 目录下的MP3文件关联到Character模型的audioUrl字段
 * 
 * 使用方法：
 * 1. 确保MongoDB已启动
 * 2. 运行: node scripts/seed_L1_audio.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');

// 加载配置和模型
const config = require('../src/config');
const Character = require('../src/models/Character');

const AUDIO_DIR = path.join(__dirname, '../uploads/audio');

async function seedL1Audio() {
  try {
    // 1. 连接MongoDB
    console.log('[Seed-L1-Audio] 正在连接MongoDB...');
    await mongoose.connect(config.mongodb.uri);
    console.log('[Seed-L1-Audio] MongoDB连接成功');

    // 2. 读取音频目录
    console.log(`[Seed-L1-Audio] 读取音频目录: ${AUDIO_DIR}`);
    const audioFiles = fs.readdirSync(AUDIO_DIR)
      .filter(file => file.endsWith('.mp3'));
    
    console.log(`[Seed-L1-Audio] 找到 ${audioFiles.length} 个音频文件`);

    // 3. 统计变量
    let updatedCount = 0;
    let notFoundCount = 0;
    let alreadySetCount = 0;
    const notFoundChars = [];

    // 4. 遍历音频文件，更新Character
    console.log('[Seed-L1-Audio] 开始更新Character音频路径...');
    
    for (const audioFile of audioFiles) {
      // 提取字符（去掉.mp3后缀）
      const character = audioFile.replace(/\.mp3$/i, '');
      const audioUrl = `/uploads/audio/${audioFile}`;

      // 查找并更新
      const charDoc = await Character.findOne({ character });
      
      if (!charDoc) {
        notFoundCount++;
        notFoundChars.push(character);
        console.warn(`[Seed-L1-Audio] 警告: 字符「${character}」未在Character集合中找到`);
        continue;
      }

      // 检查是否已有音频URL
      if (charDoc.audioUrl && charDoc.audioUrl !== '') {
        alreadySetCount++;
        console.log(`[Seed-L1-Audio] 跳过: 字符「${character}」已有音频 ${charDoc.audioUrl}`);
        continue;
      }

      // 更新audioUrl
      charDoc.audioUrl = audioUrl;
      await charDoc.save();
      
      updatedCount++;
      if (updatedCount % 50 === 0) {
        console.log(`[Seed-L1-Audio] 进度: ${updatedCount}/${audioFiles.length}`);
      }
    }

    // 5. 输出统计结果
    console.log('\n========== Seed L1 Audio 完成 ==========');
    console.log(`✅ 成功更新: ${updatedCount} 个字符`);
    console.log(`⏭️  跳过(已有音频): ${alreadySetCount} 个字符`);
    console.log(`❌ 未找到字符: ${notFoundCount} 个`);
    
    if (notFoundChars.length > 0) {
      console.log(`\n未找到的字符: ${notFoundChars.join('、')}`);
      console.log('提示: 请先运行 seed.js 导入L1字符数据');
    }

    console.log('========================================\n');

  } catch (error) {
    console.error('[Seed-L1-Audio] 错误:', error);
    throw error;
  } finally {
    // 关闭数据库连接
    await mongoose.disconnect();
    console.log('[Seed-L1-Audio] MongoDB连接已关闭');
  }
}

// 执行
seedL1Audio()
  .then(() => {
    console.log('[Seed-L1-Audio] 脚本执行成功');
    process.exit(0);
  })
  .catch((error) => {
    console.error('[Seed-L1-Audio] 脚本执行失败:', error);
    process.exit(1);
  });
