/**
 * 数据库种子脚本
 * 用法: node scripts/seed.js
 * 
 * 导入初始数据：
 * - L1 核心汉字（从教研员交付的JSON文件导入）
 * - 测试用户（开发环境）
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const Character = require('../src/models/Character');
const User = require('../src/models/User');
const config = require('../src/config');

/**
 * 将中文 coreLevel 转换为英文
 */
function mapCoreLevel(value) {
  if (value === '核心') return 'core';
  if (value === '扩展') return 'extended';
  return value || 'core';
}

/**
 * 自动生成 Unicode 编码
 */
function generateUnicode(char) {
  const code = char.charCodeAt(0);
  return 'U+' + code.toString(16).toUpperCase().padStart(4, '0');
}

async function seed() {
  try {
    await mongoose.connect(config.mongodb.uri);
    console.log('[Seed] MongoDB 已连接');

    // ===== 导入汉字数据 =====
    const jsonPath = path.join(__dirname, '../../01-内容/L1核心字50_后端导入.json');
    
    if (fs.existsSync(jsonPath)) {
      // 清理旧数据
      await Character.deleteMany({});
      console.log('[Seed] 已清理 Character 集合');
      
      const rawData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
      
      // 转换字段格式
      const characters = rawData.map(item => ({
        character: item.character,
        unicode: item.unicode || generateUnicode(item.character),
        pinyin: item.pinyin,
        tone: item.tone,
        strokeCount: item.strokeCount,
        radical: item.radical,
        structure: item.structure,
        level: item.level,
        grade: item.grade,
        coreLevel: mapCoreLevel(item.coreLevel),
        frequency: item.frequency || 0,
        etymology: item.etymology || undefined,
        meanings: item.meanings || [],
        status: 'active'
      }));
      
      await Character.insertMany(characters);
      console.log(`[Seed] 已导入 ${characters.length} 个汉字 (来源: L1核心字50_后端导入.json)`);
    } else {
      console.log(`[Seed] 未找到汉字数据文件: ${jsonPath}`);
      console.log('[Seed] 使用内置示例数据...');
      
      await Character.deleteMany({});
      
      const fallbackChars = [
        { character: '一', unicode: 'U+4E00', pinyin: 'yī', tone: 1, strokeCount: 1, radical: '一', structure: '独体', level: 1, grade: 0, coreLevel: 'core', etymology: { type: '指事', story: '一横代表数字一' }, meanings: [{ wordClass: '数词', meaning: '数字一', examples: [{ word: '一个', sentence: '我有一个苹果' }] }] },
        { character: '二', unicode: 'U+4E8C', pinyin: 'èr', tone: 4, strokeCount: 2, radical: '二', structure: '独体', level: 1, grade: 0, coreLevel: 'core', etymology: { type: '指事', story: '两横代表数字二' }, meanings: [{ wordClass: '数词', meaning: '数字二', examples: [{ word: '两个', sentence: '我有两个好朋友' }] }] },
        { character: '三', unicode: 'U+4E09', pinyin: 'sān', tone: 1, strokeCount: 3, radical: '一', structure: '独体', level: 1, grade: 0, coreLevel: 'core', etymology: { type: '指事', story: '三横代表数字三' }, meanings: [{ wordClass: '数词', meaning: '数字三', examples: [{ word: '三个', sentence: '桌子上有三个杯子' }] }] },
        { character: '大', unicode: 'U+5927', pinyin: 'dà', tone: 4, strokeCount: 3, radical: '大', structure: '独体', level: 1, grade: 0, coreLevel: 'core', etymology: { type: '象形', story: '张开双臂的人形，表示很大' }, meanings: [{ wordClass: '形容词', meaning: '大的', examples: [{ word: '大人', sentence: '大人牵着小孩' }] }] },
        { character: '小', unicode: 'U+5C0F', pinyin: 'xiǎo', tone: 3, strokeCount: 3, radical: '小', structure: '独体', level: 1, grade: 0, coreLevel: 'core', etymology: { type: '象形', story: '三粒沙子，表示很小' }, meanings: [{ wordClass: '形容词', meaning: '小的', examples: [{ word: '小鸟', sentence: '树上有一只小鸟' }] }] }
      ];
      
      await Character.insertMany(fallbackChars);
      console.log(`[Seed] 已导入 ${fallbackChars.length} 个示例汉字`);
    }

    // ===== 开发环境：创建测试用户 =====
    if (config.sms.provider === 'mock') {
      const testPhone = '13800138000';
      let testUser = await User.findOne({ phone: testPhone });
      if (!testUser) {
        testUser = await User.create({
          phone: testPhone,
          nickname: '测试用户',
          avatar: 'https://cdn.ziqu.com/avatars/test.png',
          privacyAccepted: true,
          privacyAcceptedAt: new Date()
        });
        console.log(`[Seed] 创建测试用户: ${testPhone} (验证码: ${config.sms.mockCode})`);
      } else {
        console.log(`[Seed] 测试用户已存在: ${testPhone}`);
      }
    }

    console.log('[Seed] 种子数据导入完成!');
    process.exit(0);
  } catch (err) {
    console.error('[Seed] 导入失败:', err);
    process.exit(1);
  }
}

seed();
