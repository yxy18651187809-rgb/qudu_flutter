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
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
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
    const jsonPath = path.join(__dirname, '../../../01-内容/L1完整字300_后端导入.json');
    
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
      console.log(`[Seed] 已导入 ${characters.length} 个汉字 (来源: L1完整字300_后端导入.json, 含补入的"个"字共301字)`);
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

    // ===== 导入绘本数据 =====
    await Book.deleteMany({});
    await BookPage.deleteMany({});
    console.log('[Seed] 已清理 Book 和 BookPage 集合');

    // 查找L1汉字，用于关联
    const charMap = {};
    const allChars = await Character.find({}).lean();
    allChars.forEach(c => { charMap[c.character] = c._id; });

    // 绘本01《我的身体》— v2修正版15个新字（教研员2026-04-21修正）
    const book1NewWords = ['人', '口', '手', '足', '头', '耳', '心', '大', '小', '我', '你', '会', '是', '的', '了'];
    const book1ReviewWords = ['一', '二', '三', '上', '下', '天'];
    
    const book1 = await Book.create({
      title: '我的身体',
      cover: '',
      description: '认识身体、学会爱护自己',
      level: 1,
      theme: '身体认知',
      tags: ['身体', '认知', '自我'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book1NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book1NewWords.length,
      reviewWords: book1ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 100,
      estimatedMinutes: 5,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      exercises: [
        { type: 'image_match', question: '看看图片，选出正确的身体部位名称', instruction: '手的图片→手、头的图片→头、嘴巴的图片→口' },
        { type: 'size_compare', question: '看图选出"大"和"小"', instruction: '大西瓜→大、小蚂蚁→小' },
        { type: 'point_identify', question: '指指你的头在哪里？口在哪里？手在哪里？', instruction: '引导孩子认识身体部位' },
        { type: 'count', question: '数一数你有多少只手？多少只足？', instruction: '用图片辅助理解数量' },
        { type: 'emotion', question: '指着自己的心，说：我爱我自己！', instruction: '情感引导，不涉及识字考核' }
      ],
      isFree: true,
      price: 0,
      sortOrder: 1,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book1.title} (ID: ${book1._id})`);

    // 绘本01页面（基于教研员v2修正版文案）
    const book1Pages = [
      { pageNumber: 1, text: '我是小明。', pinyin: '[wǒ shì xiǎo míng]', imageDescription: '小主人公对着镜子，开心地指着自己', teachingNote: '认识"我"是自己的称呼，"小"表示可爱的意思', wordAnnotations: [{ character: '我', isNewWord: true }, { character: '小', isNewWord: false }] },
      { pageNumber: 2, text: '这是我的头。', pinyin: '[zhè shì wǒ de tóu]', imageDescription: '小明用手指着头，旁边有一个大大的箭头指向头部', teachingNote: '认识"头"在身体最上面', wordAnnotations: [{ character: '是', isNewWord: true }, { character: '的', isNewWord: true }, { character: '头', isNewWord: true }] },
      { pageNumber: 3, text: '我的人脸。大大的口。', pinyin: '[wǒ de rén liǎn] [dà dà de kǒu]', imageDescription: '小明用手指着脸（笑），旁边画一个笑脸图标', teachingNote: '认识脸上有嘴巴（口）', wordAnnotations: [{ character: '人', isNewWord: true }, { character: '口', isNewWord: true }, { character: '大', isNewWord: true }] },
      { pageNumber: 4, text: '我有两只眼。', pinyin: '[wǒ yǒu liǎng zhī yǎn]', imageDescription: '小明用手指着眼睛，旁边画一只大眼睛的特写图标', teachingNote: '眼睛用来看东西（图片辅助理解，不强制识字）', wordAnnotations: [] },
      { pageNumber: 5, text: '这是耳。', pinyin: '[zhè shì ěr]', imageDescription: '小明用手指着耳朵，旁边有一只小鸟的简笔画', teachingNote: '耳朵用来听声音', wordAnnotations: [{ character: '耳', isNewWord: true }] },
      { pageNumber: 6, text: '这是鼻。', pinyin: '[zhè shì bí]', imageDescription: '小明用手指着鼻子，旁边画一朵花', teachingNote: '鼻子用来闻东西（图片辅助认知，不强制识字）', wordAnnotations: [] },
      { pageNumber: 7, text: '口，大！小，小。', pinyin: '[kǒu dà] [xiǎo xiǎo]', imageDescription: '小明张大嘴巴，画面用大嘴巴特写，再闭嘴变小', teachingNote: '通过大小对比巩固"大""小"', wordAnnotations: [{ character: '小', isNewWord: true }] },
      { pageNumber: 8, text: '我有一双手。', pinyin: '[wǒ yǒu yī shuāng shǒu]', imageDescription: '小明伸出双手，十根手指张开，旁边有数字10的图标', teachingNote: '认识"手"，一双手有十根手指', wordAnnotations: [{ character: '手', isNewWord: true }] },
      { pageNumber: 9, text: '我有两只足。', pinyin: '[wǒ yǒu liǎng zhī zú]', imageDescription: '小明用手指着脚，旁边有一双小鞋子的图标', teachingNote: '认识"足"就是脚，用来走路', wordAnnotations: [{ character: '足', isNewWord: true }] },
      { pageNumber: 10, text: '我的心。我会长大。', pinyin: '[wǒ de xīn] [wǒ huì zhǎng dà]', imageDescription: '小明张开双臂拥抱自己，背景是温暖的阳光，画面充满安全感', teachingNote: '心代表爱和情感，"会"表示将来能做到', wordAnnotations: [{ character: '心', isNewWord: true }, { character: '会', isNewWord: true }, { character: '了', isNewWord: true }] }
    ];

    for (const page of book1Pages) {
      // 填充 characterId
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));

      await BookPage.create({
        bookId: book1._id,
        pageNumber: page.pageNumber,
        text: page.text,
        pinyin: page.pinyin,
        imageDescription: page.imageDescription,
        teachingNote: page.teachingNote,
        wordAnnotations: annotations,
        interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本01的 ${book1Pages.length} 个页面`);

    // 绘本02《早上好》
    const book2NewWords = ['日', '早', '上', '天', '明', '亮', '起', '洗', '吃', '出', '来', '去', '爸', '妈', '爷', '奶', '好', '刷', '太', '阳'];
    const book2ReviewWords = ['人', '口', '手', '大', '小', '我', '你', '心', '是', '的', '了', '会', '一', '二', '三'];
    
    const book2 = await Book.create({
      title: '早上好',
      cover: '',
      description: '早安时光，和绘本01的小明一起迎接新的一天',
      level: 1,
      theme: '日常作息',
      tags: ['日常', '早晨', '家庭'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book2NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book2NewWords.length,
      reviewWords: book2ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 150,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 2,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book2.title} (ID: ${book2._id})`);

    // 绘本02页面（基于教研员脚本的简化版本）
    const book2Pages = [
      { pageNumber: 1, text: '太阳出来了！', pinyin: '[tài yáng chū lái le]', imageDescription: '温暖的太阳从东边升起，金色的阳光洒满大地', wordAnnotations: [{ character: '太', isNewWord: true }, { character: '阳', isNewWord: true }, { character: '出', isNewWord: true }, { character: '来', isNewWord: true }, { character: '了', isNewWord: false }] },
      { pageNumber: 2, text: '早上好，太阳！', pinyin: '[zǎo shàng hǎo tài yáng]', imageDescription: '小明站在窗前，对着太阳说早安', wordAnnotations: [{ character: '早', isNewWord: true }, { character: '上', isNewWord: true }, { character: '好', isNewWord: true }] },
      { pageNumber: 3, text: '天亮了，我起来了。', pinyin: '[tiān liàng le wǒ qǐ lái le]', imageDescription: '小明从温暖的被窝里坐起来，阳光照在床上', wordAnnotations: [{ character: '天', isNewWord: true }, { character: '亮', isNewWord: true }, { character: '起', isNewWord: true }] },
      { pageNumber: 4, text: '我刷牙，洗脸。', pinyin: '[wǒ shuā yá xǐ liǎn]', imageDescription: '小明站在洗手台前，拿着牙刷刷牙', wordAnnotations: [{ character: '刷', isNewWord: true }, { character: '洗', isNewWord: true }] },
      { pageNumber: 5, text: '我吃早饭。', pinyin: '[wǒ chī zǎo fàn]', imageDescription: '小明坐在餐桌前吃早餐，桌上有牛奶和面包', wordAnnotations: [{ character: '吃', isNewWord: true }, { character: '早', isNewWord: false }] },
      { pageNumber: 6, text: '爸爸早上好！', pinyin: '[bà ba zǎo shàng hǎo]', imageDescription: '小明向爸爸挥手说早安，爸爸微笑回应', wordAnnotations: [{ character: '爸', isNewWord: true }] },
      { pageNumber: 7, text: '妈妈早上好！', pinyin: '[mā ma zǎo shàng hǎo]', imageDescription: '小明向妈妈挥手说早安，妈妈在厨房忙碌', wordAnnotations: [{ character: '妈', isNewWord: true }] },
      { pageNumber: 8, text: '爷爷好！奶奶好！', pinyin: '[yé ye hǎo nǎi nai hǎo]', imageDescription: '小明和爷爷奶奶在一起，开心地打招呼', wordAnnotations: [{ character: '爷', isNewWord: true }, { character: '奶', isNewWord: true }] },
      { pageNumber: 9, text: '我去上学了。', pinyin: '[wǒ qù shàng xué le]', imageDescription: '小明背着小书包，走出家门', wordAnnotations: [{ character: '去', isNewWord: true }] },
      { pageNumber: 10, text: '明天见！', pinyin: '[míng tiān jiàn]', imageDescription: '小明对着太阳挥手，夕阳下温暖的光影', wordAnnotations: [{ character: '明', isNewWord: true }] }
    ];

    for (const page of book2Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));

      await BookPage.create({
        bookId: book2._id,
        pageNumber: page.pageNumber,
        text: page.text,
        pinyin: page.pinyin,
        imageDescription: page.imageDescription,
        teachingNote: '',
        wordAnnotations: annotations,
        interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本02的 ${book2Pages.length} 个页面`);

    // 绘本03《小兔子找妈妈》— 20个新字
    const book3NewWords = ['兔', '山', '石', '木', '林', '花', '找', '不', '有', '在', '一', '二', '三', '问', '回', '开', '多', '少', '里', '爱'];
    const book3ReviewWords = ['我', '你', '大', '小', '的', '了', '去', '来'];
    
    const book3 = await Book.create({
      title: '小兔子找妈妈',
      cover: '',
      description: '小兔子白白找妈妈的故事，认识自然、感受母爱',
      level: 1,
      theme: '方位认知、母爱亲情、乐于助人',
      tags: ['动物', '亲情', '方位', '自然'],
      protagonist: {
        name: '白白',
        description: '小白兔，圆滚滚，长耳朵，眼睛大而明亮，表情丰富'
      },
      newWords: book3NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book3NewWords.length,
      reviewWords: book3ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 120,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      exercises: [
        { type: 'image_match', question: '看看图片，选出正确的汉字', instruction: '小兔子→兔、大山→山、大树→木、花朵→花' },
        { type: 'count', question: '数一数画面中有几只兔子？几朵花？几块石头？', instruction: '答案用图片数字辅助：一、二、三' },
        { type: 'find_match', question: '小兔子经过了哪些地方？请把汉字和图片连起来', instruction: '树林→林、山坡→山、花丛→花、小河→水' },
        { type: 'size_compare', question: '看图选出"大"和"小"', instruction: '大兔子→大、小兔子→小、大山→大、小花→小' },
        { type: 'emotion', question: '你爱谁？对你的妈妈说一句：妈妈，我爱你！', instruction: '情感引导，不涉及识字考核' }
      ],
      isFree: true,
      price: 0,
      sortOrder: 3,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book3.title} (ID: ${book3._id})`);

    // 绘本03页面（基于教研员v1文案）
    const book3Pages = [
      { pageNumber: 1, text: '一只小兔。兔子在林里。', pinyin: '[yī zhī xiǎo tù] [tù zi zài lín lǐ]', imageDescription: '清晨的树林里，小白兔白白一个人坐在大树旁边，低着头，看起来不太开心', teachingNote: '认识"兔"和"林"，一只小兔子在树林里', wordAnnotations: [{ character: '一', isNewWord: true }, { character: '兔', isNewWord: true }, { character: '在', isNewWord: true }, { character: '林', isNewWord: true }] },
      { pageNumber: 2, text: '兔子找妈妈。妈妈不在。', pinyin: '[tù zi zhǎo mā ma] [mā ma bù zài]', imageDescription: '白白站起来，四处张望，画面用大大的问号和眼睛特写表现它在找东西', teachingNote: '认识"找"是寻找的动作，"不"表示否定', wordAnnotations: [{ character: '找', isNewWord: true }, { character: '不', isNewWord: true }] },
      { pageNumber: 3, text: '兔子上了山。有多少石头？一、二、三……', pinyin: '[tù zi shàng le shān] [yǒu duō shǎo shí tou] [yī èr sān]', imageDescription: '白白跑到小山坡上，山顶有好多大石头，白白问石头', teachingNote: '认识"山"和"石"，学习数数"一、二、三"，"多少"表示询问数量', wordAnnotations: [{ character: '山', isNewWord: true }, { character: '有', isNewWord: true }, { character: '多', isNewWord: true }, { character: '少', isNewWord: true }, { character: '石', isNewWord: true }, { character: '二', isNewWord: true }, { character: '三', isNewWord: true }] },
      { pageNumber: 4, text: '问小鸟：你有看到妈妈吗？', pinyin: '[wèn xiǎo niǎo] [nǐ yǒu kàn dào mā ma ma]', imageDescription: '白白来到一棵大树前，树上开满了花，白白仰着头问小鸟', teachingNote: '认识"问"是提问的动作，学会用"你有……吗"提问', wordAnnotations: [{ character: '问', isNewWord: true }] },
      { pageNumber: 5, text: '花开了。花有多有少。', pinyin: '[huā kāi le] [huā yǒu duō yǒu shǎo]', imageDescription: '小鸟摇摇头飞走了，白白继续走，来到一片花丛中，有红色的花和黄色的花', teachingNote: '认识"花"，巩固"多少"的概念，感受大自然的美', wordAnnotations: [{ character: '花', isNewWord: true }, { character: '开', isNewWord: true }] },
      { pageNumber: 6, text: '木桥。水里有鱼。', pinyin: '[mù qiáo] [shuǐ lǐ yǒu yú]', imageDescription: '白白走过一座小木桥，桥下是小河，河里有小鱼，白白对着水里的小鱼说话', teachingNote: '认识"木"就是木头，木头可以造桥', wordAnnotations: [{ character: '木', isNewWord: true }] },
      { pageNumber: 7, text: '里面是家。妈妈在家里。', pinyin: '[lǐ miàn shì jiā] [mā ma zài jiā lǐ]', imageDescription: '天渐渐暗了，白白坐在大树下，抱住自己的长耳朵，远处的树林深处有一个温暖的光', teachingNote: '认识"里"表示在某个空间里面，感受"家"的安全感', wordAnnotations: [{ character: '里', isNewWord: true }] },
      { pageNumber: 8, text: '妈妈！回来了！', pinyin: '[mā ma] [huí lái le]', imageDescription: '白白看到远处的光，开心地跑过去，大大的感叹号表现惊喜', teachingNote: '认识"回"表示回来、返回', wordAnnotations: [{ character: '回', isNewWord: true }] },
      { pageNumber: 9, text: '妈妈爱兔子。大兔子，小兔子。', pinyin: '[mā ma ài tù zi] [dà tù zi xiǎo tù zi]', imageDescription: '兔妈妈抱着白白，旁边有小兔子兄弟，画面温馨，小女孩小明站在远处微笑着看', teachingNote: '认识"爱"，巩固"大""小"对比，感受母爱', wordAnnotations: [{ character: '爱', isNewWord: true }] },
      { pageNumber: 10, text: '回家了。我爱妈妈。妈妈也爱我。', pinyin: '[huí jiā le] [wǒ ài mā ma] [mā ma yě ài wǒ]', imageDescription: '白白和妈妈一起走在回家的路上，经过花丛、大树、小河，天空中月亮出来了', teachingNote: '总结故事，传递"爱是相互的"温暖情感', wordAnnotations: [] }
    ];

    for (const page of book3Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));

      await BookPage.create({
        bookId: book3._id,
        pageNumber: page.pageNumber,
        text: page.text,
        pinyin: page.pinyin,
        imageDescription: page.imageDescription,
        teachingNote: page.teachingNote,
        wordAnnotations: annotations,
        interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本03的 ${book3Pages.length} 个页面`);

    // ===== 绘本04《一二三上学去》— v2修正版15个新字 =====
    const book4NewWords = ['一', '二', '三', '四', '五', '上', '学', '校', '友', '师', '看', '你', '好', '人', '坐'];
    const book4ReviewWords = ['口', '手', '头', '日', '早', '天', '来', '去', '大', '小', '我', '是', '的', '了', '会'];
    
    const book4 = await Book.create({
      title: '一二三上学去',
      cover: '',
      description: '数字认知、学校期待、友谊',
      level: 1,
      theme: '数字认知',
      tags: ['数字', '学校', '友谊', '礼貌'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book4NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book4NewWords.length,
      reviewWords: book4ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 140,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      exercises: [
        { type: 'number_match', question: '看到数字卡，说出对应的汉字', instruction: '1→一 2→二 3→三 4→四 5→五' },
        { type: 'count', question: '数一数图片里有几个物品？', instruction: '用1-5回答' },
        { type: 'image_match', question: '把场景和正确的礼貌用语连起来', instruction: '见到老师→你好/老师好 告别→明天见' },
        { type: 'story_retell', question: '看图说一说：小明在学校里做了什么？', instruction: '引导孩子复述故事' },
        { type: 'role_play', question: '和爸爸妈妈一起表演上学的故事', instruction: '情感引导，不涉及识字考核' }
      ],
      isFree: true,
      price: 0,
      sortOrder: 4,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book4.title} (ID: ${book4._id})`);

    const book4Pages = [
      { pageNumber: 1, text: '一、二、三——小明上学去。', pinyin: '[yī èr sān xiǎo míng shàng xué qù]', imageDescription: '小明背着书包，在家门口数手指', teachingNote: '认识数字1-3，学习"上学"', wordAnnotations: [{ character: '一', isNewWord: true }, { character: '二', isNewWord: true }, { character: '三', isNewWord: true }, { character: '上', isNewWord: true }] },
      { pageNumber: 2, text: '四只小鸟。一、二、三、四——', pinyin: '[sì zhī xiǎo niǎo] [yī èr sān sì]', imageDescription: '小明在路上蹦蹦跳跳，路边的树上有4只小鸟', teachingNote: '认识数字4，复习1-4', wordAnnotations: [{ character: '四', isNewWord: true }] },
      { pageNumber: 3, text: '小明到学校了。学校真大！', pinyin: '[xiǎo míng dào xué xiào le] [xué xiào zhēn dà]', imageDescription: '小明到了学校门口，看到"学校"两个大字', teachingNote: '认识"学校"', wordAnnotations: [{ character: '学', isNewWord: true }, { character: '校', isNewWord: true }] },
      { pageNumber: 4, text: '小明看到新人。"你好！""你好！"', pinyin: '[xiǎo míng kàn dào xīn rén] [nǐ hǎo]', imageDescription: '小明遇到一个新同学，两人互相打招呼', teachingNote: '学习用"你好"问候新朋友', wordAnnotations: [{ character: '看', isNewWord: true }, { character: '人', isNewWord: true }, { character: '你', isNewWord: true }] },
      { pageNumber: 5, text: '小明看到老师。"老师好！"', pinyin: '[xiǎo míng kàn dào lǎo shī] [lǎo shī hǎo]', imageDescription: '小明和新朋友一起走进教室，看到老师', teachingNote: '学习向老师问好', wordAnnotations: [{ character: '师', isNewWord: true }, { character: '好', isNewWord: true }] },
      { pageNumber: 6, text: '小明坐好了。朋友也坐好了。"我们是好朋友！"', pinyin: '[xiǎo míng zuò hǎo le] [wǒ men shì hǎo péng you]', imageDescription: '小明和新朋友在教室里找座位坐好', teachingNote: '"好朋友"是友谊的表达', wordAnnotations: [{ character: '坐', isNewWord: true }, { character: '友', isNewWord: true }] },
      { pageNumber: 7, text: '五个苹果。一、二、三、四、五——', pinyin: '[wǔ gè píng guǒ] [yī èr sān sì wǔ]', imageDescription: '课堂上，老师拿出5个苹果教具让同学们数', teachingNote: '认识数字5，完成1-5数字认知', wordAnnotations: [{ character: '五', isNewWord: true }] },
      { pageNumber: 8, text: '小明举手。"老师，我想去洗手间。"', pinyin: '[xiǎo míng jǔ shǒu] [lǎo shī wǒ xiǎng qù xǐ shǒu jiān]', imageDescription: '下课了，小明向老师举手示意', teachingNote: '学习在课堂上举手表达需求', wordAnnotations: [] },
      { pageNumber: 9, text: '放学了。"明天见！""老师好！同学好！"', pinyin: '[fàng xué le] [míng tiān jiàn] [lǎo shī hǎo tóng xué hǎo]', imageDescription: '放学了，小明和新朋友在校门口挥手告别', teachingNote: '学习告别和问候', wordAnnotations: [] },
      { pageNumber: 10, text: '一、二、三、四、五——我学会数数了！老师好！朋友好！明天还要上学！', pinyin: '[yī èr sān sì wǔ] [wǒ xué huì shǔ shù le]', imageDescription: '小明走在回家的路上，夕阳很美，脸上是开心的笑容', teachingNote: '总结一天的收获，期待明天', wordAnnotations: [] }
    ];

    for (const page of book4Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book4._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本04的 ${book4Pages.length} 个页面`);

    // ===== 绘本05《红红的太阳》— v2修正版17个新字 =====
    const book5NewWords = ['红', '黄', '蓝', '绿', '白', '黑', '光', '亮', '天', '云', '雨', '风', '雪', '星', '月', '看', '有'];
    const book5ReviewWords = ['人', '口', '手', '大', '小', '我', '你', '是', '的', '了', '一', '二', '三', '上', '好'];
    
    const book5 = await Book.create({
      title: '红红的太阳',
      cover: '',
      description: '颜色认知、自然观察、创造力',
      level: 1,
      theme: '颜色认知',
      tags: ['颜色', '自然', '天气', '创造'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book5NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book5NewWords.length,
      reviewWords: book5ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 120,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 5,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book5.title} (ID: ${book5._id})`);

    const book5Pages = [
      { pageNumber: 1, text: '天亮了。太阳出来了。', pinyin: '[tiān liàng le] [tài yáng chū lái le]', imageDescription: '温暖的太阳升起，金色阳光洒满大地', teachingNote: '认识"天"和"亮"', wordAnnotations: [{ character: '天', isNewWord: true }, { character: '亮', isNewWord: true }] },
      { pageNumber: 2, text: '红红的太阳。红，真好看。', pinyin: '[hóng hóng de tài yáng] [hóng zhēn hǎo kàn]', imageDescription: '红红的太阳高挂天空，小明抬头看', teachingNote: '认识"红"是颜色', wordAnnotations: [{ character: '红', isNewWord: true }] },
      { pageNumber: 3, text: '白天有云。云是白的。', pinyin: '[bái tiān yǒu yún] [yún shì bái de]', imageDescription: '蓝天白云，小明看着白色的云朵', teachingNote: '认识"白"和"云"', wordAnnotations: [{ character: '白', isNewWord: true }, { character: '云', isNewWord: true }, { character: '有', isNewWord: true }] },
      { pageNumber: 4, text: '风来了。风真大。', pinyin: '[fēng lái le] [fēng zhēn dà]', imageDescription: '风吹动树叶和小明的辫子', teachingNote: '认识"风"是自然现象', wordAnnotations: [{ character: '风', isNewWord: true }] },
      { pageNumber: 5, text: '下雨了。天黑了。', pinyin: '[xià yǔ le] [tiān hēi le]', imageDescription: '下雨了，天空变暗', teachingNote: '认识"雨"和"黑"', wordAnnotations: [{ character: '雨', isNewWord: true }, { character: '黑', isNewWord: true }] },
      { pageNumber: 6, text: '黄黄的雨衣。蓝蓝的天。', pinyin: '[huáng huáng de yǔ yī] [lán lán de tiān]', imageDescription: '小明穿着黄色雨衣，雨后天空变蓝', teachingNote: '认识"黄"和"蓝"', wordAnnotations: [{ character: '黄', isNewWord: true }, { character: '蓝', isNewWord: true }] },
      { pageNumber: 7, text: '绿色的草。绿，真好看。', pinyin: '[lǜ sè de cǎo] [lǜ zhēn hǎo kàn]', imageDescription: '雨后绿色的草地，小明开心地踩水', teachingNote: '认识"绿"', wordAnnotations: [{ character: '绿', isNewWord: true }] },
      { pageNumber: 8, text: '太阳又出来了。光真好。', pinyin: '[tài yáng yòu chū lái le] [guāng zhēn hǎo]', imageDescription: '太阳再次出来，阳光温暖', teachingNote: '认识"光"', wordAnnotations: [{ character: '光', isNewWord: true }, { character: '看', isNewWord: true }] },
      { pageNumber: 9, text: '晚上有星星和月亮。', pinyin: '[wǎn shàng yǒu xīng xing hé yuè liang]', imageDescription: '夜空中有星星和弯弯的月亮', teachingNote: '认识"星"和"月"', wordAnnotations: [{ character: '星', isNewWord: true }, { character: '月', isNewWord: true }] },
      { pageNumber: 10, text: '红黄蓝绿白黑——我看到好多颜色！', pinyin: '[hóng huáng lán lǜ bái hēi] [wǒ kàn dào hǎo duō yán sè]', imageDescription: '彩虹出现，小明开心地看着', teachingNote: '总结6种颜色，回顾全文', wordAnnotations: [] }
    ];

    for (const page of book5Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book5._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本05的 ${book5Pages.length} 个页面`);

    // ===== 绘本06《好吃的果子》— v1修正版18个新字 =====
    const book6NewWords = ['果', '米', '菜', '瓜', '桃', '茶', '糖', '豆', '蛋', '面', '吃', '水', '肉', '多', '少', '两', '分', '唱'];
    const book6ReviewWords = ['人', '大', '小', '我', '你', '好', '的', '了', '一', '二', '三', '上', '下', '天'];
    
    const book6 = await Book.create({
      title: '好吃的果子',
      cover: '',
      description: '食物认知、水果名称、分享快乐',
      level: 1,
      theme: '食物认知',
      tags: ['食物', '水果', '分享', '数量'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book6NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book6NewWords.length,
      reviewWords: book6ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 130,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 6,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book6.title} (ID: ${book6._id})`);

    const book6Pages = [
      { pageNumber: 1, text: '好多果子！红的、黄的、绿的。', pinyin: '[hǎo duō guǒ zi] [hóng de huáng de lǜ de]', imageDescription: '桌上摆满了各种水果，红的黄的绿的', teachingNote: '认识"果"是水果的总称', wordAnnotations: [{ character: '果', isNewWord: true }, { character: '多', isNewWord: true }] },
      { pageNumber: 2, text: '大西瓜！小桃子。', pinyin: '[dà xī guā] [xiǎo táo zi]', imageDescription: '大西瓜旁边放着一个桃子', teachingNote: '认识"瓜"和"桃"，大小对比', wordAnnotations: [{ character: '瓜', isNewWord: true }, { character: '桃', isNewWord: true }] },
      { pageNumber: 3, text: '米和菜。米饭好吃！', pinyin: '[mǐ hé cài] [mǐ fàn hǎo chī]', imageDescription: '一碗白米饭和一盘青菜', teachingNote: '认识"米"和"菜"', wordAnnotations: [{ character: '米', isNewWord: true }, { character: '菜', isNewWord: true }, { character: '吃', isNewWord: true }] },
      { pageNumber: 4, text: '喝点水。茶也好好水。', pinyin: '[hē diǎn shuǐ] [chá yě hǎo]', imageDescription: '一杯清茶和一杯水', teachingNote: '认识"水"和"茶"', wordAnnotations: [{ character: '水', isNewWord: true }, { character: '茶', isNewWord: true }] },
      { pageNumber: 5, text: '糖真多！红的糖，黄的糖。', pinyin: '[táng zhēn duō] [hóng de táng huáng de táng]', imageDescription: '五颜六色的糖果', teachingNote: '认识"糖"，巩固"多"', wordAnnotations: [{ character: '糖', isNewWord: true }] },
      { pageNumber: 6, text: '豆子，一颗一颗。', pinyin: '[dòu zi yī kē yī kē]', imageDescription: '一碗豆子，旁边数着一颗一颗', teachingNote: '认识"豆"', wordAnnotations: [{ character: '豆', isNewWord: true }] },
      { pageNumber: 7, text: '蛋！一个蛋。两个蛋。', pinyin: '[dàn] [yī gè dàn] [liǎng gè dàn]', imageDescription: '篮子里放着鸡蛋', teachingNote: '认识"蛋"和"两"', wordAnnotations: [{ character: '蛋', isNewWord: true }, { character: '两', isNewWord: true }] },
      { pageNumber: 8, text: '面条长长的。肉也好吃。', pinyin: '[miàn tiáo cháng cháng de] [ròu yě hǎo chī]', imageDescription: '一碗面条和一盘肉', teachingNote: '认识"面"和"肉"', wordAnnotations: [{ character: '面', isNewWord: true }, { character: '肉', isNewWord: true }] },
      { pageNumber: 9, text: '果子少了一半。分给你一半！', pinyin: '[guǒ zi shǎo le yī bàn] [fēn gěi nǐ yī bàn]', imageDescription: '小明把果子分成两半，给朋友一半', teachingNote: '认识"少"和"分"，学会分享', wordAnnotations: [{ character: '少', isNewWord: true }, { character: '分', isNewWord: true }] },
      { pageNumber: 10, text: '一起唱！好吃好吃真好吃！', pinyin: '[yī qǐ chàng] [hǎo chī hǎo chī zhēn hǎo chī]', imageDescription: '小明和朋友们一起唱歌庆祝', teachingNote: '认识"唱"，分享的快乐', wordAnnotations: [{ character: '唱', isNewWord: true }] }
    ];

    for (const page of book6Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book6._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本06的 ${book6Pages.length} 个页面`);

    // ===== 绘本07《家的小动物》— 18个新字 =====
    const book7NewWords = ['牛', '马', '羊', '猪', '狗', '猫', '鸡', '鸭', '鱼', '鸟', '虫', '跑', '飞', '游', '爬', '快', '慢', '笑'];
    const book7ReviewWords = ['人', '大', '小', '我', '你', '好', '的', '了', '是', '在', '有', '不', '上', '下', '来', '去'];
    
    const book7 = await Book.create({
      title: '家的小动物',
      cover: '',
      description: '动物认知、特征观察、生活常识',
      level: 1,
      theme: '动物认知',
      tags: ['动物', '特征', '动作', '农场'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book7NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book7NewWords.length,
      reviewWords: book7ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 130,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 7,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book7.title} (ID: ${book7._id})`);

    const book7Pages = [
      { pageNumber: 1, text: '大牛跑得慢。牛，慢——', pinyin: '[dà niú pǎo de màn] [niú màn]', imageDescription: '一头大牛在草地上慢悠悠地走', teachingNote: '认识"牛"和"跑""慢"', wordAnnotations: [{ character: '牛', isNewWord: true }, { character: '跑', isNewWord: true }, { character: '慢', isNewWord: true }] },
      { pageNumber: 2, text: '小马跑得快！马，快——', pinyin: '[xiǎo mǎ pǎo de kuài] [mǎ kuài]', imageDescription: '一匹小马在奔跑，速度很快', teachingNote: '认识"马"和"快"，与"慢"对比', wordAnnotations: [{ character: '马', isNewWord: true }, { character: '快', isNewWord: true }] },
      { pageNumber: 3, text: '羊在山上。白白的羊。', pinyin: '[yáng zài shān shàng] [bái bái de yáng]', imageDescription: '白色的羊在绿色的山坡上吃草', teachingNote: '认识"羊"', wordAnnotations: [{ character: '羊', isNewWord: true }] },
      { pageNumber: 4, text: '猪在泥里。猪好开心！', pinyin: '[zhū zài ní lǐ] [zhū hǎo kāi xīn]', imageDescription: '小猪在泥巴里打滚，很开心', teachingNote: '认识"猪"', wordAnnotations: [{ character: '猪', isNewWord: true }] },
      { pageNumber: 5, text: '小狗跑来了。狗是好朋友。', pinyin: '[xiǎo gǒu pǎo lái le] [gǒu shì hǎo péng you]', imageDescription: '小狗跑向小明，摇尾巴', teachingNote: '认识"狗"', wordAnnotations: [{ character: '狗', isNewWord: true }] },
      { pageNumber: 6, text: '小猫不跑，猫在睡觉。', pinyin: '[xiǎo māo bù pǎo] [māo zài shuì jiào]', imageDescription: '小猫蜷成一团在睡觉', teachingNote: '认识"猫"', wordAnnotations: [{ character: '猫', isNewWord: true }] },
      { pageNumber: 7, text: '鸡会飞不高。鸡在地上。', pinyin: '[jī huì fēi bù gāo] [jī zài dì shàng]', imageDescription: '一只鸡扇着翅膀，飞不高', teachingNote: '认识"鸡"和"飞"', wordAnnotations: [{ character: '鸡', isNewWord: true }, { character: '飞', isNewWord: true }] },
      { pageNumber: 8, text: '鸭子在水里游。鸭游得快！', pinyin: '[yā zi zài shuǐ lǐ yóu] [yā yóu de kuài]', imageDescription: '鸭子在水里自由自在地游', teachingNote: '认识"鸭"和"游"', wordAnnotations: [{ character: '鸭', isNewWord: true }, { character: '游', isNewWord: true }] },
      { pageNumber: 9, text: '鱼也在水里游。小鱼好快！', pinyin: '[yú yě zài shuǐ lǐ yóu] [xiǎo yú hǎo kuài]', imageDescription: '小鱼在水里快速游动', teachingNote: '认识"鱼"', wordAnnotations: [{ character: '鱼', isNewWord: true }] },
      { pageNumber: 10, text: '鸟在天上飞。虫在树上爬。大家都在笑！', pinyin: '[niǎo zài tiān shàng fēi] [chóng zài shù shàng pá] [dà jiā dōu zài xiào]', imageDescription: '鸟在天上飞，虫子在树上爬，小明看着大家笑', teachingNote: '认识"鸟""虫""爬""笑"', wordAnnotations: [{ character: '鸟', isNewWord: true }, { character: '虫', isNewWord: true }, { character: '爬', isNewWord: true }, { character: '笑', isNewWord: true }] }
    ];

    for (const page of book7Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book7._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本07的 ${book7Pages.length} 个页面`);

    // ===== 绘本08《四季歌》— 18个新字 =====
    const book8NewWords = ['春', '秋', '冬', '冰', '气', '沙', '河', '泉', '洞', '浇', '湿', '种', '树', '草', '年', '先', '长', '土'];
    const book8ReviewWords = ['人', '大', '小', '我', '你', '好', '的', '了', '是', '在', '有', '不', '上', '下', '来', '去', '天', '风', '雨'];
    
    const book8 = await Book.create({
      title: '四季歌',
      cover: '',
      description: '季节认知、自然变化、感受四季',
      level: 1,
      theme: '季节认知',
      tags: ['季节', '自然', '天气', '植物'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book8NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book8NewWords.length,
      reviewWords: book8ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 130,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 8,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book8.title} (ID: ${book8._id})`);

    const book8Pages = [
      { pageNumber: 1, text: '春天来了。气暖暖的。', pinyin: '[chūn tiān lái le] [qì nuǎn nuǎn de]', imageDescription: '春天来了，小草发芽，阳光温暖', teachingNote: '认识"春"和"气"', wordAnnotations: [{ character: '春', isNewWord: true }, { character: '气', isNewWord: true }] },
      { pageNumber: 2, text: '先种树。树会长高。', pinyin: '[xiān zhòng shù] [shù huì zhǎng gāo]', imageDescription: '小明在春天种下一棵小树苗', teachingNote: '认识"先""种""树""长"', wordAnnotations: [{ character: '先', isNewWord: true }, { character: '种', isNewWord: true }, { character: '树', isNewWord: true }, { character: '长', isNewWord: true }] },
      { pageNumber: 3, text: '草长出来了。浇浇水。', pinyin: '[cǎo zhǎng chū lái le] [jiāo jiāo shuǐ]', imageDescription: '小明给小草浇水', teachingNote: '认识"草"和"浇"', wordAnnotations: [{ character: '草', isNewWord: true }, { character: '浇', isNewWord: true }] },
      { pageNumber: 4, text: '土湿了。泉水在土里。', pinyin: '[tǔ shī le] [quán shuǐ zài tǔ lǐ]', imageDescription: '土地被水浇湿了，地下水在流动', teachingNote: '认识"土""湿""泉"', wordAnnotations: [{ character: '土', isNewWord: true }, { character: '湿', isNewWord: true }, { character: '泉', isNewWord: true }] },
      { pageNumber: 5, text: '河里有水。沙子在河边。', pinyin: '[hé lǐ yǒu shuǐ] [shā zi zài hé biān]', imageDescription: '清澈的河水流过，河岸边有沙子', teachingNote: '认识"河"和"沙"', wordAnnotations: [{ character: '河', isNewWord: true }, { character: '沙', isNewWord: true }] },
      { pageNumber: 6, text: '秋来了。叶变黄了。', pinyin: '[qiū lái le] [yè biàn huáng le]', imageDescription: '秋天的树叶变黄飘落', teachingNote: '认识"秋"', wordAnnotations: [{ character: '秋', isNewWord: true }] },
      { pageNumber: 7, text: '大雁飞走了。天气变冷了。', pinyin: '[dà yàn fēi zǒu le] [tiān qì biàn lěng le]', imageDescription: '大雁排队飞走，天气变冷', teachingNote: '复习"气"', wordAnnotations: [] },
      { pageNumber: 8, text: '冬来了。下雪了。冰好冷！', pinyin: '[dōng lái le] [xià xuě le] [bīng hǎo lěng]', imageDescription: '冬天来了，结冰了', teachingNote: '认识"冬"和"冰"', wordAnnotations: [{ character: '冬', isNewWord: true }, { character: '冰', isNewWord: true }] },
      { pageNumber: 9, text: '小动物在洞里。好暖和。', pinyin: '[xiǎo dòng wù zài dòng lǐ] [hǎo nuǎn huo]', imageDescription: '小动物在洞穴里冬眠，温暖安全', teachingNote: '认识"洞"', wordAnnotations: [{ character: '洞', isNewWord: true }] },
      { pageNumber: 10, text: '一年有四季。春夏秋冬，年年有好日子！', pinyin: '[yī nián yǒu sì jì] [chūn xià qiū dōng] [nián nián yǒu hǎo rì zi]', imageDescription: '四季轮转的美丽画面', teachingNote: '认识"年"，总结四季', wordAnnotations: [{ character: '年', isNewWord: true }] }
    ];

    for (const page of book8Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book8._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本08的 ${book8Pages.length} 个页面`);

    // ===== 绘本09《小明的家》— 18个新字 =====
    const book9NewWords = ['爸', '妈', '爷', '奶', '哥', '弟', '叔', '男', '女', '老', '安', '家', '字', '故', '事', '衣', '桌', '椅'];
    const book9ReviewWords = ['人', '大', '小', '我', '你', '好', '的', '了', '是', '在', '有', '不', '来', '去', '一', '二', '三', '上'];
    
    const book9 = await Book.create({
      title: '小明的家',
      cover: '',
      description: '家庭成员、亲情表达、家居物品',
      level: 1,
      theme: '家庭成员',
      tags: ['家庭', '亲情', '称谓', '家居'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book9NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book9NewWords.length,
      reviewWords: book9ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 130,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 9,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book9.title} (ID: ${book9._id})`);

    const book9Pages = [
      { pageNumber: 1, text: '这是我的家。家好大！', pinyin: '[zhè shì wǒ de jiā] [jiā hǎo dà]', imageDescription: '小明站在家门口，开心地指着自己的家', teachingNote: '认识"家"', wordAnnotations: [{ character: '家', isNewWord: true }] },
      { pageNumber: 2, text: '爸是男的。妈是女的。', pinyin: '[bà shì nán de] [mā shì nǚ de]', imageDescription: '爸爸和妈妈站在客厅', teachingNote: '认识"爸""妈""男""女"', wordAnnotations: [{ character: '爸', isNewWord: true }, { character: '妈', isNewWord: true }, { character: '男', isNewWord: true }, { character: '女', isNewWord: true }] },
      { pageNumber: 3, text: '爷爷是老人。爷爷好！', pinyin: '[yé ye shì lǎo rén] [yé ye hǎo]', imageDescription: '爷爷坐在椅子上，小明给他捶背', teachingNote: '认识"爷"和"老"', wordAnnotations: [{ character: '爷', isNewWord: true }, { character: '老', isNewWord: true }] },
      { pageNumber: 4, text: '奶奶也是老人。奶奶好！', pinyin: '[nǎi nai yě shì lǎo rén] [nǎi nai hǎo]', imageDescription: '奶奶在织毛衣，小明在旁边', teachingNote: '认识"奶"', wordAnnotations: [{ character: '奶', isNewWord: true }] },
      { pageNumber: 5, text: '哥哥是男的。弟弟是男的。', pinyin: '[gē ge shì nán de] [dì di shì nán de]', imageDescription: '哥哥和弟弟在玩球', teachingNote: '认识"哥"和"弟"', wordAnnotations: [{ character: '哥', isNewWord: true }, { character: '弟', isNewWord: true }] },
      { pageNumber: 6, text: '叔叔来了。叔叔也是男的。', pinyin: '[shū shu lái le] [shū shu yě shì nán de]', imageDescription: '叔叔来家里做客，小明迎接', teachingNote: '认识"叔"', wordAnnotations: [{ character: '叔', isNewWord: true }] },
      { pageNumber: 7, text: '桌上好多菜。椅子也好多。', pinyin: '[zhuō shàng hǎo duō cài] [yǐ zi yě hǎo duō]', imageDescription: '餐桌上摆满了菜，很多椅子', teachingNote: '认识"桌"和"椅"', wordAnnotations: [{ character: '桌', isNewWord: true }, { character: '椅', isNewWord: true }] },
      { pageNumber: 8, text: '我穿新衣。衣上有一个字。', pinyin: '[wǒ chuān xīn yī] [yī shàng yǒu yī gè zì]', imageDescription: '小明穿着新衣服，上面有个字', teachingNote: '认识"衣"和"字"', wordAnnotations: [{ character: '衣', isNewWord: true }, { character: '字', isNewWord: true }] },
      { pageNumber: 9, text: '爸爸讲故事。故事真有趣！', pinyin: '[bà ba jiǎng gù shì] [gù shì zhēn yǒu qù]', imageDescription: '爸爸在给小明讲故事', teachingNote: '认识"故"和"事"', wordAnnotations: [{ character: '故', isNewWord: true }, { character: '事', isNewWord: true }] },
      { pageNumber: 10, text: '家好安。我爱我的家！', pinyin: '[jiā hǎo ān] [wǒ ài wǒ de jiā]', imageDescription: '全家人在客厅，温馨幸福的画面', teachingNote: '认识"安"，家的温暖', wordAnnotations: [{ character: '安', isNewWord: true }] }
    ];

    for (const page of book9Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book9._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本09的 ${book9Pages.length} 个页面`);

    // ===== 绘本10《去公园玩》— 18个新字 =====
    const book10NewWords = ['车', '远', '方', '左', '前', '外', '东', '西', '北', '海', '画', '说', '读', '纸', '笔', '站', '想', '拿'];
    const book10ReviewWords = ['人', '大', '小', '我', '你', '好', '的', '了', '是', '在', '有', '不', '来', '去', '一', '二', '三', '上', '看', '水'];
    
    const book10 = await Book.create({
      title: '去公园玩',
      cover: '',
      description: '方向认知、户外探索、创意表达',
      level: 1,
      theme: '方向认知',
      tags: ['方向', '户外', '公园', '交通', '创意'],
      protagonist: {
        name: '小明',
        description: '小女孩，扎两个小辫子，亚洲面孔，活泼可爱'
      },
      newWords: book10NewWords.map(c => charMap[c]).filter(Boolean),
      newWordCount: book10NewWords.length,
      reviewWords: book10ReviewWords.map(c => charMap[c]).filter(Boolean),
      pageCount: 10,
      totalCharacters: 130,
      estimatedMinutes: 6,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      isFree: true,
      price: 0,
      sortOrder: 10,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book10.title} (ID: ${book10._id})`);

    const book10Pages = [
      { pageNumber: 1, text: '今天去公园！坐车去。', pinyin: '[jīn tiān qù gōng yuán] [zuò chē qù]', imageDescription: '小明站在公交车站等车，要去公园', teachingNote: '认识"车"', wordAnnotations: [{ character: '车', isNewWord: true }] },
      { pageNumber: 2, text: '车站在前面。站上好多人。', pinyin: '[chē zhàn zài qián miàn] [zhàn shàng hǎo duō rén]', imageDescription: '公交车站很多人在等车', teachingNote: '认识"站"和"前"', wordAnnotations: [{ character: '站', isNewWord: true }, { character: '前', isNewWord: true }] },
      { pageNumber: 3, text: '前方左转。左边有树。', pinyin: '[qián fāng zuǒ zhuǎn] [zuǒ biān yǒu shù]', imageDescription: '走到路口左转，左边是大树', teachingNote: '认识"方"和"左"', wordAnnotations: [{ character: '方', isNewWord: true }, { character: '左', isNewWord: true }] },
      { pageNumber: 4, text: '公园在外面。外面好大！', pinyin: '[gōng yuán zài wài miàn] [wài miàn hǎo dà]', imageDescription: '到了公园外面，公园很大', teachingNote: '认识"外"', wordAnnotations: [{ character: '外', isNewWord: true }] },
      { pageNumber: 5, text: '东边是太阳。西边有山。', pinyin: '[dōng biān shì tài yáng] [xī biān yǒu shān]', imageDescription: '东边太阳升起，西边有山', teachingNote: '认识"东"和"西"', wordAnnotations: [{ character: '东', isNewWord: true }, { character: '西', isNewWord: true }] },
      { pageNumber: 6, text: '北边好远。远处有大海。', pinyin: '[běi biān hǎo yuǎn] [yuǎn chù yǒu dà hǎi]', imageDescription: '北方远处有大海', teachingNote: '认识"北""远""海"', wordAnnotations: [{ character: '北', isNewWord: true }, { character: '远', isNewWord: true }, { character: '海', isNewWord: true }] },
      { pageNumber: 7, text: '我拿纸和笔。画一幅画！', pinyin: '[wǒ ná zhǐ hé bǐ] [huà yī fú huà]', imageDescription: '小明拿出纸和笔画画', teachingNote: '认识"拿""纸""笔""画"', wordAnnotations: [{ character: '拿', isNewWord: true }, { character: '纸', isNewWord: true }, { character: '笔', isNewWord: true }, { character: '画', isNewWord: true }] },
      { pageNumber: 8, text: '我画了太阳和花。说说你的画。', pinyin: '[wǒ huà le tài yáng hé huā] [shuō shuō nǐ de huà]', imageDescription: '小明画了太阳和花，和小伙伴分享', teachingNote: '认识"说"', wordAnnotations: [{ character: '说', isNewWord: true }] },
      { pageNumber: 9, text: '我还想读书。书里有好多字。', pinyin: '[wǒ hái xiǎng dú shū] [shū lǐ yǒu hǎo duō zì]', imageDescription: '小明在公园长椅上读书', teachingNote: '认识"想"和"读"', wordAnnotations: [{ character: '想', isNewWord: true }, { character: '读', isNewWord: true }] },
      { pageNumber: 10, text: '公园真好玩！东西南北，我都知道！', pinyin: '[gōng yuán zhēn hǎo wán] [dōng xī nán běi] [wǒ dōu zhī dào]', imageDescription: '小明在公园里开心地奔跑，背景是四个方向指示', teachingNote: '总结方向认知', wordAnnotations: [] }
    ];

    for (const page of book10Pages) {
      const annotations = (page.wordAnnotations || []).map(a => ({
        characterId: charMap[a.character],
        character: a.character,
        isNewWord: a.isNewWord,
        highlightStyle: a.isNewWord ? 'both' : 'underline'
      }));
      await BookPage.create({
        bookId: book10._id, pageNumber: page.pageNumber, text: page.text,
        pinyin: page.pinyin, imageDescription: page.imageDescription,
        teachingNote: page.teachingNote, wordAnnotations: annotations, interactiveElements: []
      });
    }
    console.log(`[Seed] 已创建绘本10的 ${book10Pages.length} 个页面`);

    console.log('[Seed] 种子数据导入完成! (共10本绘本)');
    process.exit(0);
  } catch (err) {
    console.error('[Seed] 导入失败:', err);
    process.exit(1);
  }
}

seed();
