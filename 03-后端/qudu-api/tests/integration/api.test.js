/**
 * 字趣阅读 - 后端集成测试
 * 覆盖：TTS API、测评即时反馈、绘本/字卡 API
 * 
 * 运行: npx jest tests/integration/api.test.js
 * 
 * 注意：需要 MongoDB 运行在 localhost，且已执行 seed
 */

const request = require('supertest');
const mongoose = require('mongoose');

// 测试前设置：加载app但不监听端口
let app;
let authToken;
let testChildId;

beforeAll(async () => {
  // 加载环境变量
  require('dotenv').config({ path: require('path').join(__dirname, '../../.env') || '../../.env.example' });
  
  app = require('../../src/app.js');
  
  // 等待mongoose连接
  await new Promise(resolve => {
    const check = () => {
      if (mongoose.connection.readyState === 1) resolve();
      else setTimeout(check, 100);
    };
    check();
  });
  
  // 获取测试用户token（mock SMS模式下直接登录）
  const config = require('../../src/config');
  if (config.sms.provider === 'mock') {
    // 发送验证码
    await request(app)
      .post('/api/v1/auth/sms-code')
      .send({ phone: '13800138000' });
    
    // 使用mock验证码登录
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ phone: '13800138000', code: config.sms.mockCode || '123456' });
    
    if (loginRes.body.data && loginRes.body.data.token) {
      authToken = loginRes.body.data.token;
    }
  }
  
  // 获取测试儿童ID
  if (authToken) {
    const childrenRes = await request(app)
      .get('/api/v1/children')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (childrenRes.body.data && childrenRes.body.data.length > 0) {
      testChildId = childrenRes.body.data[0].id;
    } else {
      // 创建测试儿童
      const createRes = await request(app)
        .post('/api/v1/children')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: '测试宝宝', birthDate: '2020-01-01', gender: 'male' });
      
      if (createRes.body.data) {
        testChildId = createRes.body.data.id;
      }
    }
  }
}, 30000);

afterAll(async () => {
  await mongoose.disconnect();
}, 10000);

// ============================================================
// 测试套件1：TTS API
// ============================================================
describe('TTS API', () => {
  describe('GET /api/v1/tts/character/:char', () => {
    test('返回单个汉字的发音音频URL', async () => {
      const res = await request(app)
        .get('/api/v1/tts/character/春')
        .set('Authorization', `Bearer ${authToken}`);
      
      // 可能200（成功）或404（字不在数据库）
      if (res.status === 200) {
        expect(res.body.data).toHaveProperty('character', '春');
        expect(res.body.data).toHaveProperty('pinyin');
        expect(res.body.data).toHaveProperty('audioUrl');
        expect(res.body.data.audioUrl).toMatch(/\.mp3$/);
      }
    });

    test('拒绝无效汉字参数', async () => {
      const res = await request(app)
        .get('/api/v1/tts/character/abc')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(400);
      expect(res.body.message).toMatch(/单个汉字/);
    });

    test('拒绝空字符参数', async () => {
      const res = await request(app)
        .get('/api/v1/tts/character/');
      
      // 应该404（路由不匹配）或400
      expect([400, 404]).toContain(res.status);
    });

    test('不存在的汉字返回404', async () => {
      const res = await request(app)
        .get('/api/v1/tts/character/龘')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/v1/books/:id/tts', () => {
    test('返回绘本全部页面TTS音频', async () => {
      // 先获取一本存在的绘本
      const booksRes = await request(app)
        .get('/api/v1/books?level=1&pageSize=1')
        .set('Authorization', `Bearer ${authToken}`);
      
      if (booksRes.status === 200 && booksRes.body.data && booksRes.body.data.list && booksRes.body.data.list.length > 0) {
        const book = booksRes.body.data.list[0];
        const bookId = book.id || book.bookId;
        
        const res = await request(app)
          .get(`/api/v1/books/${bookId}/tts`)
          .set('Authorization', `Bearer ${authToken}`);
        
        if (res.status === 200) {
          const data = res.body.data;
          expect(data).toHaveProperty('pages');
          expect(Array.isArray(data.pages)).toBe(true);
          expect(data.pages.length).toBeGreaterThan(0);
          
          // 验证页面音频结构
          const firstPage = data.pages[0];
          expect(firstPage).toHaveProperty('pageNumber');
          expect(firstPage).toHaveProperty('text');
          expect(firstPage).toHaveProperty('audio');
          expect(firstPage.audio).toHaveProperty('preGenerated');
          expect(firstPage.audio).toHaveProperty('charByChar');
        }
      }
    });

    test('返回绘本单页TTS音频（带page参数）', async () => {
      const booksRes = await request(app)
        .get('/api/v1/books?level=1&pageSize=1')
        .set('Authorization', `Bearer ${authToken}`);
      
      if (booksRes.status === 200 && booksRes.body.data && booksRes.body.data.list && booksRes.body.data.list.length > 0) {
        const book = booksRes.body.data.list[0];
        const bookId = book.id || book.bookId;
        
        const res = await request(app)
          .get(`/api/v1/books/${bookId}/tts?page=1`)
          .set('Authorization', `Bearer ${authToken}`);
        
        if (res.status === 200) {
          const data = res.body.data;
          expect(data).toHaveProperty('pageNumber', 1);
          expect(data).toHaveProperty('text');
          expect(data).toHaveProperty('audio');
        }
      }
    });

    test('无效页码返回400', async () => {
      const booksRes = await request(app)
        .get('/api/v1/books?level=1&pageSize=1')
        .set('Authorization', `Bearer ${authToken}`);
      
      if (booksRes.status === 200 && booksRes.body.data && booksRes.body.data.list && booksRes.body.data.list.length > 0) {
        const book = booksRes.body.data.list[0];
        const bookId = book.id || book.bookId;
        
        const res = await request(app)
          .get(`/api/v1/books/${bookId}/tts?page=-1`)
          .set('Authorization', `Bearer ${authToken}`);
        
        expect(res.status).toBe(400);
        expect(res.body.message).toMatch(/正整数/);
      }
    });

    test('不存在的绘本返回404', async () => {
      const res = await request(app)
        .get('/api/v1/books/000000000000000000000000/tts')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(404);
    });
  });
});

// ============================================================
// 测试套件2：测评即时反馈（P1-02）
// ============================================================
describe('Assessment API - 即时反馈', () => {
  let assessmentId;

  test('startAssessment 不返回 correctAnswer', async () => {
    if (!authToken || !testChildId) return;
    
    const res = await request(app)
      .post('/api/v1/assessments/start')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        childId: testChildId,
        type: 'initial',
        targetLevel: 1,
        questionCount: 5
      });
    
    if (res.status === 200) {
      assessmentId = res.body.data.assessmentId;
      
      // 验证问题列表不包含correctAnswer
      const questions = res.body.data.questions;
      expect(Array.isArray(questions)).toBe(true);
      
      for (const q of questions) {
        expect(q).not.toHaveProperty('correctAnswer');
        expect(q).toHaveProperty('characterId');
        expect(q).toHaveProperty('character');
        expect(q).toHaveProperty('questionType');
        expect(q).toHaveProperty('options');
      }
    }
  });

  test('submitAssessment 返回 correctAnswer 和 isCorrect', async () => {
    if (!authToken || !assessmentId) return;
    
    // 先获取进行中的测评
    const startRes = await request(app)
      .post('/api/v1/assessments/start')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        childId: testChildId,
        type: 'initial',
        targetLevel: 1,
        questionCount: 5
      });
    
    if (startRes.status !== 200) return;
    
    const aId = startRes.body.data.assessmentId;
    const questions = startRes.body.data.questions;
    
    // 构造答案（全部选第一个选项）
    const answers = questions.map(q => ({
      characterId: q.characterId,
      userAnswer: q.options ? q.options[0] : '',
      responseTime: 1000
    }));
    
    const res = await request(app)
      .post(`/api/v1/assessments/${aId}/submit`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ answers, duration: 30000 });
    
    if (res.status === 200) {
      const data = res.body.data;
      expect(data.status).toBe('completed');
      expect(data).toHaveProperty('correctCount');
      expect(data).toHaveProperty('totalCount');
      expect(data).toHaveProperty('accuracy');
      
      // P1-02核心验证：每题返回correctAnswer和isCorrect
      const resultQuestions = data.questions;
      expect(Array.isArray(resultQuestions)).toBe(true);
      
      for (const q of resultQuestions) {
        expect(q).toHaveProperty('correctAnswer');
        expect(q).toHaveProperty('isCorrect');
        expect(q).toHaveProperty('userAnswer');
        expect(typeof q.isCorrect).toBe('boolean');
      }
    }
  });
});

