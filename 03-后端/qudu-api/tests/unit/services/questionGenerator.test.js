/**
 * questionGenerator.js 单元测试
 *
 * 覆盖纯函数：adjustDistribution, stripTone, shuffleArray, buildQuestion
 * 不依赖 MongoDB，纯逻辑验证
 */

const {
  adjustDistribution,
  stripTone,
  shuffleArray,
  buildQuestion,
  ASSESSMENT_CONFIG,
  THEME_MAP,
  SIMILAR_SHAPE_MAP
} = require('../../../src/services/questionGenerator');

// ========== stripTone ==========

describe('stripTone', () => {
  test('去掉一声 ā → a', () => {
    expect(stripTone('mā')).toBe('ma');
  });

  test('去掉二声 á → a', () => {
    expect(stripTone('bá')).toBe('ba');
  });

  test('去掉三声 ǎ → a', () => {
    expect(stripTone('wǎ')).toBe('wa');
  });

  test('去掉四声 à → a', () => {
    expect(stripTone('dà')).toBe('da');
  });

  test('多声调混合 nǐ hǎo', () => {
    expect(stripTone('nǐ')).toBe('ni');
    expect(stripTone('hǎo')).toBe('hao');
  });

  test('ǚ 特殊声调', () => {
    expect(stripTone('lǚ')).toBe('lv');
    expect(stripTone('nǜ')).toBe('nv');
  });

  test('空格返回空字符串', () => {
    expect(stripTone('')).toBe('');
    expect(stripTone(null)).toBe('');
  });
});

// ========== adjustDistribution ==========

describe('adjustDistribution', () => {
  const reviewDist = ASSESSMENT_CONFIG.review.typeDistribution; // 8,6,6

  test('总数相同时返回原分布', () => {
    const result = adjustDistribution(reviewDist, 20);
    expect(result).toEqual({ recognize: 8, meaning_select: 6, pinyin_match: 6 });
  });

  test('15题时符合教研设计 6+6+3', () => {
    const result = adjustDistribution(reviewDist, 15);
    // 15 * 8/20 = 6 → recognize:6
    // 15 * 6/20 = 4.5 → floor=4
    // 15 * 6/20 = 4.5 → floor=4
    // remainder 1 → recognize
    expect(result.recognize + result.meaning_select + result.pinyin_match).toBe(15);
  });

  test('10题时分布总和等于10', () => {
    const result = adjustDistribution(reviewDist, 10);
    const total = Object.values(result).reduce((s, v) => s + v, 0);
    expect(total).toBe(10);
  });

  test('18题时分布总和等于18', () => {
    const result = adjustDistribution(reviewDist, 18);
    const total = Object.values(result).reduce((s, v) => s + v, 0);
    expect(total).toBe(18);
  });

  test('5题时分布总和等于5', () => {
    const result = adjustDistribution(reviewDist, 5);
    const total = Object.values(result).reduce((s, v) => s + v, 0);
    expect(total).toBe(5);
  });

  test('所有题型非负', () => {
    for (let count = 1; count <= 30; count++) {
      const result = adjustDistribution(reviewDist, count);
      expect(result.recognize).toBeGreaterThanOrEqual(0);
      expect(result.meaning_select).toBeGreaterThanOrEqual(0);
      expect(result.pinyin_match).toBeGreaterThanOrEqual(0);
    }
  });

  test('initial 配置 20题分布正确', () => {
    const initDist = ASSESSMENT_CONFIG.initial.typeDistribution;
    const result = adjustDistribution(initDist, 20);
    expect(result.recognize).toBe(8);
    expect(result.meaning_select).toBe(7);
    expect(result.pinyin_match).toBe(5);
  });

  test('review 配置 20题分布正确', () => {
    const result = adjustDistribution(reviewDist, 20);
    expect(result.recognize).toBe(8);
    expect(result.meaning_select).toBe(6);
    expect(result.pinyin_match).toBe(6);
  });
});

// ========== shuffleArray ==========

describe('shuffleArray', () => {
  test('返回相同长度的数组', () => {
    const arr = [1, 2, 3, 4, 5];
    const result = shuffleArray(arr);
    expect(result.length).toBe(arr.length);
  });

  test('不修改原数组', () => {
    const arr = [1, 2, 3];
    const copy = [...arr];
    shuffleArray(arr);
    expect(arr).toEqual(copy);
  });

  test('包含所有原元素', () => {
    const arr = ['a', 'b', 'c', 'd', 'e'];
    const result = shuffleArray(arr);
    expect(result.sort()).toEqual(arr.sort());
  });

  test('空数组返回空数组', () => {
    expect(shuffleArray([])).toEqual([]);
  });

  test('单元素数组返回相同', () => {
    expect(shuffleArray([42])).toEqual([42]);
  });
});

// ========== buildQuestion ==========

