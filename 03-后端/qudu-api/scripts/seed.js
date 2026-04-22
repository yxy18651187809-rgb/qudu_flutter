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
    const jsonPath = path.join(__dirname, '../../01-内容/L1完整字300_后端导入.json');
    
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

    // 绘本01《我的身体》— 20个新字
    const book1NewWords = ['人', '口', '手', '足', '头', '脸', '眼', '耳', '鼻', '心', '十', '只', '个', '会', '能', '爱', '我', '你', '他', '她'];
    const book1ReviewWords = ['大', '小', '上', '下', '天', '地', '一', '二', '三', '四'];
    
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
      totalCharacters: 120,
      estimatedMinutes: 5,
      vocabularyComplexity: 1,
      sentenceLength: 1,
      exercises: [
        { type: 'image_match', question: '看看图片，选出正确的身体部位名称', instruction: '手的图片→手、头的图片→头、嘴巴的图片→口' },
        { type: 'listen_select', question: '听老师读，选择正确的字', instruction: '老师读"耳朵"，选"耳"' },
        { type: 'point_identify', question: '指指你的头在哪里？口在哪里？手在哪里？', instruction: '引导孩子认识身体部位' },
        { type: 'count', question: '数一数你有多少只手？多少只足？', instruction: '用图片辅助理解数量' },
        { type: 'emotion_match', question: '把表情和对应的感受连起来', instruction: '笑脸→开心 哭脸→伤心' }
      ],
      isFree: true,
      price: 0,
      sortOrder: 1,
      status: 'online',
      publishedAt: new Date()
    });
    console.log(`[Seed] 已创建绘本: ${book1.title} (ID: ${book1._id})`);

    // 绘本01页面（基于教研员v1文案）
    const book1Pages = [
      { pageNumber: 1, text: '我是小明。', pinyin: '[wǒ shì xiǎo míng]', imageDescription: '清晨，小主人公在床上醒来，揉揉眼睛，窗外有阳光', teachingNote: '认识"我"是每个人独特的称呼', wordAnnotations: [{ character: '我', isNewWord: true }] },
      { pageNumber: 2, text: '这是我的头。', pinyin: '[zhè shì wǒ de tóu]', imageDescription: '小主人公指着镜子里的自己，数着身体部位', teachingNote: '认识"头"是身体的最高部位', wordAnnotations: [{ character: '头', isNewWord: true }] },
      { pageNumber: 3, text: '这是我的脸。我的脸会笑。', pinyin: '[zhè shì wǒ de liǎn] [wǒ de liǎn huì xiào]', imageDescription: '小主人公用手指着自己的脸，镜子里有笑脸', teachingNote: '认识"脸"能表达情绪', wordAnnotations: [{ character: '脸', isNewWord: true }, { character: '会', isNewWord: true }] },
      { pageNumber: 4, text: '我的眼睛会看。我看见花。', pinyin: '[wǒ de yǎn jīng huì kàn] [wǒ kàn jiàn huā]', imageDescription: '小主人公用手指着自己的眼睛，再指着花朵', teachingNote: '眼睛的用处是看东西', wordAnnotations: [{ character: '眼', isNewWord: true }] },
      { pageNumber: 5, text: '我的耳朵会听。小鸟唱歌，我听见了。', pinyin: '[wǒ de ěr duo huì tīng] [xiǎo niǎo chàng gē wǒ tīng jiàn le]', imageDescription: '小主人公的耳朵旁边有一只小鸟在唱歌', teachingNote: '耳朵的用处是听声音', wordAnnotations: [{ character: '耳', isNewWord: true }] },
      { pageNumber: 6, text: '我的鼻子会闻。我闻见花香。', pinyin: '[wǒ de bí zi huì wén] [wǒ wén jiàn huā xiāng]', imageDescription: '小主人公用手指着自己的鼻子，旁边有花朵和饼干', teachingNote: '鼻子的用处是闻气味', wordAnnotations: [{ character: '鼻', isNewWord: true }] },
      { pageNumber: 7, text: '我的口会说话。啊——啊——', pinyin: '[wǒ de kǒu huì shuō huà] [ā——ā——]', imageDescription: '小主人公张大嘴巴，嘴里有白白健康的牙齿', teachingNote: '嘴巴的用处是说话和吃东西', wordAnnotations: [{ character: '口', isNewWord: true }] },
      { pageNumber: 8, text: '我有两只手。我有两只足。', pinyin: '[wǒ yǒu liǎng zhī shǒu] [wǒ yǒu liǎng zhī zú]', imageDescription: '小主人公伸出双手，十根手指张开，旁边还有两只脚', teachingNote: '认识"手"和"足"，理解"两只"的数量', wordAnnotations: [{ character: '手', isNewWord: true }, { character: '只', isNewWord: true }, { character: '足', isNewWord: true }] },
      { pageNumber: 9, text: '我的心在跳。我爱爸爸妈妈。', pinyin: '[wǒ de xīn zài tiào] [wǒ ài bà ba mā ma]', imageDescription: '小主人公用手摸着心口，脸上是开心的表情', teachingNote: '心代表爱和情感', wordAnnotations: [{ character: '心', isNewWord: true }, { character: '爱', isNewWord: true }] },
      { pageNumber: 10, text: '我有一个身体。我能跑、能跳、能长大。我爱我自己。', pinyin: '[wǒ yǒu yī gè shēn tǐ] [wǒ néng pǎo néng tiào néng zhǎng dà] [wǒ ài wǒ zì jǐ]', imageDescription: '小主人公张开双臂拥抱自己，背景是温暖的阳光', teachingNote: '每个人都有独一无二的身体，要学会爱护自己', wordAnnotations: [{ character: '个', isNewWord: true }, { character: '能', isNewWord: true }] }
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

    console.log('[Seed] 种子数据导入完成!');
    process.exit(0);
  } catch (err) {
    console.error('[Seed] 导入失败:', err);
    process.exit(1);
  }
}

seed();
