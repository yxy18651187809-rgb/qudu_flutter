/**
 * reviewAlgorithm.js 单元测试
 *
 * 覆盖 SM-2 遗忘曲线算法纯函数：
 * calculateNextReview, calculateStage, estimateWordCount,
 * recommendLevel, addDays
 */

const {
  calculateNextReview,
  calculateStage,
  estimateWordCount,
  recommendLevel,
  addDays
} = require('../../../src/services/reviewAlgorithm');

// ========== calculateNextReview ==========

describe('calculateNextReview', () => {
  describe('正确回答', () => {
    test('第1次正确：interval 保持为1', () => {
      const mastery = { currentInterval: 1, easeFactor: 2.5, masteryScore: 0 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.nextInterval).toBe(1);
      expect(result.easeFactor).toBe(2.6);
      expect(result.masteryScore).toBe(15);
    });

    test('第2次正确（interval=1）：interval 保持为1（算法基于 interval 非次数）', () => {
      const mastery = { currentInterval: 1, easeFactor: 2.6, masteryScore: 15 };
      const result = calculateNextReview(mastery, 'correct');
      // currentInterval===1 → 第一条分支命中，保持1
      // easeFactor +0.1, masteryScore +15
      expect(result.nextInterval).toBe(1);
    });

    test('interval=2 正确：interval 升至3', () => {
      const mastery = { currentInterval: 2, easeFactor: 2.5, masteryScore: 30 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.nextInterval).toBe(3);
    });

    test('interval=3 正确：interval 升至6', () => {
      const mastery = { currentInterval: 3, easeFactor: 2.5, masteryScore: 45 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.nextInterval).toBe(6);
    });

    test('interval=6 正确：interval * easeFactor', () => {
      const mastery = { currentInterval: 6, easeFactor: 2.5, masteryScore: 60 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.nextInterval).toBe(15); // 6 * 2.5 = 15
    });

    test('掌握度上限100', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.5, masteryScore: 95 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.masteryScore).toBe(100);
    });

    test('easeFactor 上限3.0', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.95, masteryScore: 80 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.easeFactor).toBe(3.0);
    });
  });

  describe('错误回答', () => {
    test('重置 interval 为 1', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.5, masteryScore: 60 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.nextInterval).toBe(1);
    });

    test('降低 easeFactor', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.5, masteryScore: 60 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.easeFactor).toBe(2.3);
    });

    test('easeFactor 下限1.3', () => {
      const mastery = { currentInterval: 10, easeFactor: 1.35, masteryScore: 20 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.easeFactor).toBe(1.3);
    });

    test('降低掌握度 -20', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.5, masteryScore: 60 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.masteryScore).toBe(40);
    });

    test('掌握度下限0', () => {
      const mastery = { currentInterval: 10, easeFactor: 2.5, masteryScore: 10 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.masteryScore).toBe(0);
    });
  });

  describe('跳过', () => {
    test('保持 interval 不变', () => {
      const mastery = { currentInterval: 5, easeFactor: 2.5, masteryScore: 30 };
      const result = calculateNextReview(mastery, 'skipped');
      expect(result.nextInterval).toBe(5);
    });

    test('easeFactor 不变', () => {
      const mastery = { currentInterval: 5, easeFactor: 2.5, masteryScore: 30 };
      const result = calculateNextReview(mastery, 'skipped');
      expect(result.easeFactor).toBe(2.5);
    });

    test('掌握度 -5', () => {
      const mastery = { currentInterval: 5, easeFactor: 2.5, masteryScore: 30 };
      const result = calculateNextReview(mastery, 'skipped');
      expect(result.masteryScore).toBe(25);
    });
  });

  describe('学习阶段', () => {
    test('掌握度≥80 + interval≥6 → mastered', () => {
      const mastery = { currentInterval: 6, easeFactor: 2.5, masteryScore: 80 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.stage).toBe('mastered');
    });

    test('掌握度≥40 → reviewing', () => {
      const mastery = { currentInterval: 3, easeFactor: 2.5, masteryScore: 40 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.stage).toBe('reviewing');
    });

    test('掌握度>0 且 <40 → learning', () => {
      const mastery = { currentInterval: 2, easeFactor: 2.5, masteryScore: 15 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.stage).toBe('learning');
    });

    test('掌握度=0 → new', () => {
      const mastery = { currentInterval: 1, easeFactor: 2.5, masteryScore: 0 };
      const result = calculateNextReview(mastery, 'wrong');
      expect(result.stage).toBe('new');
    });
  });

  describe('nextReviewAt 时间校验', () => {
    test('返回未来日期', () => {
      const mastery = { currentInterval: 3, easeFactor: 2.5, masteryScore: 30 };
      const result = calculateNextReview(mastery, 'correct');
      expect(result.nextReviewAt).toBeInstanceOf(Date);
      expect(result.nextReviewAt.getTime()).toBeGreaterThan(Date.now() - 1000);
    });
  });
});

