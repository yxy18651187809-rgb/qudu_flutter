/**
 * L2绘本书架数据种子脚本（完善版）
 * 用法: node scripts/seed_L2_books.js
 * 
 * 数据来源：
 * - L2完整字_后端导入.json（80字）
 * - L2-015~L2-020 六篇已完成教案
 * - L2-021~L2-030 框架占位（待教研员完成）
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') || '../.env.example' });
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const Character = require('../src/models/Character');
const Book = require('../src/models/Book');
const BookPage = require('../src/models/BookPage');
const config = require('../src/config');

function mapCoreLevel(value) {
  if (value === '核心') return 'core';
  if (value === '扩展') return 'extended';
  return value || 'core';
}

function generateUnicode(char) {
  const code = char.charCodeAt(0);
  return 'U+' + code.toString(16).toUpperCase().padStart(4, '0');
}

async function seedL2() {
  try {
    await mongoose.connect(config.mongodb.uri);
    console.log('[Seed-L2] MongoDB 已连接');

    // ===== 1. 导入L2汉字 =====
    const jsonPath = path.join(__dirname, '../../../01-内容/L2完整字_后端导入.json');

    if (fs.existsSync(jsonPath)) {
      await Character.deleteMany({ level: 2 });
      console.log('[Seed-L2] 已清理 L2 Character 数据');

      const rawData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
      const characterDocs = rawData.map(item => ({
        character: item.character,
        unicode: item.unicode || generateUnicode(item.character),
        pinyin: item.pinyin,
        tone: item.tone,
        strokeCount: item.strokeCount,
        radical: item.radical,
        structure: item.structure,
        level: 2,
        grade: item.grade || 1,
        coreLevel: mapCoreLevel(item.coreLevel),
        frequency: item.frequency || 0,
        etymology: item.etymology || undefined,
        meanings: item.meanings || [],
        imageUrl: item.imageUrl || '',
        animationUrl: item.animationUrl || '',
        status: 'active'
      }));

      // 逐条插入，跳过已存在的字符（同一字符可能已从L1导入）
      let inserted = 0, skipped = 0;
      for (const doc of characterDocs) {
        try {
          await Character.create(doc);
          inserted++;
        } catch (err) {
          if (err.code === 11000) {
            skipped++;
          } else {
            console.error(`[Seed-L2] 插入失败 "${doc.character}":`, err.message);
          }
        }
      }
      console.log(`[Seed-L2] 已导入 ${inserted} 个L2汉字, ${skipped} 个重复(跳过)`);
    } else {
      console.log(`[Seed-L2] ⚠️ 未找到L2字表: ${jsonPath}`);
    }

    // ===== 2. 构建字ID映射 =====
    const allChars = await Character.find({}).lean();
    const charMap = {};
    allChars.forEach(c => { charMap[c.character] = c._id; });

    // ===== 3. 清理旧L2绘本 =====
    await Book.deleteMany({ level: 2 });
    await BookPage.deleteMany({ bookId: { $in: (await Book.find({ level: 2 }).select('_id')).map(b => b._id) } });
    console.log('[Seed-L2] 已清理 L2 Book 和 BookPage 数据');

    // ===== 4. 创建L2绘本（6篇已完成 + 4篇占位） =====

    // --- L2-015《我的好朋友》---
    const b01New = ['友','谊','分','享','助','互','相','懂','谅','吵','架','服','具','礼','貌','夸','赞','认','真','心'];
    const b01Review = ['人','大','小','我','你','好','的','了','是','在','有','不','来','去','一','二','三'];
    
    const b01 = await Book.create({
      bookId: 'L2_book_01', title: '我的好朋友',
      cover: '/uploads/covers/book_cover_L2_01.png',
      description: '理解朋友的意义，学会分享与原谅',
      level: 2, theme: '社交', tags: ['友谊','分享','原谅','礼貌'],
      protagonist: { name: '小明', description: '善良的小男孩，学会了做朋友' },
      newWords: b01New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b01New.length,
      reviewWords: b01Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 320, estimatedMinutes: 8,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'find_match', question: '朋友之间要怎么做？', instruction: '选择：分享/打架' },
        { type: 'image_match', question: '找出和朋友有关的字', instruction: '友、分、助' },
        { type: 'emotion', question: '你的好朋友是谁？说一件开心的事', instruction: '情感引导' }
      ],
      isFree: true, price: 0, sortOrder: 11, status: 'online', publishedAt: new Date()
    });

    const b01Pages = [
      { pn:1, text:'放学了，小明和小红一起回家。', py:'[fàng xué le, xiǎo míng hé xiǎo hóng yī qǐ huí jiā]', img:'放学了，小明和小红一起走出校门', teach:'认识"友"是朋友的意思', wa:[{c:'友',n:true}] },
      { pn:2, text:'小红有一个新玩具，邀请小明一起玩。', py:'[xiǎo hóng yǒu yī ge xīn wán jù]', img:'小红拿着一个新玩具', teach:'分享就是把自己喜欢的东西给别人玩', wa:[{c:'谊',n:true},{c:'分',n:true},{c:'享',n:true}] },
      { pn:3, text:'"我们一起玩吧！"小明说。', py:'[wǒ men yī qǐ wán ba]', img:'小明很开心地和小红分享玩具', teach:'邀请朋友一起玩', wa:[{c:'助',n:true}] },
      { pn:4, text:'他们互相帮忙，玩得很开心。', py:'[tā men hù xiāng bāng máng]', img:'两个小朋友在公园玩跷跷板', teach:'认识"互"和"相"，互相帮助', wa:[{c:'互',n:true},{c:'相',n:true}] },
      { pn:5, text:'小明不小心，碰到了小红。', py:'[xiǎo míng bù xiǎo xīn, pèng dào le xiǎo hóng]', img:'小明不小心弄疼了小红', teach:'认识"懂"和"谅"', wa:[{c:'懂',n:true},{c:'谅',n:true}] },
      { pn:6, text:'小红有些难过，但不怪小明。', py:'[xiǎo hóng yǒu xiē nán guò]', img:'小红有些伤心难过', teach:'认识"吵"', wa:[{c:'吵',n:true}] },
      { pn:7, text:'"对不起！"小明说。', py:'[duì bù qǐ, xiǎo míng shuō]', img:'小明向小红道歉', teach:'说"对不起"表示道歉', wa:[{c:'架',n:true}] },
      { pn:8, text:'"没关系，我们是好朋友！"小红说。', py:'[méi guān xi, wǒ men shì hǎo péng yǒu]', img:'小红原谅了小明', teach:'认识"服"和"具"', wa:[{c:'服',n:true},{c:'具',n:true}] },
      { pn:9, text:'他们一起玩滑梯，很高兴。', py:'[tā men yī qǐ wán huá tī]', img:'两人继续开心地玩耍', teach:'认识"礼"和"貌"', wa:[{c:'礼',n:true},{c:'貌',n:true}] },
      { pn:10, text:'"明天见！"他们互相挥手。', py:'[míng tiān jiàn, tā men hù xiāng huī shǒu]', img:'夕阳下，两个小朋友挥手告别', teach:'认识"夸"和"赞"', wa:[{c:'夸',n:true},{c:'赞',n:true}] },
      { pn:11, text:'小红告诉妈妈："我们互相帮助，是好朋友！"', py:'[xiǎo hóng gào sù mā ma, wǒ men hù xiāng bāng zhù]', img:'小红的妈妈问今天开心吗', teach:'复习"认真"', wa:[{c:'认',n:true}] },
      { pn:12, text:'小明说："朋友要互相分享，互相原谅！"', py:'[xiǎo míng shuō, péng yǒu yào hù xiāng fēn xiǎng]', img:'小明的妈妈也问了同样的话', teach:'认识"真"和"心"', wa:[{c:'真',n:true},{c:'心',n:true}] }
    ];

    for (const p of b01Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b01._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本01《我的好朋友》 ${b01Pages.length}页 ✅`);

    // --- L2-016《春游去》---
    const b02New = ['春','游','温','暖','绿','叶','蝶','蜜','蜂','野','餐','垫','背','食','吹','泡'];
    const b02Review = ['气','花','草','树','鸟','飞','包','物','我','你','好','的','了','一','起','去','来'];
    
    const b02 = await Book.create({
      bookId: 'L2_book_02', title: '春游去',
      cover: '/uploads/covers/book_cover_L2_02.png',
      description: '春天去野外，认识花虫鸟',
      level: 2, theme: '自然', tags: ['春游','自然','昆虫','野餐'],
      protagonist: { name: '小明', description: '和爸爸妈妈一起春游' },
      newWords: b02New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b02New.length,
      reviewWords: b02Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 340, estimatedMinutes: 9,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'image_match', question: '找出春天的景色', instruction: '花/草/树/燕子' },
        { type: 'find_match', question: '蝴蝶和蜜蜂在做什么？', instruction: '采蜜/飞舞' },
        { type: 'story_retell', question: '春游时你最喜欢做什么？', instruction: '引导复述' }
      ],
      isFree: true, price: 0, sortOrder: 12, status: 'online', publishedAt: new Date()
    });

    const b02Pages = [
      { pn:1, text:'春天到了，天气真暖和！', py:'[chūn tiān dào le, tiān qì zhēn nuǎn huo]', img:'春天来了，阳光温暖', teach:'认识"春"', wa:[{c:'春',n:true}] },
      { pn:2, text:'"我们去春游吧！"爸爸说。', py:'[wǒ men qù chūn yóu ba, bà ba shuō]', img:'爸爸提议去春游', teach:'认识"游"', wa:[{c:'游',n:true}] },
      { pn:3, text:'他们来到公园，看到很多花。', py:'[tā men lái dào gōng yuán, kàn dào hěn duō huā]', img:'一家三口来到公园', teach:'复习"气"', wa:[] },
      { pn:4, text:'草地上开着各种颜色的花，真美！', py:'[cǎo dì shàng kāi zhe gè zhǒng yán sè de huā]', img:'草地上开满了野花', teach:'认识"温"和"暖"', wa:[{c:'温',n:true},{c:'暖',n:true}] },
      { pn:5, text:'小树的叶子绿绿的，真好看！', py:'[xiǎo shù de yè zi lǜ lǜ de]', img:'小树长出了新叶子', teach:'认识"绿"和"叶"', wa:[{c:'绿',n:true},{c:'叶',n:true}] },
      { pn:6, text:'小鸟飞来飞去，真快乐！', py:'[xiǎo niǎo fēi lái fēi qù]', img:'小鸟在天空中飞', teach:'复习"鸟"和"飞"', wa:[] },
      { pn:7, text:'蝴蝶和蜜蜂在花间飞舞。', py:'[hú dié hé mì fēng zài huā jiān fēi wǔ]', img:'花丛中有蝴蝶和蜜蜂', teach:'认识"蝶""蜜""蜂"', wa:[{c:'蝶',n:true},{c:'蜜',n:true},{c:'蜂',n:true}] },
      { pn:8, text:'他们铺上野餐垫，开始野餐。', py:'[tā men pū shàng yě cān diàn]', img:'一家人在草地上野餐', teach:'认识"野""餐""垫"', wa:[{c:'野',n:true},{c:'餐',n:true},{c:'垫',n:true}] },
      { pn:9, text:'小明带来泡泡水，吹出很多泡泡。', py:'[xiǎo míng dài lái pào pao shuǐ]', img:'小明在吹泡泡', teach:'认识"吹"和"泡"', wa:[{c:'吹',n:true},{c:'泡',n:true}] },
      { pn:10, text:'泡泡在阳光下变成彩色，真美！', py:'[pào pào zài yáng guāng xià biàn chéng cǎi sè]', img:'泡泡在阳光下的彩虹', teach:'巩固泡泡', wa:[] },
      { pn:11, text:'背上小背包，带着食物。', py:'[bēi shàng xiǎo bèi bāo, dài zhe shí wù]', img:'小明背着小背包', teach:'认识"背"和"食"', wa:[{c:'背',n:true},{c:'食',n:true}] },
      { pn:12, text:'太阳快下山了，今天真开心！', py:'[tài yáng kuài xià shān le, jīn tiān zhēn kāi xīn]', img:'一家人开心地合照', teach:'总结春游', wa:[] }
    ];

    for (const p of b02Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b02._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本02《春游去》 ${b02Pages.length}页 ✅`);

    // --- L2-017《端午节》---
    const b03New = ['端','午','粽','艾','龙','舟','赛','香','绳','戴','念','原','勇','敢'];
    const b03Review = ['包','叶','米','我','你','好','的','了','在','有','不','来','去','一','二','三'];
    
    const b03 = await Book.create({
      bookId: 'L2_book_03', title: '端午节',
      cover: '/uploads/covers/book_cover_L2_03.png',
      description: '了解端午习俗，纪念屈原',
      level: 2, theme: '传统文化', tags: ['端午','粽子','龙舟','屈原'],
      protagonist: { name: '小明', description: '和妈妈一起过端午' },
      newWords: b03New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b03New.length,
      reviewWords: b03Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 330, estimatedMinutes: 9,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'image_match', question: '端午节的习俗有哪些？', instruction: '粽子/龙舟/艾草' },
        { type: 'find_match', question: '屈原是谁？', instruction: '爱国诗人' },
        { type: 'story_retell', question: '说一说端午节做什么', instruction: '引导复述' }
      ],
      isFree: true, price: 0, sortOrder: 13, status: 'online', publishedAt: new Date()
    });

    const b03Pages = [
      { pn:1, text:'五月初五是端午节。', py:'[wǔ yuè chū wǔ shì duān wǔ jié]', img:'五月初五，小明和妈妈在厨房包粽子', teach:'认识"端"和"午"', wa:[{c:'端',n:true},{c:'午',n:true}] },
      { pn:2, text:'妈妈包粽子，小明也帮忙。', py:'[mā ma bāo zòng zi, xiǎo míng yě bāng máng]', img:'妈妈教小明包粽子', teach:'认识"粽"', wa:[{c:'粽',n:true}] },
      { pn:3, text:'粽子真香啊！', py:'[zòng zi zhēn xiāng a]', img:'粽子煮好了，热气腾腾', teach:'认识"香"', wa:[{c:'香',n:true}] },
      { pn:4, text:'门口挂着艾草，可以驱蚊子。', py:'[mén kǒu guà zhe ài cǎo]', img:'小明家门口挂着艾草', teach:'认识"艾"', wa:[{c:'艾',n:true}] },
      { pn:5, text:'小明戴着五彩绳，好看极了！', py:'[xiǎo míng dài zhe wǔ cǎi shéng]', img:'小明手腕上系着五彩绳', teach:'认识"绳"和"戴"', wa:[{c:'绳',n:true},{c:'戴',n:true}] },
      { pn:6, text:'江上有龙舟比赛，真热闹！', py:'[jiāng shàng yǒu lóng zhōu bǐ sài]', img:'江上有龙舟比赛', teach:'认识"龙""舟""赛"', wa:[{c:'龙',n:true},{c:'舟',n:true},{c:'赛',n:true}] },
      { pn:7, text:'妈妈讲故事：屈原是谁？', py:'[mā ma jiǎng gù shì, qū yuán shì shuí]', img:'小明在看书，书上有屈原的故事', teach:'认识"念"和"屈"', wa:[{c:'念',n:true},{c:'屈',n:true}] },
      { pn:8, text:'屈原很勇敢，人们纪念他。', py:'[qū yuán hěn yǒng gǎn, rén men jì niàn tā]', img:'屈原投江的图画（简化处理）', teach:'认识"原""勇""敢"', wa:[{c:'原',n:true},{c:'勇',n:true},{c:'敢',n:true}] },
      { pn:9, text:'人们扔粽子到江里，不让鱼吃屈原。', py:'[rén men rēng zòng zi dào jiāng lǐ]', img:'大家往江里扔粽子', teach:'巩固"念"', wa:[] },
      { pn:10, text:'"粽子真好吃！"小明说。', py:'[zòng zi zhēn hǎo chī]', img:'小明吃粽子，很开心', teach:'巩固复习', wa:[] },
      { pn:11, text:'"明年端午节，我还要看龙舟！"小明说。', py:'[míng nián duān wǔ jié, wǒ hái yào kàn lóng zhōu]', img:'小明和小伙伴一起看龙舟', teach:'巩固', wa:[] },
      { pn:12, text:'端午节是团圆的节日，大家在一起。', py:'[duān wǔ jié shì tuán yuán de jié rì]', img:'夕阳下，小明家门前，全家人团圆', teach:'总结端午', wa:[] }
    ];

    for (const p of b03Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b03._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本03《端午节》 ${b03Pages.length}页 ✅`);

    // --- L2-018《小树长大了》---
    const b04New = ['种','浇','肥','泥','根','枝','高','粗','壮','窝','护','成'];
    const b04Review = ['树','叶','鸟','家','爱','我','你','好','的','了','在','有','不','一','二','三','上','下','来','去'];
    
    const b04 = await Book.create({
      bookId: 'L2_book_04', title: '小树长大了',
      cover: '/uploads/covers/book_cover_L2_04.png',
      description: '种下一棵树，看它长大',
      level: 2, theme: '成长', tags: ['种树','成长','坚持','保护'],
      protagonist: { name: '小明', description: '和一棵小树一起长大' },
      newWords: b04New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b04New.length,
      reviewWords: b04Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 340, estimatedMinutes: 9,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'story_retell', question: '种树的顺序是什么？', instruction: '挖坑→种树→浇水→长大' },
        { type: 'image_match', question: '小树需要什么才能长大？', instruction: '阳光/水/肥料' },
        { type: 'emotion', question: '你种过什么植物？怎么照顾它的？', instruction: '引导表达' }
      ],
      isFree: false, price: 0, sortOrder: 14, status: 'online', publishedAt: new Date()
    });

    const b04Pages = [
      { pn:1, text:'小明种了一棵小树。', py:'[xiǎo míng zhòng le yī kē xiǎo shù]', img:'小明在院子里种下一棵小树苗', teach:'认识"种"', wa:[{c:'种',n:true}] },
      { pn:2, text:'小明给小树浇水。', py:'[xiǎo míng gěi xiǎo shù jiāo shuǐ]', img:'小明给小树浇水', teach:'认识"浇"', wa:[{c:'浇',n:true}] },
      { pn:3, text:'小树在泥土里长根。', py:'[xiǎo shù zài ní tǔ lǐ zhǎng gēn]', img:'太阳晒着小树，小树在泥土里扎根', teach:'认识"泥"和"根"', wa:[{c:'泥',n:true},{c:'根',n:true}] },
      { pn:4, text:'小树长出了绿叶。', py:'[xiǎo shù zhǎng chū le lǜ yè]', img:'春天，小树长出了嫩绿的叶子', teach:'复习"叶"', wa:[] },
      { pn:5, text:'小树的树枝越来越多了。', py:'[xiǎo shù de shù zhī yuè lái yuè duō le]', img:'夏天，小树长出了很多树枝', teach:'认识"枝"', wa:[{c:'枝',n:true}] },
      { pn:6, text:'小树长高了！到小明的膝盖。', py:'[xiǎo shù zhǎng gāo le]', img:'小明比一比，小树长到他膝盖了', teach:'认识"高"', wa:[{c:'高',n:true}] },
      { pn:7, text:'小树越长越粗壮。', py:'[xiǎo shù yuè zhǎng yuè cū zhuàng]', img:'秋天，小树变得更粗壮了', teach:'认识"粗"和"壮"', wa:[{c:'粗',n:true},{c:'壮',n:true}] },
      { pn:8, text:'小鸟在小树上做窝。', py:'[xiǎo niǎo zài xiǎo shù shàng zuò wō]', img:'小鸟在小树上筑巢', teach:'认识"窝"', wa:[{c:'窝',n:true}] },
      { pn:9, text:'小鸟在树上唱歌。', py:'[xiǎo niǎo zài shù shàng chàng gē]', img:'小鸟在树上唱歌', teach:'复习"唱"', wa:[] },
      { pn:10, text:'一年过去了，小树长大了！', py:'[yī nián guò qù le, xiǎo shù zhǎng dà le]', img:'一年后，小树已经长得很高大了', teach:'巩固', wa:[] },
      { pn:11, text:'小树比小明还高了！', py:'[xiǎo shù bǐ xiǎo míng hái gāo le]', img:'小明和小树比身高', teach:'巩固"高"', wa:[] },
      { pn:12, text:'小明保护小树，不让它受伤。小树长大了！', py:'[xiǎo míng bǎo hù xiǎo shù, xiǎo shù zhǎng dà le]', img:'小明保护小树，不让别人摇晃', teach:'认识"护"和"成"', wa:[{c:'护',n:true},{c:'成',n:true}] }
    ];

    for (const p of b04Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b04._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本04《小树长大了》 ${b04Pages.length}页 ✅`);

    // --- L2-019《小雨滴》---
    const b05New = ['雨','滴','伞','靴','雷','闪','湿','滑','虹','晴','空'];
    const b05Review = ['风','云','泥','温','暖','我','你','好','的','了','在','有','不','来','去','一','上','下'];
    
    const b05 = await Book.create({
      bookId: 'L2_book_05', title: '小雨滴',
      cover: '/uploads/covers/book_cover_L2_05.png',
      description: '认识雨天，注意安全',
      level: 2, theme: '自然', tags: ['雨天','安全','彩虹','天气'],
      protagonist: { name: '小明', description: '在雨天玩耍的小朋友' },
      newWords: b05New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b05New.length,
      reviewWords: b05Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 330, estimatedMinutes: 9,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'image_match', question: '下雨天需要什么？', instruction: '雨伞/雨靴' },
        { type: 'find_match', question: '雨后天空会出现什么？', instruction: '彩虹' },
        { type: 'point_identify', question: '闪电打雷时应该怎么做？', instruction: '不要站在树下' }
      ],
      isFree: false, price: 0, sortOrder: 15, status: 'online', publishedAt: new Date()
    });

    const b05Pages = [
      { pn:1, text:'天空变暗了。要下雨了。', py:'[tiān kōng biàn àn le, yào xià yǔ le]', img:'窗外天空变暗，乌云密布', teach:'认识"雨"', wa:[{c:'雨',n:true},{c:'空',n:true}] },
      { pn:2, text:'雨滴落下来了。', py:'[yǔ dī luò xià lái le]', img:'雨滴开始从天空落下来', teach:'认识"滴"', wa:[{c:'滴',n:true}] },
      { pn:3, text:'小明拿出雨伞。', py:'[xiǎo míng ná chū yǔ sǎn]', img:'小明拿出雨伞', teach:'认识"伞"', wa:[{c:'伞',n:true}] },
      { pn:4, text:'穿上雨靴，去踩水！', py:'[chuān shàng yǔ xuē, qù cǎi shuǐ]', img:'小明穿上雨靴', teach:'认识"靴"', wa:[{c:'靴',n:true}] },
      { pn:5, text:'闪电！打雷了！', py:'[shǎn diàn, dǎ léi le]', img:'天空闪过一道闪电', teach:'认识"闪"和"雷"', wa:[{c:'闪',n:true},{c:'雷',n:true}] },
      { pn:6, text:'风吹雨斜。小明撑着伞。', py:'[fēng chuī yǔ xié]', img:'风吹得雨斜斜的', teach:'复习"风"', wa:[] },
      { pn:7, text:'踩到水坑，鞋子湿了。', py:'[cǎi dào shuǐ kēng, xié zi shī le]', img:'小明踩到水坑', teach:'认识"湿"', wa:[{c:'湿',n:true}] },
      { pn:8, text:'小明滑倒了。坐在泥巴里。', py:'[xiǎo míng huá dǎo le]', img:'小明滑倒在泥巴里', teach:'认识"滑"', wa:[{c:'滑',n:true}] },
      { pn:9, text:'雨停了。天空出现彩虹！', py:'[yǔ tíng le, tiān kōng chū xiàn cǎi hóng]', img:'雨停了，天空出现彩虹', teach:'认识"虹"', wa:[{c:'虹',n:true}] },
      { pn:10, text:'太阳出来了。天晴了！', py:'[tài yáng chū lái le, tiān qíng le]', img:'太阳出来了', teach:'认识"晴"', wa:[{c:'晴',n:true}] },
      { pn:11, text:'晾晒湿衣服。晒干就好了。', py:'[liàng shài shī yī fu]', img:'小明晾晒湿衣服', teach:'巩固"干"', wa:[] },
      { pn:12, text:'温暖的阳光。小明很开心。', py:'[wēn nuǎn de yáng guāng]', img:'小明看着温暖的阳光', teach:'复习"温"和"暖"', wa:[] }
    ];

    for (const p of b05Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b05._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本05《小雨滴》 ${b05Pages.length}页 ✅`);

    // --- L2-020《小雪花》---
    const b06New = ['雪','冷','热','冬','季','窗','结','冰','脚','印','炉','茶','杯','声','音'];
    const b06Review = ['花','笑','暖','家','我','你','好','的','了','在','有','不','来','去','一','上','下'];
    
    const b06 = await Book.create({
      bookId: 'L2_book_06', title: '小雪花',
      cover: '/uploads/covers/book_cover_L2_06.png',
      description: '认识冬天和雪花，注意保暖',
      level: 2, theme: '自然', tags: ['冬天','雪花','保暖','季节'],
      protagonist: { name: '小明', description: '在冬天玩耍的小朋友' },
      newWords: b06New.map(c => charMap[c]).filter(Boolean),
      newWordCount: b06New.length,
      reviewWords: b06Review.map(c => charMap[c]).filter(Boolean),
      pageCount: 12, totalCharacters: 340, estimatedMinutes: 9,
      vocabularyComplexity: 2, sentenceLength: 2,
      exercises: [
        { type: 'image_match', question: '冬天会下什么？', instruction: '雪花' },
        { type: 'find_match', question: '冬天需要穿什么？', instruction: '棉衣/手套/围巾' },
        { type: 'emotion', question: '冬天你最喜欢做什么？', instruction: '引导表达' }
      ],
      isFree: false, price: 0, sortOrder: 16, status: 'online', publishedAt: new Date()
    });

    const b06Pages = [
      { pn:1, text:'冬天来了。天空飘起小雪花。', py:'[dōng tiān lái le, tiān kōng piāo qǐ xiǎo xuě huā]', img:'冬天来了，天空飘起小雪花', teach:'认识"冬"和"雪"', wa:[{c:'冬',n:true},{c:'雪',n:true}] },
      { pn:2, text:'小明站在窗前。看着小雪花。', py:'[xiǎo míng zhàn zài chuāng qián]', img:'小明站在窗前看雪花', teach:'认识"窗"', wa:[{c:'窗',n:true}] },
      { pn:3, text:'玻璃很冷。小明缩回手。', py:'[bō li hěn lěng]', img:'小明用手摸玻璃', teach:'认识"冷"', wa:[{c:'冷',n:true}] },
      { pn:4, text:'戴上手套和围巾。出门去！', py:'[dài shàng shǒu tào hé wéi jīn]', img:'小明戴上手套和围巾', teach:'巩固', wa:[] },
      { pn:5, text:'雪地上有脚印。小明的脚印。', py:'[xuě dì shàng yǒu jiǎo yìn]', img:'小明在雪地里跑，脚印留在雪地上', teach:'认识"脚"和"印"', wa:[{c:'脚',n:true},{c:'印',n:true}] },
      { pn:6, text:'树枝结冰了。亮晶晶的。', py:'[shù zhī jié bīng le]', img:'小树的树枝上结了冰晶', teach:'认识"结"和"冰"', wa:[{c:'结',n:true},{c:'冰',n:true}] },
      { pn:7, text:'一起堆雪人。雪人笑哈哈。', py:'[yī qǐ duī xuě rén]', img:'小明和小伙伴一起堆雪人', teach:'复习"笑"', wa:[] },
      { pn:8, text:'手冻红了。脸也冻红了。', py:'[shǒu dòng hóng le]', img:'小明手和脸都冻红了', teach:'巩固', wa:[] },
      { pn:9, text:'回到家里。火炉暖暖的。', py:'[huí dào jiā lǐ, huǒ lú nuǎn nuǎn de]', img:'回到家里，火炉烧得暖暖的', teach:'认识"炉"', wa:[{c:'炉',n:true}] },
      { pn:10, text:'捧着热茶。暖暖和和的。', py:'[pěng zhe rè chá]', img:'小明捧着热茶', teach:'认识"热""茶""杯"', wa:[{c:'热',n:true},{c:'茶',n:true},{c:'杯',n:true}] },
      { pn:11, text:'外面很冷。家里很暖。', py:'[wài miàn hěn lěng, jiā lǐ hěn nuǎn]', img:'窗外雪还在下，小明在家很温暖', teach:'复习"冷"和"暖"', wa:[] },
      { pn:12, text:'家里有笑声。好听的声音。', py:'[jiā lǐ yǒu xiào shēng]', img:'小明笑着看书，家里有笑声', teach:'认识"声"和"音"', wa:[{c:'声',n:true},{c:'音',n:true}] }
    ];

    for (const p of b06Pages) {
      const annotations = p.wa.map(a => ({ characterId: charMap[a.c], character: a.c, isNewWord: a.n, highlightStyle: a.n ? 'both' : 'underline' }));
      await BookPage.create({ bookId: b06._id, pageNumber: p.pn, text: p.text, pinyin: p.py, imageDescription: p.img, teachingNote: p.teach, wordAnnotations: annotations, interactiveElements: [] });
    }
    console.log(`[Seed-L2] 绘本06《小雪花》 ${b06Pages.length}页 ✅`);

    // ===== 5. L2占位绘本（4本draft，待教研员完成） =====
    const draftBooks = [
      { bookId:'L2_book_07', title:'小马的河', cover:'/uploads/covers/book_cover_L2_07.png', description:'小马过河，学会自己判断', theme:'成长', tags:['成长','判断','勇气'], protagonist:{name:'小马',description:'棕色小马驹，勇敢好奇'}, sortOrder:17 },
      { bookId:'L2_book_08', title:'蚂蚁搬家', cover:'/uploads/covers/book_cover_L2_08.png', description:'团队合作，天气变化', theme:'自然', tags:['蚂蚁','团队','天气'], protagonist:{name:'小蚂蚁',description:'勤劳的蚂蚁工人'}, sortOrder:18 },
      { bookId:'L2_book_09', title:'谁最聪明', cover:'/uploads/covers/book_cover_L2_09.png', description:'不以貌取人', theme:'成长', tags:['智慧','公平','成长'], protagonist:{name:'小动物们',description:'森林里的小动物'}, sortOrder:19 },
      { bookId:'L2_book_10', title:'种一棵树', cover:'/uploads/covers/book_cover_L2_10.png', description:'种树过程，观察成长', theme:'科学', tags:['树','成长','科学'], protagonist:{name:'小园丁',description:'喜欢种树的小朋友'}, sortOrder:20 }
    ];

    for (const draft of draftBooks) {
      await Book.create({
        ...draft,
        level: 2,
        newWords: [],
        newWordCount: 0,
        reviewWords: [],
        pageCount: 12,
        totalCharacters: 300,
        estimatedMinutes: 9,
        vocabularyComplexity: 2,
        sentenceLength: 2,
        exercises: [],
        isFree: false,
        status: 'draft'
      });
      console.log(`[Seed-L2] 占位绘本《${draft.title}》 draft ✅`);
    }

    console.log('[Seed-L2] ✅ L2种子数据导入完成！(6本完整 + 4本占位)');
  } catch (err) {
    console.error('[Seed-L2] ❌ 错误:', err);
  } finally {
    await mongoose.disconnect();
    console.log('[Seed-L2] MongoDB 已断开');
  }
}

seedL2();