describe('buildQuestion', () => {
  const mockCharDoc = {
    _id: '507f1f77bcf86cd799439011',
    character: '大',
    pinyin: 'dà',
    meanings: [{ meaning: '大小的大' }],
    tone: 4
  };

  const mockDistractors = ['小', '天', '人'];

  const mockCharMap = {
    '大': mockCharDoc,
    '小': { character: '小', pinyin: 'xiǎo', meanings: [{ meaning: '大小的小' }] },
    '天': { character: '天', pinyin: 'tiān', meanings: [{ meaning: '天空的天' }] },
    '人': { character: '人', pinyin: 'rén', meanings: [{ meaning: '人类的人' }] }
  };

  test('recognize 题型：看字选拼音', () => {
    const q = buildQuestion(mockCharDoc, 'recognize', mockDistractors, mockCharMap);
    expect(q.questionType).toBe('recognize');
    expect(q.correctAnswer).toBe('dà');
    expect(q.options).toHaveLength(4);
    expect(q.options[0]).toHaveProperty('key');
    expect(q.options[0]).toHaveProperty('content');
    // 正确答案在选项中
    expect(q.options.some(o => o.content === 'dà')).toBe(true);
    // recognize 题型不返回 imageUrl
    expect(q.imageUrl).toBeNull();
  });

  test('pinyin_match 题型：看拼音选字', () => {
    const q = buildQuestion(mockCharDoc, 'pinyin_match', mockDistractors, mockCharMap);
    expect(q.questionType).toBe('pinyin_match');
    expect(q.correctAnswer).toBe('大');
    expect(q.options).toHaveLength(4);
    // 正确答案在选项中
    expect(q.options.some(o => o.content === '大')).toBe(true);
    // 干扰项在选项中
    expect(q.options.some(o => o.content === '小')).toBe(true);
    expect(q.imageUrl).toBeNull();
  });

  test('meaning_select 题型：看字选意思', () => {
    const q = buildQuestion(mockCharDoc, 'meaning_select', mockDistractors, mockCharMap);
    expect(q.questionType).toBe('meaning_select');
    expect(q.correctAnswer).toBe('大小的大');
    expect(q.options).toHaveLength(4);
    // 选项 key 为 A/B/C/D
    expect(q.options[0].key).toBe('A');
    expect(q.options[1].key).toBe('B');
    // meaning_select 题型返回 imageUrl
    expect(q.imageUrl).toBe('/images/characters/大.png');
  });

  test('audioUrl 正确生成', () => {
    const q = buildQuestion(mockCharDoc, 'recognize', mockDistractors, mockCharMap);
    expect(q.audioUrl).toBe('/audio/大.mp3');
  });

  test('characterId 正确赋值', () => {
    const q = buildQuestion(mockCharDoc, 'recognize', mockDistractors, mockCharMap);
    expect(q.characterId).toBe('507f1f77bcf86cd799439011');
  });

  test('干扰项缺少 charMap 时使用 fallback 拼音', () => {
    // 只提供部分 charMap，模拟干扰字无拼音数据
    const partialMap = { '大': mockCharDoc };
    const q = buildQuestion(mockCharDoc, 'recognize', ['小', '天', '人'], partialMap);
    // 应有4个选项（正确+fallback拼音）
    expect(q.options).toHaveLength(4);
    // 正确答案在选项中
    expect(q.options.some(o => o.content === 'dà')).toBe(true);
  });

  test('干扰项缺少 charMap 时使用 fallback 释义', () => {
    const partialMap = { '大': mockCharDoc };
    const q = buildQuestion(mockCharDoc, 'meaning_select', ['小', '天', '人'], partialMap);
    expect(q.options).toHaveLength(4);
    expect(q.correctAnswer).toBe('大小的大');
  });
});

// ========== 配置常量验证 ==========

describe('配置常量完整性', () => {
  test('ASSESSMENT_CONFIG 包含三种测评类型', () => {
    expect(ASSESSMENT_CONFIG).toHaveProperty('initial');
    expect(ASSESSMENT_CONFIG).toHaveProperty('review');
    expect(ASSESSMENT_CONFIG).toHaveProperty('level_test');
  });

  test('每种测评类型分布总和等于 totalQuestions', () => {
    for (const type of ['initial', 'review', 'level_test']) {
      const cfg = ASSESSMENT_CONFIG[type];
      const dist = cfg.typeDistribution;
      const sum = Object.values(dist).reduce((s, v) => s + v, 0);
      expect(sum).toBe(cfg.totalQuestions);
    }
  });

  test('THEME_MAP 包含所有主题', () => {
    expect(THEME_MAP).toHaveProperty('身体部位');
    expect(THEME_MAP).toHaveProperty('自然动物');
    expect(THEME_MAP).toHaveProperty('校园');
    expect(THEME_MAP).toHaveProperty('食物');
  });

  test('SIMILAR_SHAPE_MAP 包含常见形近字', () => {
    expect(SIMILAR_SHAPE_MAP['人']).toContain('入');
    expect(SIMILAR_SHAPE_MAP['大']).toContain('太');
    expect(SIMILAR_SHAPE_MAP['日']).toContain('白');
    expect(SIMILAR_SHAPE_MAP['子']).toContain('了');
  });
});