// ========== calculateStage ==========

describe('calculateStage', () => {
  test('mastery≥80 + interval≥6 → mastered', () => {
    expect(calculateStage(80, 6)).toBe('mastered');
    expect(calculateStage(90, 10)).toBe('mastered');
  });

  test('mastery≥80 但 interval<6 → reviewing', () => {
    expect(calculateStage(80, 3)).toBe('reviewing');
  });

  test('mastery≥40 → reviewing', () => {
    expect(calculateStage(40, 3)).toBe('reviewing');
    expect(calculateStage(75, 5)).toBe('reviewing');
  });

  test('mastery>0 且 <40 → learning', () => {
    expect(calculateStage(1, 1)).toBe('learning');
    expect(calculateStage(39, 5)).toBe('learning');
  });

  test('mastery=0 → new', () => {
    expect(calculateStage(0, 1)).toBe('new');
    expect(calculateStage(0, 10)).toBe('new');
  });
});

// ========== estimateWordCount ==========

describe('estimateWordCount', () => {
  test('全部正确 → 估算所有字', () => {
    const results = [{ level: 1, accuracy: 100 }];
    const estimated = estimateWordCount(results);
    expect(estimated).toBe(300);
  });

  test('50% 正确 L1', () => {
    const results = [{ level: 1, accuracy: 50 }];
    const estimated = estimateWordCount(results);
    expect(estimated).toBe(150);
  });

  test('多级别累加', () => {
    const results = [
      { level: 1, accuracy: 80 },
      { level: 2, accuracy: 50 }
    ];
    const estimated = estimateWordCount(results);
    // L1: 300*0.8=240, L2: 600*0.5=300, total=540
    expect(estimated).toBe(540);
  });

  test('L1 0% → 0', () => {
    const results = [{ level: 1, accuracy: 0 }];
    const estimated = estimateWordCount(results);
    expect(estimated).toBe(0);
  });

  test('空结果返回0', () => {
    expect(estimateWordCount([])).toBe(0);
  });
});

// ========== recommendLevel ==========

describe('recommendLevel', () => {
  test('0~300 → L1', () => {
    expect(recommendLevel(0)).toBe(1);
    expect(recommendLevel(150)).toBe(1);
    expect(recommendLevel(300)).toBe(1);
  });

  test('301~600 → L2', () => {
    expect(recommendLevel(301)).toBe(2);
    expect(recommendLevel(500)).toBe(2);
    expect(recommendLevel(600)).toBe(2);
  });

  test('601~1000 → L3', () => {
    expect(recommendLevel(601)).toBe(3);
    expect(recommendLevel(1000)).toBe(3);
  });

  test('1001~1500 → L4', () => {
    expect(recommendLevel(1001)).toBe(4);
    expect(recommendLevel(1500)).toBe(4);
  });

  test('1501+ → L5', () => {
    expect(recommendLevel(1501)).toBe(5);
    expect(recommendLevel(3000)).toBe(5);
  });
});

// ========== addDays ==========

describe('addDays', () => {
  test('加1天', () => {
    const date = new Date('2026-05-10');
    const result = addDays(date, 1);
    expect(result.getDate()).toBe(11);
    expect(result.getMonth()).toBe(4); // May
  });

  test('加0天返回同一天', () => {
    const date = new Date('2026-05-10');
    const result = addDays(date, 0);
    expect(result.getTime()).toBe(date.getTime());
  });

  test('跨月加天', () => {
    const date = new Date('2026-05-31');
    const result = addDays(date, 1);
    expect(result.getMonth()).toBe(5); // June
    expect(result.getDate()).toBe(1);
  });

  test('不修改原日期', () => {
    const date = new Date('2026-05-10');
    const originalTime = date.getTime();
    addDays(date, 5);
    expect(date.getTime()).toBe(originalTime);
  });

  test('加30天', () => {
    const date = new Date('2026-05-10');
    const result = addDays(date, 30);
    expect(result.getMonth()).toBe(5); // June
    expect(result.getDate()).toBe(9);
  });
});