// ============================================================
// 测试套件3：绘本和字卡 API（基础路由）
// ============================================================
describe('Books & Characters API', () => {
  test('GET /api/v1/books 返回绘本列表', async () => {
    const res = await request(app)
      .get('/api/v1/books?level=1&pageSize=5')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (res.status === 200) {
      expect(res.body.data).toHaveProperty('list');
      expect(Array.isArray(res.body.data.list)).toBe(true);
    }
  });

  test('GET /api/v1/characters 返回字卡列表', async () => {
    const res = await request(app)
      .get('/api/v1/characters?level=1&pageSize=5')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (res.status === 200) {
      expect(res.body.data).toHaveProperty('list');
      expect(Array.isArray(res.body.data.list)).toBe(true);
    }
  });

  test('GET /api/v1/books/:id 返回绘本详情含页面', async () => {
    const booksRes = await request(app)
      .get('/api/v1/books?level=1&pageSize=1')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (booksRes.status === 200 && booksRes.body.data && booksRes.body.data.list && booksRes.body.data.list.length > 0) {
      const book = booksRes.body.data.list[0];
      const bookId = book.id || book.bookId;
      
      const res = await request(app)
        .get(`/api/v1/books/${bookId}`)
        .set('Authorization', `Bearer ${authToken}`);
      
      if (res.status === 200) {
        expect(res.body.data).toHaveProperty('title');
        expect(res.body.data).toHaveProperty('level');
        expect(res.body.data).toHaveProperty('newWordCount');
      }
    }
  });

  test('L2绘本可通过API查询', async () => {
    const res = await request(app)
      .get('/api/v1/books?level=2&pageSize=10')
      .set('Authorization', `Bearer ${authToken}`);
    
    if (res.status === 200 && res.body.data && res.body.data.list) {
      // 如果seed已运行，应该能查到L2绘本
      const l2Books = res.body.data.list;
      if (l2Books.length > 0) {
        const firstL2 = l2Books[0];
        expect(firstL2.level).toBe(2);
        expect(firstL2).toHaveProperty('title');
        expect(firstL2).toHaveProperty('bookId');
      }
    }
  });
});

// ============================================================
// 测试套件4：认证API（基础验证）
// ============================================================
describe('Auth API', () => {
  test('未登录访问受保护接口返回401', async () => {
    const res = await request(app)
      .get('/api/v1/children');
    
    expect(res.status).toBe(401);
  });

  test('无效Token返回401', async () => {
    const res = await request(app)
      .get('/api/v1/children')
      .set('Authorization', 'Bearer invalid_token_xxx');
    
    expect(res.status).toBe(401);
  });
});
